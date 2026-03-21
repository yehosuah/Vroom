import Foundation
import SwiftData

final class SubscriptionRepositoryImpl: @unchecked Sendable, SubscriptionRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func loadSnapshot() async throws -> SubscriptionSnapshot {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<SubscriptionSnapshotRecord>()).first?.domainModel ?? .free
    }

    func saveSnapshot(_ snapshot: SubscriptionSnapshot) async throws {
        let context = ModelContext(container)
        if let existing = try context.fetch(FetchDescriptor<SubscriptionSnapshotRecord>()).first {
            let replacement = SubscriptionSnapshotRecord(snapshot: snapshot)
            existing.tierRaw = replacement.tierRaw
            existing.productsData = replacement.productsData
            existing.renewalStateRaw = replacement.renewalStateRaw
            existing.expirationDate = replacement.expirationDate
            existing.lastValidatedAt = replacement.lastValidatedAt
        } else {
            context.insert(SubscriptionSnapshotRecord(snapshot: snapshot))
        }
        try context.save()
    }

    func clearSnapshot() async throws {
        let context = ModelContext(container)
        try context.fetch(FetchDescriptor<SubscriptionSnapshotRecord>()).forEach(context.delete)
        try context.save()
    }
}
