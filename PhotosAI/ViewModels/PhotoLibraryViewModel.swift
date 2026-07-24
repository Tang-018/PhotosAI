import Combine
import Foundation
import Photos
import AppKit

@MainActor final class PhotoLibraryViewModel: ObservableObject {
    @Published private(set) var authorizationStatus: PHAuthorizationStatus; @Published private(set) var analysis: PhotoLibraryAnalysis?
    @Published private(set) var isScanning = false; @Published private(set) var progress = 0.0; @Published private(set) var statusText = "请先授权并扫描照片库"
    @Published var selectedFilter: LibraryFilter = .all; @Published var searchText = ""; @Published var thumbnailSize = 140.0; @Published var selectedAsset: PhotoAsset?; @Published var errorMessage: String?; @Published var exportMessage: String?
    private let service = PhotoLibraryService(); let thumbnails = ThumbnailService()
    @Published var isOCRRunning = false; @Published var isOCRPaused = false; @Published var ocrProgress = OCRProgress(); @Published var ocrRecords: [String: OCRRecord] = [:]
    private let ocr = OCRService(); private let ocrStore = OCRIndexStore(); private var ocrTask: Task<Void, Never>?
    private let contentStore = ContentAnalysisStore(); private let contentService = ContentAnalysisService()
    private let duplicateStore = DuplicateStore(); private let duplicateService = DuplicateAnalysisService(); private var duplicateTask: Task<Void, Never>?
    @Published var duplicateGroups: [[DuplicateMatch]] = []; @Published var similarGroups: [[DuplicateMatch]] = []; @Published var duplicateProgress = DuplicateProgress(); @Published var isDuplicateScanRunning = false
    @Published var analysisRecords: [String: ContentAnalysisRecord] = [:]; @Published var selectedCategory: ContentCategory?; @Published var isAnalysisRunning = false; @Published var analysisCompleted = 0; @Published var analysisTotal = 0
    init() { authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite); ocrRecords = ocrStore.all; analysisRecords = contentStore.all; reloadDuplicateIndex() }
    var filteredAssets: [PhotoAsset] {
        let all = analysis?.items ?? []; let duplicateIDs = Set(duplicateGroups.flatMap { $0.flatMap { [$0.assetA, $0.assetB] } }); let similarIDs = Set(similarGroups.flatMap { $0.flatMap { [$0.assetA, $0.assetB] } }); let base0: [PhotoAsset] = switch selectedFilter { case .all: all; case .screenshots: all.filter(\.isScreenshot); case .videos: all.filter { $0.mediaType == .video }; case .livePhotos: all.filter(\.isLivePhoto); case .favorites: all.filter(\.isFavorite); case .recent: Array(all.prefix(100)); case .duplicates: all.filter { duplicateIDs.contains($0.id) }; case .similar: all.filter { similarIDs.contains($0.id) } }; let base = selectedCategory.map { c in base0.filter { analysisRecords[$0.id]?.primaryCategory == c } } ?? base0
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(); guard !query.isEmpty else { return base }
        return base.filter { asset in
            let date = asset.creationDate.map { ISO8601DateFormatter().string(from: $0) } ?? ""
            return date.contains(query) || (query == "截图" && asset.isScreenshot) || (query == "视频" && asset.mediaType == .video) || ((query == "live photo" || query == "livephoto") && asset.isLivePhoto) || (query == "收藏" && asset.isFavorite) || ocrStore.search(query).contains(asset.id)
        }
    }
    func requestAuthorization() { statusText = "正在请求照片权限…"; service.requestAuthorization { [weak self] s in self?.authorizationStatus = s; self?.statusText = s == .authorized || s == .limited ? "权限已授予" : "未获得权限" } }
    func scan() { guard authorizationStatus == .authorized || authorizationStatus == .limited else { errorMessage = "请先授权访问照片。"; return }; isScanning = true; progress = 0; service.scan(progress: { [weak self] c, t in self?.progress = t == 0 ? 1 : Double(c) / Double(t); self?.statusText = "正在扫描：\(c) / \(t)" }, completion: { [weak self] r in guard let self else { return }; self.isScanning = false; switch r { case .success(let a): self.analysis = a; self.statusText = a.totalCount == 0 ? "照片库为空" : "扫描完成：\(a.totalCount) 项"; case .failure(let e): self.errorMessage = e.localizedDescription; self.statusText = "扫描失败" } }) }
    func asset(for photo: PhotoAsset) -> PHAsset? { service.asset(for: photo.id) }
    func exportReport() { guard let analysis else { return }; do { if let url = try ReportExporter.export(analysis) { exportMessage = "报告已导出到：\(url.path)" } } catch { errorMessage = "导出失败：\(error.localizedDescription)" } }
    func recognizeScreenshots() { guard !isOCRRunning, let analysis else { return }; let list = analysis.items.filter { $0.isScreenshot && $0.mediaType == .photo }; ocrProgress = OCRProgress(total: list.count); isOCRRunning = true; ocrTask = Task { for photo in list { if Task.isCancelled { break }; await recognize(photo); ocrProgress.completed += 1 }; try? ocrStore.save(); isOCRRunning = false } }
    func stopOCR() { ocrTask?.cancel(); isOCRRunning = false }
    func pauseOCR() { isOCRPaused = true; ocrTask?.cancel(); isOCRRunning = false }
    func exportOCR() { let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; guard panel.runModal() == .OK, let folder = panel.url else { return }; do { try ocrStore.export(to: folder); exportMessage = "OCR JSON、Markdown 和文本已导出" } catch { errorMessage = "OCR 导出失败：\(error.localizedDescription)" } }
    func recognize(_ photo: PhotoAsset) async { guard let asset = asset(for: photo) else { return }; do { let result = try await ocr.recognizeText(for: asset); let status: OCRStatus = result.text.isEmpty ? .noText : .completed; let record = OCRRecord(id: photo.id, assetLocalIdentifier: photo.id, recognizedText: result.text, normalizedText: OCRRecord.normalize(result.text), recognitionDate: Date(), creationDate: photo.creationDate, confidence: result.confidence, languageHints: ["zh-Hans", "en-US"], status: status, sourceFingerprint: "\(photo.pixelWidth)x\(photo.pixelHeight)", errorMessage: nil); ocrStore.upsert(record); try? ocrStore.save(); ocrRecords[photo.id] = record; if status == .completed { ocrProgress.recognized += 1 } else { ocrProgress.noText += 1 } } catch { ocrProgress.failed += 1 } }
    func clearOCR() { do { try ocrStore.clearAll(); ocrRecords = [:] } catch { errorMessage = "清除 OCR 索引失败" } }
    func analyze(_ photo: PhotoAsset) { guard let asset = asset(for: photo) else { return }; Task { do { let record = try await contentService.analyze(asset: asset, photoAsset: photo); analysisRecords[photo.id] = record; contentStore.upsert(record); try? contentStore.save() } catch { errorMessage = "分析失败：\(error.localizedDescription)" } } }
    func analyzeAll() { guard let items = analysis?.items, !isAnalysisRunning else { return }; isAnalysisRunning = true; analysisCompleted = 0; analysisTotal = items.filter { $0.mediaType == .photo }.count; Task { for photo in items where photo.mediaType == .photo { if Task.isCancelled { break }; analyze(photo); analysisCompleted += 1 }; isAnalysisRunning = false } }
    func stopAnalysis() { isAnalysisRunning = false }
    func reloadDuplicateIndex() { duplicateGroups = duplicateStore.groupDuplicates(); similarGroups = duplicateStore.groupSimilar() }
    func clearDuplicateIndex() { try? duplicateStore.replace([]); reloadDuplicateIndex() }
    func startDuplicateScan() { guard !isDuplicateScanRunning, let photos = analysis?.items else { return }; let pairs = photos.compactMap { p in asset(for: p).map { ($0, p) } }; isDuplicateScanRunning = true; duplicateTask = Task { _ = await duplicateService.analyze(pairs) { [weak self] state in Task { @MainActor in self?.duplicateProgress = state } }; reloadDuplicateIndex(); isDuplicateScanRunning = false } }
    func cancelDuplicateScan() { duplicateTask?.cancel(); isDuplicateScanRunning = false }
    func addUserTag(_ name: String, to photo: PhotoAsset) { guard var record = analysisRecords[photo.id] else { return }; record.tags.append(ContentTag(id: "user-\(UUID().uuidString)", name: name, confidence: 1, source: .user)); analysisRecords[photo.id] = record; contentStore.upsert(record); try? contentStore.save() }
    func removeUserTag(_ name: String, from photo: PhotoAsset) { guard var record = analysisRecords[photo.id] else { return }; record.tags.removeAll { $0.source == .user && $0.name == name }; analysisRecords[photo.id] = record; contentStore.upsert(record); try? contentStore.save() }
}
