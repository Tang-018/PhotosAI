import SwiftUI
struct PhotoGridView: View {
    @ObservedObject var viewModel: PhotoLibraryViewModel
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: viewModel.thumbnailSize), spacing: 12)],
                spacing: 12
            ) {
                ForEach(viewModel.filteredAssets) { photo in
                    PhotoThumbnailView(
                        photo: photo,
                        asset: viewModel.asset(for: photo),
                        size: viewModel.thumbnailSize,
                        service: viewModel.thumbnails,
                        category: viewModel.analysisRecords[photo.id]?.primaryCategory,
                        isDuplicate: viewModel.duplicateGroups.flatMap { $0 }.contains { $0.assetA == photo.id || $0.assetB == photo.id },
                        isSimilar: viewModel.similarGroups.flatMap { $0 }.contains { $0.assetA == photo.id || $0.assetB == photo.id }
                    )
                    .onTapGesture { viewModel.selectedAsset = photo }
                }
            }
            .padding(16)
        }
    }
}
