import Foundation

struct NoopSyncEngine: SyncEngine {
    func processPendingChanges() async throws {
    }
}
