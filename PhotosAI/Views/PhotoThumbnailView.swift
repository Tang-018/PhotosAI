import SwiftUI
import Photos
struct PhotoThumbnailView: View {
    let photo: PhotoAsset; let asset: PHAsset?; let size: CGFloat; let service: ThumbnailService; let category: ContentCategory?; let isDuplicate: Bool; let isSimilar: Bool
    @State private var image: NSImage?
    var body: some View { ZStack(alignment: .bottomTrailing) {
        Group { if let image { Image(nsImage: image).resizable().scaledToFill() } else { Rectangle().fill(.quaternary).overlay(Image(systemName: "photo").foregroundStyle(.secondary)) } }
            .frame(width: size, height: size).clipped().clipShape(RoundedRectangle(cornerRadius: 8))
        HStack(spacing: 4) { if photo.isScreenshot { Text("截图").font(.caption2.bold()) }; if photo.isLivePhoto { Image(systemName: "livephoto") }; if photo.isFavorite { Image(systemName: "heart.fill") }; if photo.mediaType == .video { Image(systemName: "video.fill"); Text(time(photo.duration)).font(.caption2.monospacedDigit()) } }
            .padding(5).foregroundStyle(.white).background(.black.opacity(0.65), in: Capsule()).padding(5)
        if let category { Text(category.title).font(.caption2.bold()).padding(5).foregroundStyle(.white).background(.black.opacity(0.65), in: Capsule()).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(5) }
        HStack(spacing: 4) { if isDuplicate { Image(systemName: "rectangle.on.rectangle.fill").foregroundStyle(.red) }; if isSimilar { Image(systemName: "photo.stack.fill").foregroundStyle(.yellow) } }.padding(5).background(.black.opacity(0.55), in: Capsule()).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(5)
    }.task(id: "\(photo.id)-\(size)") { guard let asset else { return }; image = await service.requestThumbnail(for: asset, targetSize: CGSize(width: size * 2, height: size * 2)) }.onDisappear { service.cancel(assetID: photo.id) } }
    private func time(_ duration: TimeInterval) -> String { String(format: "%d:%02d", Int(duration) / 60, Int(duration) % 60) }
}
