import Foundation

struct Convoy: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var joinCode: String
    var hostProfileID: UUID
    var createdAt: Date
    var status: ConvoyStatus
    var settings: ConvoySettings
}

struct ConvoyParticipant: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var profileID: UUID
    var displayName: String
    var vehicleID: UUID?
    var presence: ParticipantPresence
    var lastLocation: GeoCoordinate?
    var lastUpdateAt: Date
}
