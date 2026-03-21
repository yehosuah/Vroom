import Foundation
import SwiftData

final class ConvoyCacheRepositoryImpl: @unchecked Sendable, ConvoyCacheRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func saveRecentConvoy(_ convoy: Convoy) async throws {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<ConvoyCacheRecord>())
        if let existing = records.first(where: { $0.id == convoy.id }) {
            let replacement = ConvoyCacheRecord(convoy: convoy)
            existing.joinCode = replacement.joinCode
            existing.hostProfileID = replacement.hostProfileID
            existing.createdAt = replacement.createdAt
            existing.statusRaw = replacement.statusRaw
            existing.settingsData = replacement.settingsData
        } else {
            context.insert(ConvoyCacheRecord(convoy: convoy))
        }
        try context.save()
    }

    func loadRecentConvoys() async throws -> [Convoy] {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<ConvoyCacheRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])).map(\.domainModel)
    }
}
