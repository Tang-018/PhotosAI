import Foundation

enum LibraryFilter: String, CaseIterable, Identifiable {
    case all, screenshots, videos, livePhotos, favorites, recent, duplicates, similar
    var id: String { rawValue }
    var title: String { switch self {
    case .all: return "全部照片"; case .screenshots: return "截图"; case .videos: return "视频"
    case .livePhotos: return "Live Photos"; case .favorites: return "收藏"; case .recent: return "最近项目"; case .duplicates: return "重复照片"; case .similar: return "相似照片" } }
    var icon: String { switch self {
    case .all: return "photo.on.rectangle"; case .screenshots: return "camera.viewfinder"
    case .videos: return "video"; case .livePhotos: return "livephoto"; case .favorites: return "heart"; case .recent: return "clock"; case .duplicates: return "rectangle.on.rectangle"; case .similar: return "photo.stack" } }
}
