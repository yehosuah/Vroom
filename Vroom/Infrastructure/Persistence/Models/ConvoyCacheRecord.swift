import Foundation
import SwiftData

@Model
final class ConvoyCacheRecord {
    @Attribute(.unique) var id: UUID
    var joinCode: String
    var hostProfileID: UUID
    var createdAt: Date
    var statusRaw: String
    var settingsData: Data

    init(id: UUID, joinCode: String, hostProfileID: UUID, createdAt: Date, statusRaw: String, settingsData: Data) {
        self.id = id
        self.joinCode = joinCode
        self.hostProfileID = hostProfileID
        self.createdAt = createdAt
        self.statusRaw = statusRaw
        self.settingsData = settingsData
    }
}

extension ConvoyCacheRecord {
    convenience init(convoy: Convoy) {
        let encoder = JSONEncoder()
        self.init(
            id: convoy.id,
            joinCode: convoy.joinCode,
            hostProfileID: convoy.hostProfileID,
            createdAt: convoy.createdAt,
            statusRaw: convoy.status.rawValue,
            settingsData: (try? encoder.encode(convoy.settings)) ?? Data()
        )
    }

    var domainModel: Convoy {
        let decoder = JSONDecoder()
        return Convoy(
            id: id,
            joinCode: joinCode,
            hostProfileID: hostProfileID,
            createdAt: createdAt,
            status: ConvoyStatus(rawValue: statusRaw) ?? .lobby,
            settings: (try? decoder.decode(ConvoySettings.self, from: settingsData)) ?? .default
        )
    }
}
