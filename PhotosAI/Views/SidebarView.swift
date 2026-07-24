import SwiftUI
struct SidebarView: View {
    @ObservedObject var viewModel: PhotoLibraryViewModel
    var body: some View { List(selection: $viewModel.selectedFilter) {
        Section("照片库") { ForEach(LibraryFilter.allCases) { filter in Label(filter.title, systemImage: filter.icon).tag(filter) } }
        Section("智能文字") {
            Text("已识别：\(viewModel.ocrRecords.values.filter { $0.status == .completed }.count)")
            Text("无文字：\(viewModel.ocrRecords.values.filter { $0.status == .noText }.count)")
            Text("失败：\(viewModel.ocrRecords.values.filter { $0.status == .failed }.count)")
            Button("清除 OCR 索引") { viewModel.clearOCR() }
        }
        Section("智能分类") {
            ForEach([ContentCategory.aiLearning, .work, .document, .product, .socialMedia, .invoice, .identityDocument, .code, .travel, .food, .scenery, .person, .animal, .vehicle, .webpage, .unknown]) { category in
                Button { viewModel.selectedCategory = viewModel.selectedCategory == category ? nil : category } label: { HStack { Text(category.title); Spacer(); Text("\(viewModel.analysisRecords.values.filter { $0.primaryCategory == category }.count)").foregroundStyle(.secondary) } }
            }
        }
        if let analysis = viewModel.analysis { Section("概览") { StatisticsView(analysis: analysis).padding(.vertical, 4) } }
        Section { Text("权限：\(viewModel.authorizationStatus.chineseDescription)").font(.caption).foregroundStyle(.secondary) }
    }.navigationTitle("PhotosAI") }
}
