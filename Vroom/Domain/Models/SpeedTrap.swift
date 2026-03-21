import Foundation

struct SpeedTrap: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var driveID: UUID
    var timestamp: Date
    var peakSpeedKPH: Double
    var coordinate: GeoCoordinate
    var isFavorite: Bool
}
