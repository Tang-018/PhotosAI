import AppKit
import Photos
import Vision
/// Local, read-only Vision feature-print comparison service.
final class FeaturePrintService { private let manager = PHCachingImageManager()
    func featurePrint(for asset: PHAsset) async throws -> VNFeaturePrintObservation { let image: NSImage = try await withCheckedThrowingContinuation { c in let o = PHImageRequestOptions(); o.deliveryMode = .highQualityFormat; o.resizeMode = .fast; o.isNetworkAccessAllowed = true; manager.requestImage(for: asset, targetSize: CGSize(width: 800, height: 800), contentMode: .aspectFit, options: o) { image, _ in image.map { c.resume(returning: $0) } ?? c.resume(throwing: NSError(domain: "PhotosAI", code: 1)) } }; guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { throw NSError(domain: "PhotosAI", code: 2) }; return try await withCheckedThrowingContinuation { c in DispatchQueue.global(qos: .userInitiated).async { let r = VNGenerateImageFeaturePrintRequest { request, error in if let error { c.resume(throwing: error) } else if let result = request.results?.first as? VNFeaturePrintObservation { c.resume(returning: result) } else { c.resume(throwing: NSError(domain: "PhotosAI", code: 3)) } }; try? VNImageRequestHandler(cgImage: cg, options: [:]).perform([r]) } } }
    func distance(_ a: VNFeaturePrintObservation, _ b: VNFeaturePrintObservation) throws -> Float { var value: Float = 0; try a.computeDistance(&value, to: b); return value }
}
