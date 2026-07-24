import AppKit
import Foundation
enum ReportExporter {
    static func export(_ analysis: PhotoLibraryAnalysis) throws -> URL? {
        let panel = NSOpenPanel(); panel.title = "选择报告导出文件夹"; panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let folder = panel.url else { return nil }
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601; encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(analysis).write(to: folder.appendingPathComponent("photo_analysis.json"), options: .atomic)
        let text = "# PhotosAI 分析报告\n\n> 仅从 PhotoKit 只读扫描生成；未修改 Photos。\n\n- 媒体总数：\(analysis.totalCount)\n- 照片：\(analysis.photoCount)\n- 视频：\(analysis.videoCount)\n- 截图：\(analysis.screenshotCount)\n- Live Photos：\(analysis.livePhotoCount)\n- 收藏：\(analysis.favoriteCount)\n"
        try text.write(to: folder.appendingPathComponent("photo_analysis.md"), atomically: true, encoding: .utf8); return folder
    }
}
