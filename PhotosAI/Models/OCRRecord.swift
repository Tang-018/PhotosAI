import Foundation

enum OCRStatus: String, Codable, Hashable { case pending, processing, completed, noText, failed }
struct OCRRecord: Identifiable, Codable, Hashable {
    let id: String; let assetLocalIdentifier: String; let recognizedText: String; let normalizedText: String
    let recognitionDate: Date; let creationDate: Date?; let confidence: Float?; let languageHints: [String]
    let status: OCRStatus; let sourceFingerprint: String; let errorMessage: String?
    static func normalize(_ text: String) -> String { text.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ") }
}
struct OCRProgress { var completed = 0; var total = 0; var recognized = 0; var noText = 0; var failed = 0; var skipped = 0 }
