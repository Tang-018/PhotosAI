# PhotosAI（V2，只读）

一个原生 macOS SwiftUI App，通过 PhotoKit 只读扫描当前 Photos Library，并导出本地 JSON 与 Markdown 报告。

## V2 新增：缩略图浏览与筛选

- `NavigationSplitView` 侧边栏：全部照片、截图、视频、Live Photos、收藏、最近项目。
- 自适应 `LazyVGrid`：按需加载约 140 × 140 的裁剪缩略图；滑块可调节大小。
- `PHCachingImageManager` + 内存缓存：只请求显示尺寸的缩略图，离开可见区域会取消请求，不加载原始大图。
- 搜索支持年份/月（如 `2025`、`2025-07`）及“截图、视频、Live Photo、收藏”。
- 点击缩略图打开只读详情页，显示预览、时间、分辨率、时长和 PhotoKit localIdentifier。

## 安全边界

- 不使用 AppleScript，不读取 `Photos Library.photoslibrary` 的内部数据库或文件。
- `PhotoLibraryService` 只调用 `PHAsset.fetchAssets` 和只读属性。
- 项目中没有 `PHPhotoLibrary.performChanges`、`PHAssetChangeRequest` 或 `PHAssetCollectionChangeRequest`，因此不能删除、编辑、移动照片或创建相簿。
- 导出时由你在系统文件选择器中指定目录，输出 `photo_analysis.json` 与 `photo_analysis.md`。

## 用 Xcode 打开

1. 在 Finder 双击 `PhotosAI.xcodeproj`，或在终端运行：

   ```bash
   open /Users/tangziqing/Documents/Codex/2026-07-23/ban/outputs/PhotosAIApp/PhotosAI.xcodeproj
   ```

2. 选择 **PhotosAI** target，打开 **Signing & Capabilities**。
3. 在 **Signing** 中选择你的 Apple Development Team，并确保 Bundle Identifier 唯一（例如 `com.你的名字.PhotosAI`）。原因：签名后的 App 才能获得 macOS 隐私权限。
4. 保持 **App Sandbox** 开启，并确认以下能力：
   - **Photos Library**：用于 PhotoKit 读取图库；
   - **User Selected File / Read/Write**：用于把报告写到你在导出面板选择的文件夹。
5. 选择 `My Mac`，按 **⌘R** 运行。

## 首次授权与使用

1. 在 App 中点击“授权访问照片”，系统请求照片访问时选择“允许完全访问”。PhotoKit 将整库读取权限称为 `.readWrite`；PhotosAI 的代码仍严格只读。
2. 点击“扫描照片库”。界面显示扫描进度、统计数据和最近 100 项元数据。
3. 点击“导出分析报告”，在弹出的目录选择器中选一个文件夹。
4. 检查该文件夹中的 `photo_analysis.json` 与 `photo_analysis.md`。

如果以前拒绝过：在“系统设置”→“隐私与安全性”→“照片”中，允许 PhotosAI 访问，再回到 App 点击扫描。

## 如何验证只读

1. 在 Xcode 全局搜索 `PHAssetChangeRequest`、`PHAssetCollectionChangeRequest` 和 `performChanges(`：V1 不含这些 Photos 写入 API 调用。
2. 扫描前后在 Photos 中比较照片数量和相簿列表：应用仅读取元数据，不会生成任何新相簿。
3. 检查导出目录：应用只会新建两个报告文件，不会向 Photos Library 写入文件。

## 项目结构

```text
PhotosAIApp/
├── PhotosAI.xcodeproj
├── PhotosAI/
│   ├── Models/             # Codable 元数据模型
│   ├── Services/           # PhotoKit 只读扫描与报告导出
│   ├── ViewModels/         # MVVM 状态与用户操作
│   ├── Views/              # SwiftUI 统计视图
│   ├── Resources/Info.plist
│   └── PhotosAI.entitlements
└── README.md
```
