import SwiftUI
import Photos
struct PhotoDetailView: View {
    let photo: PhotoAsset; let asset: PHAsset?; let thumbnailService: ThumbnailService; let record: OCRRecord?; let analysisRecord: ContentAnalysisRecord?; let recognize: () -> Void; let analyze: () -> Void; let addTag: (String) -> Void; let removeTag: (String) -> Void; @Environment(\.dismiss) private var dismiss; @State private var image: NSImage?
    var body: some View { VStack(alignment: .leading, spacing: 16) {
        HStack { Text("照片详情（只读）").font(.title2.bold()); Spacer(); Button("关闭") { dismiss() } }
        Group { if let image { Image(nsImage: image).resizable().scaledToFit() } else { ProgressView().frame(maxWidth: .infinity, minHeight: 300) } }.frame(maxWidth: .infinity, maxHeight: 420)
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 10) { row("拍摄时间", photo.creationDate?.formatted(date: .long, time: .shortened) ?? "未知"); row("类型", photo.mediaType.rawValue); row("分辨率", "\(photo.pixelWidth) × \(photo.pixelHeight)"); row("截图", photo.isScreenshot ? "是" : "否"); row("localIdentifier", photo.localIdentifier) }
        Divider(); Text("OCR（本机识别）").font(.headline); Text("状态：\(record?.status.rawValue ?? "未识别")"); if let record { Text("识别时间：\(record.recognitionDate.formatted()) · \(record.recognizedText.count) 字"); ScrollView { Text(record.recognizedText.isEmpty ? "未识别到可用文字" : record.recognizedText).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }.frame(height: 120); Button("复制全部文字") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(record.recognizedText, forType: .string) } }; Button(record == nil ? "识别此照片" : "重新识别") { recognize() }
        AnalysisPanel(record: analysisRecord, analyze: analyze, addTag: addTag, removeTag: removeTag)
    }.padding(24).frame(width: 620).task { if let asset { image = await thumbnailService.requestThumbnail(for: asset, targetSize: CGSize(width: 1200, height: 900)) } } }
    private func row(_ key: String, _ value: String) -> some View { GridRow { Text(key).foregroundStyle(.secondary); Text(value).textSelection(.enabled) } }
}
