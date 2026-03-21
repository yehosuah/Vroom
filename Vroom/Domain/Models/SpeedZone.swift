import Foundation

struct SpeedZone: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var startMarker: GeoCoordinate
    var endMarker: GeoCoordinate
    var vehicleScope: UUID?
    var createdAt: Date
    var status: SpeedZoneStatus
}

struct SpeedZoneRun: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var zoneID: UUID
    var driveID: UUID
    var elapsed: TimeInterval
    var entrySpeedKPH: Double
    var exitSpeedKPH: Double
    var peakSpeedKPH: Double
    var completedAt: Date
}
