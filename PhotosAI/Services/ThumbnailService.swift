import AppKit
import Photos

@MainActor
final class ThumbnailService {
    private let manager = PHCachingImageManager()
    private let cache = NSCache<NSString, NSImage>()
    private var requestIDs: [String: PHImageRequestID] = [:]
    func requestThumbnail(for asset: PHAsset, targetSize: CGSize) async -> NSImage? {
        let key = "\(asset.localIdentifier)-\(Int(targetSize.width))x\(Int(targetSize.height))"
        if let image = cache.object(forKey: key as NSString) { return image }
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions(); options.deliveryMode = .highQualityFormat; options.resizeMode = .fast; options.isNetworkAccessAllowed = true
            let requestID = manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { [weak self] image, info in
                guard info?[PHImageCancelledKey] as? Bool != true else { continuation.resume(returning: nil); return }
                if let image { self?.cache.setObject(image, forKey: key as NSString); continuation.resume(returning: image) }
                else { continuation.resume(returning: nil) }
            }
            self.requestIDs[key] = requestID
        }
    }
    func cancel(assetID: String) { for (key, id) in requestIDs where key.hasPrefix(assetID) { manager.cancelImageRequest(id); requestIDs[key] = nil } }
}
