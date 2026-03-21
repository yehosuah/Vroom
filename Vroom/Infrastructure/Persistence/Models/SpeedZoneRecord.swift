import Foundation
import SwiftData

@Model
final class SpeedZoneRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var startLatitude: Double
    var startLongitude: Double
    var endLatitude: Double
    var endLongitude: Double
    var vehicleScope: UUID?
    var createdAt: Date
    var statusRaw: String

    init(id: UUID, name: String, startLatitude: Double, startLongitude: Double, endLatitude: Double, endLongitude: Double, vehicleScope: UUID?, createdAt: Date, statusRaw: String) {
        self.id = id
        self.name = name
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.endLatitude = endLatitude
        self.endLongitude = endLongitude
        self.vehicleScope = vehicleScope
        self.createdAt = createdAt
        self.statusRaw = statusRaw
    }
}

extension SpeedZoneRecord {
    convenience init(zone: SpeedZone) {
        self.init(
            id: zone.id,
            name: zone.name,
            startLatitude: zone.startMarker.latitude,
            startLongitude: zone.startMarker.longitude,
            endLatitude: zone.endMarker.latitude,
            endLongitude: zone.endMarker.longitude,
            vehicleScope: zone.vehicleScope,
            createdAt: zone.createdAt,
            statusRaw: zone.status.rawValue
        )
    }

    var domainModel: SpeedZone {
        SpeedZone(
            id: id,
            name: name,
            startMarker: GeoCoordinate(latitude: startLatitude, longitude: startLongitude),
            endMarker: GeoCoordinate(latitude: endLatitude, longitude: endLongitude),
            vehicleScope: vehicleScope,
            createdAt: createdAt,
            status: SpeedZoneStatus(rawValue: statusRaw) ?? .active
        )
    }
}
