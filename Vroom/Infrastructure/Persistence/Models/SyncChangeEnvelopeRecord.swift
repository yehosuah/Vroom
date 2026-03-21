import Foundation
import SwiftData

@Model
final class SyncChangeEnvelopeRecord {
    @Attribute(.unique) var id: UUID
    var entityTypeRaw: String
    var entityID: UUID
    var changeTypeRaw: String
    var version: Int
    var updatedAt: Date
    var statusRaw: String

    init(id: UUID, entityTypeRaw: String, entityID: UUID, changeTypeRaw: String, version: Int, updatedAt: Date, statusRaw: String) {
        self.id = id
        self.entityTypeRaw = entityTypeRaw
        self.entityID = entityID
        self.changeTypeRaw = changeTypeRaw
        self.version = version
        self.updatedAt = updatedAt
        self.statusRaw = statusRaw
    }
}

extension SyncChangeEnvelopeRecord {
    convenience init(envelope: SyncChangeEnvelope) {
        self.init(
            id: envelope.id,
            entityTypeRaw: envelope.entityType.rawValue,
            entityID: envelope.entityID,
            changeTypeRaw: envelope.changeType.rawValue,
            version: envelope.version,
            updatedAt: envelope.updatedAt,
            statusRaw: envelope.status.rawValue
        )
    }

    var domainModel: SyncChangeEnvelope {
        SyncChangeEnvelope(
            id: id,
            entityType: SyncEntityType(rawValue: entityTypeRaw) ?? .drive,
            entityID: entityID,
            changeType: SyncChangeType(rawValue: changeTypeRaw) ?? .upsert,
            version: version,
            updatedAt: updatedAt,
            status: SyncStatus(rawValue: statusRaw) ?? .pending
        )
    }
}
