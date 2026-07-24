import SwiftUI
struct ContentView: View {
    @StateObject private var viewModel = PhotoLibraryViewModel()
    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
        } detail: {
            VStack(spacing: 0) {
                toolbar
                Divider()
                if viewModel.analysis == nil { PermissionView(viewModel: viewModel) }
                else if viewModel.filteredAssets.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "photo").font(.system(size: 42)).foregroundStyle(.secondary)
                        Text("没有符合条件的项目").font(.title3.bold())
                        Text("请调整筛选条件或搜索词。").foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                else { PhotoGridView(viewModel: viewModel) }
            }.navigationTitle(viewModel.selectedFilter.title)
        }.frame(minWidth: 950, minHeight: 650)
        .sheet(item: $viewModel.selectedAsset) { photo in PhotoDetailView(photo: photo, asset: viewModel.asset(for: photo), thumbnailService: viewModel.thumbnails, record: viewModel.ocrRecords[photo.id], analysisRecord: viewModel.analysisRecords[photo.id], recognize: { Task { await viewModel.recognize(photo) } }, analyze: { viewModel.analyze(photo) }, addTag: { viewModel.addUserTag($0, to: photo) }, removeTag: { viewModel.removeUserTag($0, from: photo) }) }
        .alert("提示", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) { Button("确定", role: .cancel) {} } message: { Text(viewModel.errorMessage ?? "") }
    }
    private var toolbar: some View { HStack(spacing: 14) {
        Button("扫描照片库") { viewModel.scan() }.buttonStyle(.borderedProminent).disabled(viewModel.isScanning)
        Button(viewModel.isDuplicateScanRunning ? "停止重复扫描" : "扫描重复图片") { viewModel.isDuplicateScanRunning ? viewModel.cancelDuplicateScan() : viewModel.startDuplicateScan() }.disabled(viewModel.analysis == nil)
        if viewModel.isDuplicateScanRunning { ProgressView(value: Double(viewModel.duplicateProgress.completed), total: Double(max(1, viewModel.duplicateProgress.total))).frame(width: 80) }
        Button("识别截图文字") { viewModel.recognizeScreenshots() }.disabled(viewModel.analysis == nil || viewModel.isOCRRunning)
        Button("分析全部") { viewModel.analyzeAll() }.disabled(viewModel.analysis == nil || viewModel.isAnalysisRunning)
        if viewModel.isAnalysisRunning { Button("停止分析") { viewModel.stopAnalysis() }; ProgressView(value: Double(viewModel.analysisCompleted), total: Double(max(1, viewModel.analysisTotal))).frame(width: 80) }
        if viewModel.isOCRRunning { Button("停止识别") { viewModel.stopOCR() }; ProgressView(value: Double(viewModel.ocrProgress.completed), total: Double(max(1, viewModel.ocrProgress.total))).frame(width: 90) }
        Text("\(viewModel.selectedFilter.title)：\(viewModel.filteredAssets.count) 项").foregroundStyle(.secondary)
        Spacer(); Image(systemName: "photo"); Slider(value: $viewModel.thumbnailSize, in: 100...220, step: 10).frame(width: 130)
        TextField("搜索年份、月份或类型", text: $viewModel.searchText).textFieldStyle(.roundedBorder).frame(width: 200)
        Button("导出报告") { viewModel.exportReport() }.disabled(viewModel.analysis == nil)
        Button("导出 OCR") { viewModel.exportOCR() }.disabled(viewModel.ocrRecords.isEmpty)
    }.padding(14) }
}
