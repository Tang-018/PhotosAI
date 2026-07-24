import AppKit
import Photos
import Vision

enum OCRServiceError: Error { case imageUnavailable }
final class OCRService {
    private let manager = PHCachingImageManager()
    func recognizeText(for asset: PHAsset) async throws -> (text: String, confidence: Float?) {
        let image: NSImage = try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions(); options.deliveryMode = .highQualityFormat; options.resizeMode = .exact; options.isNetworkAccessAllowed = true
            manager.requestImage(for: asset, targetSize: CGSize(width: 1800, height: 1800), contentMode: .aspectFit, options: options) { image, info in
                if let image { continuation.resume(returning: image) } else { continuation.resume(throwing: OCRServiceError.imageUnavailable) }
            }
        }
        guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { throw OCRServiceError.imageUnavailable }
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest { request, error in
                    if let error { continuation.resume(throwing: error); return }
                    let observations = request.results as? [VNRecognizedTextObservation] ?? []
                    let candidates = observations.compactMap { $0.topCandidates(1).first }
                    continuation.resume(returning: (candidates.map(\.string).joined(separator: "\n"), candidates.map(\.confidence).max()))
                }
                request.recognitionLevel = .accurate; request.usesLanguageCorrection = true; request.recognitionLanguages = ["zh-Hans", "en-US"]; request.minimumTextHeight = 0.012
                try? VNImageRequestHandler(cgImage: cg, options: [:]).perform([request])
            }
        }
    }
}
