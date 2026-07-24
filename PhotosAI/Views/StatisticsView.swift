import SwiftUI
struct StatisticsView: View { let analysis: PhotoLibraryAnalysis
    var body: some View { VStack(alignment: .leading, spacing: 5) { stat("全部", analysis.totalCount); stat("照片", analysis.photoCount); stat("视频", analysis.videoCount); stat("截图", analysis.screenshotCount); stat("Live Photos", analysis.livePhotoCount); stat("收藏", analysis.favoriteCount) }.font(.caption)
    }
    private func stat(_ name: String, _ count: Int) -> some View { HStack { Text(name); Spacer(); Text(count, format: .number).foregroundStyle(.secondary) } }
}
