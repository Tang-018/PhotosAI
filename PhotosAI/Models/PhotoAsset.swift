import Foundation
import Photos

enum AssetMediaType: String, Codable, Hashable { case photo = "照片", video = "视频", audio = "音频", other = "其他" }

struct PhotoAsset: Identifiable, Hashable, Codable {
    let id: String
    let localIdentifier: String
    let creationDate: Date?
    let mediaType: AssetMediaType
    let mediaSubtypes: UInt
    let pixelWidth: Int
    let pixelHeight: Int
    let duration: TimeInterval
    let isFavorite: Bool
    let isScreenshot: Bool
    let isLivePhoto: Bool
}

struct PhotoLibraryAnalysis: Codable {
    let generatedAt: Date; let totalCount: Int; let photoCount: Int; let videoCount: Int
    let screenshotCount: Int; let livePhotoCount: Int; let favoriteCount: Int; let items: [PhotoAsset]
}

extension PHAuthorizationStatus {
    var chineseDescription: String { switch self {
    case .authorized: return "已授权完全访问"; case .limited: return "已授权有限访问"
    case .denied: return "已拒绝"; case .restricted: return "受系统限制"; case .notDetermined: return "尚未授权"
    @unknown default: return "未知" } }
}
