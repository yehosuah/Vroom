import Foundation
import SwiftData

final class SyncQueueRepositoryImpl: @unchecked Sendable, SyncQueueRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func enqueue(_ envelope: SyncChangeEnvelope) async throws {
        let context = ModelContext(container)
        context.insert(SyncChangeEnvelopeRecord(envelope: envelope))
        try context.save()
    }

    func pendingChanges() async throws -> [SyncChangeEnvelope] {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<SyncChangeEnvelopeRecord>(sortBy: [SortDescriptor(\.updatedAt)])).map(\.domainModel).filter { $0.status != .synced }
    }

    func markSynced(ids: [UUID]) async throws {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<SyncChangeEnvelopeRecord>())
        for record in records where ids.contains(record.id) {
            record.statusRaw = SyncStatus.synced.rawValue
        }
        try context.save()
    }
}
