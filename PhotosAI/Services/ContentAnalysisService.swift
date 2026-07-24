import AppKit
import Photos
import Vision

struct AnalysisProgress { var completed = 0; var total = 0; var succeeded = 0; var failed = 0 }

/// Fully local, read-only analysis: PhotoKit read + Vision classification only.
final class ContentAnalysisService {
    private let manager = PHCachingImageManager()
    private let store: ContentAnalysisStore
    private let ocrStore: OCRIndexStore
    init(store: ContentAnalysisStore = ContentAnalysisStore(), ocrStore: OCRIndexStore = OCRIndexStore()) { self.store = store; self.ocrStore = ocrStore }

    func analyze(asset: PHAsset, photoAsset: PhotoAsset) async throws -> ContentAnalysisRecord {
        try Task.checkCancellation()
        let image: NSImage = try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions(); options.deliveryMode = .highQualityFormat; options.resizeMode = .exact; options.isNetworkAccessAllowed = true
            manager.requestImage(for: asset, targetSize: CGSize(width: 1400, height: 1400), contentMode: .aspectFit, options: options) { image, _ in
                image.map { continuation.resume(returning: $0) } ?? continuation.resume(throwing: NSError(domain: "PhotosAI", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法读取分析图片"]))
            }
        }
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { throw NSError(domain: "PhotosAI", code: 2) }
        let labels: [ContentTag] = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNClassifyImageRequest { request, error in
                    if let error { continuation.resume(throwing: error); return }
                    let tags = (request.results as? [VNClassificationObservation] ?? []).filter { $0.confidence >= 0.25 }.prefix(12).map { ContentTag(id: "vision-\($0.identifier)", name: Self.localized($0.identifier), confidence: Double($0.confidence), source: .vision) }
                    continuation.resume(returning: tags)
                }; try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
            }
        }
        let ocr = ocrStore.record(for: photoAsset.id); let text = ocr?.normalizedText ?? ""
        var tags = labels; if photoAsset.isScreenshot { tags.append(ContentTag(id: "meta-screenshot", name: "截图", confidence: 0.9, source: .metadata)) }
        let category: ContentCategory
        if let rule = ContentClassificationRules.classify(ocrText: text) { category = rule.category; tags.append(contentsOf: rule.tags) }
        else if photoAsset.isScreenshot { category = .screenshot }
        else if labels.contains(where: { $0.name.contains("食物") }) { category = .food }
        else if labels.contains(where: { $0.name.contains("风景") }) { category = .scenery }
        else { category = .unknown }
        let record = ContentAnalysisRecord(id: photoAsset.id, assetLocalIdentifier: photoAsset.id, primaryCategory: category, tags: Array(Dictionary(grouping: tags, by: \.name).compactMap { $0.value.max(by: { $0.confidence < $1.confidence }) }.prefix(20)), summary: "本机分析：\(category.title)" + (text.isEmpty ? "。" : "，结合了图片文字。"), visionLabels: labels, ocrKeywords: Array(text.split(separator: " ").prefix(20)).map(String.init), analysisDate: Date(), status: .completed, errorMessage: nil, sourceFingerprint: "\(photoAsset.pixelWidth)x\(photoAsset.pixelHeight)-\(photoAsset.creationDate?.timeIntervalSince1970 ?? 0)", modelVersion: "vision-v1")
        store.upsert(record); try store.save(); return record
    }

    func analyzeBatch(_ pairs: [(PHAsset, PhotoAsset)], concurrencyLimit: Int = 2, progress: @escaping @Sendable (AnalysisProgress) -> Void) async -> [ContentAnalysisRecord] {
        var result: [ContentAnalysisRecord] = []; var state = AnalysisProgress(total: pairs.count)
        for pair in pairs { if Task.isCancelled { break }; do { result.append(try await analyze(asset: pair.0, photoAsset: pair.1)); state.succeeded += 1 } catch { state.failed += 1 }; state.completed += 1; progress(state) }
        return result
    }
    private static func localized(_ value: String) -> String { let map = ["food":"食物", "landscape":"风景", "person":"人物", "animal":"动物", "vehicle":"车辆", "document":"文档"]; return map[value.lowercased()] ?? value }
}
