import Foundation
final class DuplicateStore { private var matches: [DuplicateMatch] = []; private var scans: [String: DuplicateScanRecord] = [:]; private let url: URL; private let version = "featureprint-v1"
    private struct Index: Codable { let duplicateIndexVersion: String; let matches: [DuplicateMatch]; let scans: [DuplicateScanRecord] }
    init() { let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("PhotosAI", isDirectory: true); try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true); url = base.appendingPathComponent("duplicate_index.json"); if let data = try? Data(contentsOf: url), let index = try? JSONDecoder().decode(Index.self, from: data) { matches = index.matches; scans = Dictionary(uniqueKeysWithValues: index.scans.map { ($0.assetID, $0) }) } }
    func replace(_ value: [DuplicateMatch]) throws { matches = value; try save() }
    func shouldScan(_ photo: PhotoAsset) -> Bool { guard let old = scans[photo.id] else { return true }; return old.status != .completed || old.featurePrintVersion != version || old.pixelWidth != photo.pixelWidth || old.pixelHeight != photo.pixelHeight || old.creationDate != photo.creationDate }
    func markCompleted(_ photo: PhotoAsset) { scans[photo.id] = DuplicateScanRecord(assetID: photo.id, status: .completed, scanTime: Date(), featurePrintVersion: version, visionVersion: "Vision", pixelWidth: photo.pixelWidth, pixelHeight: photo.pixelHeight, creationDate: photo.creationDate, lastUpdate: Date()) }
    func markFailed(_ photo: PhotoAsset) { scans[photo.id] = DuplicateScanRecord(assetID: photo.id, status: .failed, scanTime: Date(), featurePrintVersion: version, visionVersion: "Vision", pixelWidth: photo.pixelWidth, pixelHeight: photo.pixelHeight, creationDate: photo.creationDate, lastUpdate: Date()) }
    func save() throws { let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; try e.encode(Index(duplicateIndexVersion: version, matches: matches, scans: Array(scans.values))).write(to: url, options: .atomic) }
    var all: [DuplicateMatch] { matches }
    func searchDuplicates() -> [DuplicateMatch] { matches.filter { $0.kind == "完全重复" }.sorted { $0.distance < $1.distance } }
    func searchSimilar(minimumSimilarity: Float = 0.85) -> [DuplicateMatch] { matches.filter { $0.kind == "相似图片" && $0.distance <= (1 - minimumSimilarity) * 20 }.sorted { $0.distance < $1.distance } }
    func groupDuplicates() -> [[DuplicateMatch]] { Dictionary(grouping: searchDuplicates(), by: \.assetA).values.map(Array.init) }
    func groupSimilar(minimumSimilarity: Float = 0.85) -> [[DuplicateMatch]] { Dictionary(grouping: searchSimilar(minimumSimilarity: minimumSimilarity), by: \.assetA).values.map(Array.init) }
}
