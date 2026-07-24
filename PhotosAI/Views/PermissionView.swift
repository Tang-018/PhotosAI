import SwiftUI
struct PermissionView: View {
    @ObservedObject var viewModel: PhotoLibraryViewModel
    var body: some View { VStack(spacing: 16) {
        Image(systemName: "photo.badge.plus").font(.system(size: 52)).foregroundStyle(.secondary)
        Text(viewModel.authorizationStatus == .denied ? "照片访问已被拒绝" : "请授权访问照片库").font(.title2.bold())
        Text("PhotosAI 仅读取媒体元数据与缩略图，不会修改照片或创建相簿。").foregroundStyle(.secondary)
        Button("授权访问照片") { viewModel.requestAuthorization() }.buttonStyle(.borderedProminent)
        if viewModel.isScanning { ProgressView(viewModel.statusText, value: viewModel.progress).frame(width: 300) } else { Text(viewModel.statusText).foregroundStyle(.secondary) }
    }.frame(maxWidth: .infinity, maxHeight: .infinity) }
}
