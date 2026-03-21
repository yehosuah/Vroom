import Foundation

struct SyncChangeEnvelope: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var entityType: SyncEntityType
    var entityID: UUID
    var changeType: SyncChangeType
    var version: Int
    var updatedAt: Date
    var status: SyncStatus
}
