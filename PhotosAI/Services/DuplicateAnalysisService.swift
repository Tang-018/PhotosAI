import Photos
import Vision

struct DuplicateProgress { var completed = 0; var total = 0; var matches = 0 }

/// Read-only, bounded V5 duplicate pass. Feature prints are held only for the active scan.
final class DuplicateAnalysisService {
    private let featurePrints = FeaturePrintService()
    private let store: DuplicateStore
    init(store: DuplicateStore = DuplicateStore()) { self.store = store }

    func analyze(_ pairs: [(PHAsset, PhotoAsset)], progress: @escaping @Sendable (DuplicateProgress) -> Void) async -> [DuplicateMatch] {
        var fingerprints: [(String, VNFeaturePrintObservation)] = []
        var matches = store.all; var state = DuplicateProgress(total: pairs.count); var sinceLastSave = 0
        for (asset, metadata) in pairs where metadata.mediaType == .photo {
            if Task.isCancelled { break }
            guard store.shouldScan(metadata) else { state.completed += 1; progress(state); continue }
            do {
                let print = try await featurePrints.featurePrint(for: asset)
                for (previousID, previous) in fingerprints {
                    let distance = try featurePrints.distance(print, previous)
                    guard distance < 12 else { continue }
                    matches.append(DuplicateMatch(id: "\(previousID)|\(metadata.id)", assetA: previousID, assetB: metadata.id, distance: distance, kind: distance < 2 ? "完全重复" : "相似图片", createdAt: Date()))
                }
                fingerprints.append((metadata.id, print))
                store.markCompleted(metadata)
            } catch { store.markFailed(metadata) }
            state.completed += 1; sinceLastSave += 1; state.matches = matches.count; progress(state)
            if sinceLastSave == 50 { try? store.replace(matches); sinceLastSave = 0 }
        }
        try? store.replace(matches)
        return matches
    }
}
