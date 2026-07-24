import Foundation
enum ContentCategory: String, Codable, CaseIterable, Identifiable { case screenshot, chat, document, invoice, receipt, identityDocument, code, aiLearning, socialMedia, webpage, food, scenery, person, animal, vehicle, product, travel, work, health, unknown; var id: String { rawValue }; var title: String { rawValue } }
enum TagSource: String, Codable { case vision, ocr, metadata, rule, user }
enum ContentAnalysisStatus: String, Codable { case pending, processing, completed, insufficientData, failed }
struct ContentTag: Identifiable, Codable, Hashable { let id: String; let name: String; let confidence: Double; let source: TagSource }
struct ContentAnalysisRecord: Identifiable, Codable, Hashable { let id: String; let assetLocalIdentifier: String; var primaryCategory: ContentCategory; var tags: [ContentTag]; var summary: String?; var visionLabels: [ContentTag]; var ocrKeywords: [String]; var analysisDate: Date; var status: ContentAnalysisStatus; var errorMessage: String?; var sourceFingerprint: String; var modelVersion: String }
