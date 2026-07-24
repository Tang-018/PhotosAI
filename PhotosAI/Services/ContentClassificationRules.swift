import Foundation

/// Centralized, local OCR rule engine. Order defines primary-category priority.
enum ContentClassificationRules {
    struct Result { let category: ContentCategory; let tags: [ContentTag] }
    private static let rules: [(ContentCategory, String, [String])] = [
        (.identityDocument, "证件", ["身份证", "驾驶证", "护照", "银行卡"]),
        (.invoice, "发票", ["发票", "税额", "金额", "invoice"]),
        (.aiLearning, "AI", ["chatgpt", "claude", "gemini", "copilot", "cursor", "openai"]),
        (.code, "编程", ["代码", "swift", "python", "java", "github", "vscode", "xcode"]),
        (.work, "工作", ["会议", "排班", "日程", "calendar"]),
        (.travel, "出行", ["地图", "酒店", "飞机", "车票", "高铁"]),
        (.socialMedia, "社交", ["微信", "qq", "telegram", "discord", "slack"]),
        (.product, "购物", ["支付宝", "微信支付", "付款", "订单", "物流", "快递", "淘宝", "京东", "拼多多"]),
        (.document, "学习", ["课堂", "考试", "课程", "笔记"])
    ]
    static func classify(ocrText: String) -> Result? {
        let text = OCRRecord.normalize(ocrText); var matches: [(ContentCategory, ContentTag)] = []
        for (category, tag, terms) in rules where terms.contains(where: text.contains) {
            matches.append((category, ContentTag(id: "rule-\(tag)", name: tag, confidence: 0.95, source: .rule)))
        }
        guard let first = matches.first else { return nil }
        var seen = Set<String>(); let tags = matches.map(\.1).filter { seen.insert($0.name).inserted }
        return Result(category: first.0, tags: tags)
    }
}
