import Foundation
struct DuplicateMatch: Codable, Hashable, Identifiable { let id: String; let assetA: String; let assetB: String; let distance: Float; let kind: String; let createdAt: Date }
enum DuplicateScanStatus: String, Codable { case pending, completed, failed }
struct DuplicateScanRecord: Codable, Hashable { let assetID: String; var status: DuplicateScanStatus; var scanTime: Date?; var featurePrintVersion: String; var visionVersion: String; var pixelWidth: Int; var pixelHeight: Int; var creationDate: Date?; var lastUpdate: Date }
