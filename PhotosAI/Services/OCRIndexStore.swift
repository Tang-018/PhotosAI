import Foundation

final class OCRIndexStore {
    private var records: [String: OCRRecord] = [:]
    private let url: URL
    init(fileURL: URL? = nil) { let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("PhotosAI", isDirectory: true); try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true); url = fileURL ?? base.appendingPathComponent("ocr_index.json"); load() }
    func load() { guard let data = try? Data(contentsOf: url), let decoded = try? JSONDecoder().decode([OCRRecord].self, from: data) else { return }; records = Dictionary(uniqueKeysWithValues: decoded.map { ($0.assetLocalIdentifier, $0) }) }
    func save() throws { let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; try e.encode(Array(records.values)).write(to: url, options: .atomic) }
    func upsert(_ record: OCRRecord) { records[record.assetLocalIdentifier] = record }
    func record(for id: String) -> OCRRecord? { records[id] }
    func clearAll() throws { records = [:]; try save() }
    func search(_ query: String) -> Set<String> { let terms = OCRRecord.normalize(query).split(separator: " "); guard !terms.isEmpty else { return [] }; return Set(records.values.filter { record in terms.allSatisfy { record.normalizedText.contains($0) } }.map(\.assetLocalIdentifier)) }
    var all: [String: OCRRecord] { records }
    func export(to folder: URL) throws { let records = Array(records.values); let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; e.outputFormatting = [.prettyPrinted, .sortedKeys]; try e.encode(records).write(to: folder.appendingPathComponent("ocr_records.json"), options: .atomic); let text = records.map { "## \($0.assetLocalIdentifier)\n状态：\($0.status.rawValue)\n\n\($0.recognizedText)" }.joined(separator: "\n\n"); try text.write(to: folder.appendingPathComponent("ocr_records.md"), atomically: true, encoding: .utf8); try records.map(\.recognizedText).joined(separator: "\n\n").write(to: folder.appendingPathComponent("ocr_all_text.txt"), atomically: true, encoding: .utf8) }
}
