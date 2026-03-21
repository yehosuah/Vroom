import Foundation

protocol SyncQueueRepository: Sendable {
    func enqueue(_ envelope: SyncChangeEnvelope) async throws
    func pendingChanges() async throws -> [SyncChangeEnvelope]
    func markSynced(ids: [UUID]) async throws
}
