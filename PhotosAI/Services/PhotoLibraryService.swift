import Foundation
import Photos

/// Read-only PhotoKit service. No performChanges / change-request APIs are used.
final class PhotoLibraryService {
    private var assetsByID: [String: PHAsset] = [:]
    func currentAuthorizationStatus() -> PHAuthorizationStatus { PHPhotoLibrary.authorizationStatus(for: .readWrite) }
    func requestAuthorization(completion: @escaping (PHAuthorizationStatus) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async { completion(status) }
        }
    }
    func asset(for id: String) -> PHAsset? { assetsByID[id] }
    func scan(progress: @escaping (Int, Int) -> Void, completion: @escaping (Result<PhotoLibraryAnalysis, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let options = PHFetchOptions(); options.includeHiddenAssets = false; options.includeAllBurstAssets = false
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let result = PHAsset.fetchAssets(with: options); let total = result.count
            var rows: [PhotoAsset] = []; var lookup: [String: PHAsset] = [:]; rows.reserveCapacity(total)
            result.enumerateObjects { asset, index, _ in
                let type: AssetMediaType = asset.mediaType == .image ? .photo : asset.mediaType == .video ? .video : asset.mediaType == .audio ? .audio : .other
                let row = PhotoAsset(id: asset.localIdentifier, localIdentifier: asset.localIdentifier, creationDate: asset.creationDate, mediaType: type, mediaSubtypes: asset.mediaSubtypes.rawValue, pixelWidth: asset.pixelWidth, pixelHeight: asset.pixelHeight, duration: asset.duration, isFavorite: asset.isFavorite, isScreenshot: asset.mediaSubtypes.contains(.photoScreenshot), isLivePhoto: asset.mediaSubtypes.contains(.photoLive))
                rows.append(row); lookup[row.id] = asset
                if index % 40 == 0 || index + 1 == total { DispatchQueue.main.async { progress(index + 1, total) } }
            }
            let report = PhotoLibraryAnalysis(generatedAt: Date(), totalCount: total, photoCount: rows.filter { $0.mediaType == .photo }.count, videoCount: rows.filter { $0.mediaType == .video }.count, screenshotCount: rows.filter(\.isScreenshot).count, livePhotoCount: rows.filter(\.isLivePhoto).count, favoriteCount: rows.filter(\.isFavorite).count, items: rows)
            DispatchQueue.main.async { self.assetsByID = lookup; completion(.success(report)) }
        }
    }
}
