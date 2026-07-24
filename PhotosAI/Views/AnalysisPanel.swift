import AppKit
import SwiftUI

struct AnalysisPanel: View {
    let record: ContentAnalysisRecord?
    let analyze: () -> Void
    let addTag: (String) -> Void
    let removeTag: (String) -> Void
    @State private var newTag = ""
    var body: some View { VStack(alignment: .leading, spacing: 10) {
        Divider(); Text("智能分析（本机）").font(.headline)
        if let record {
            Text("状态：\(record.status.rawValue)"); Text("分析时间：\(record.analysisDate.formatted())"); Text("主类别：\(record.primaryCategory.title)").font(.subheadline.bold())
            if let summary = record.summary { Text(summary).textSelection(.enabled); Button("复制摘要") { copy(summary) } }
            tags("自动标签", record.tags.filter { $0.source != .user }, removable: false); tags("用户标签", record.tags.filter { $0.source == .user }, removable: true)
            HStack { TextField("新增用户标签", text: $newTag); Button("添加") { let tag = newTag.trimmingCharacters(in: .whitespaces); if !tag.isEmpty { addTag(tag); newTag = "" } } }
            if !record.visionLabels.isEmpty { Text("Vision 分类：\(record.visionLabels.map(\.name).joined(separator: "、"))").font(.caption).foregroundStyle(.secondary) }
            if !record.ocrKeywords.isEmpty { Text("OCR 命中：\(record.ocrKeywords.joined(separator: "、"))").font(.caption).foregroundStyle(.secondary) }
            HStack { Button("复制全部标签") { copy(record.tags.map(\.name).joined(separator: "、")) }; Button("重新分析") { analyze() } }
            if record.status == .failed { Text(record.errorMessage ?? "分析失败").foregroundStyle(.red) }
        } else { Text("尚未分析。").foregroundStyle(.secondary); Button("开始分析") { analyze() } }
    } }
    @ViewBuilder private func tags(_ title: String, _ tags: [ContentTag], removable: Bool) -> some View { if !tags.isEmpty { VStack(alignment: .leading) { Text(title).font(.caption).foregroundStyle(.secondary); FlowLayout(tags: tags, remove: removable ? removeTag : nil) } } }
    private func copy(_ text: String) { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text, forType: .string) }
}

private struct FlowLayout: View { let tags: [ContentTag]; let remove: ((String) -> Void)?; var body: some View { HStack { ForEach(tags) { tag in HStack(spacing: 3) { Text(tag.name); if let remove { Button("×") { remove(tag.name) }.buttonStyle(.plain) } }.font(.caption).padding(4).background(.quaternary, in: Capsule()) } } } }
