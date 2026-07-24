# PhotosAI

> AI 驱动的 macOS 智能照片管理助手

![macOS](https://img.shields.io/badge/macOS-13%2B-000000?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-5-orange?logo=swift&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue)

PhotosAI 是一款坚持**本地优先、只读分析**的 macOS 照片管理助手：读取 Photos 图库的公开元数据与缩略图，在本机完成 OCR、内容理解和重复照片分析，绝不修改系统照片库。📷

## ✨ 功能

| 功能 | 说明 | 状态 |
|---|---|---|
| PhotoKit 扫描 | 读取照片、视频、截图、Live Photo、收藏及基础元数据 | ✅ 已完成 |
| 缩略图浏览 | 自适应网格、媒体筛选、详情查看与本地缓存 | ✅ 已完成 |
| OCR | 基于 Apple Vision 的本地中英文文字识别与索引 | ✅ 已完成 |
| 智能分类 | 融合 Vision、OCR 与元数据生成本地分类及标签 | ✅ 已完成 |
| 重复照片检测 | 基于 Vision FeaturePrint 的重复/相似照片索引 | 🚧 开发中 |
| 搜索 | 日期、媒体类型、OCR 文本与本地分类组合搜索 | ✅ 已完成 |
| JSON 导出 | 导出照片扫描与本地分析结果 | ✅ 已完成 |
| Markdown 导出 | 导出可阅读的照片与 OCR 分析报告 | ✅ 已完成 |

> 🔒 所有分析在本机完成；不会上传照片、OCR 文本或分析结果，也不会创建、修改、移动或删除 Photos 中的任何项目。

## 🖼️ 项目截图

<!-- 将截图放入 docs/images/ 后，可在此处替换为：![PhotosAI 主界面](docs/images/main-window.png) -->

_截图即将补充。_

## 🧰 技术栈

- **SwiftUI**：原生 macOS 界面
- **PhotoKit**：只读访问 Photos 图库
- **Vision**：OCR、图像分类与 FeaturePrint
- **CoreImage**：图像处理能力基础
- **MVVM**：清晰分离界面、状态与服务层
- **Swift Concurrency / Combine**：后台任务与响应式状态更新

## 🗂️ 项目结构

```text
PhotosAIApp/
├── PhotosAI.xcodeproj
├── PhotosAI/
│   ├── Models/          # 照片、OCR、内容分析、重复检测模型
│   ├── Services/        # PhotoKit、Vision、索引与导出服务
│   ├── ViewModels/      # PhotoLibraryViewModel
│   ├── Views/           # SwiftUI 页面、网格、详情与分析面板
│   ├── Resources/       # Info.plist
│   └── PhotosAI.entitlements
└── README.md
```

## 🚀 安装与运行

### 环境要求

- macOS 13 Ventura 或更高版本
- Xcode 16.2 或更高版本
- Apple ID（用于本机签名）

### 运行步骤

1. 克隆或下载本仓库。
2. 使用 Xcode 打开 `PhotosAI.xcodeproj`。
3. 选择 **PhotosAI** target，在 **Signing & Capabilities** 中选择你的 Development Team。
4. 保持 App Sandbox、Photos Library 与 User Selected File Read/Write 能力开启。
5. 选择 `My Mac`，按 <kbd>⌘</kbd> + <kbd>R</kbd> 运行。
6. 首次启动时，在系统提示中允许 PhotosAI 访问照片。
7. 点击“扫描照片库”，开始本地只读分析。

> 如曾拒绝权限，请在“系统设置 → 隐私与安全性 → 照片”中重新允许 PhotosAI 访问图库。

## 🗺️ Roadmap

- [x] PhotoKit 图库扫描
- [x] 本地 OCR 与 OCR 索引
- [x] 本地内容分类
- [ ] OpenAI Vision
- [ ] AI 自动标签
- [ ] AI 搜索
- [ ] 自动整理相册
- [ ] 智能回忆

## 📄 License

本项目采用 [MIT License](LICENSE)。
