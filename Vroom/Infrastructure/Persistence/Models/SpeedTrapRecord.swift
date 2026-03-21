import Foundation
import SwiftData

@Model
final class SpeedTrapRecord {
    @Attribute(.unique) var id: UUID
    var driveID: UUID
    var timestamp: Date
    var peakSpeedKPH: Double
    var latitude: Double
    var longitude: Double
    var isFavorite: Bool

    init(id: UUID, driveID: UUID, timestamp: Date, peakSpeedKPH: Double, latitude: Double, longitude: Double, isFavorite: Bool) {
        self.id = id
        self.driveID = driveID
        self.timestamp = timestamp
        self.peakSpeedKPH = peakSpeedKPH
        self.latitude = latitude
        self.longitude = longitude
        self.isFavorite = isFavorite
    }
}

extension SpeedTrapRecord {
    convenience init(trap: SpeedTrap) {
        self.init(
            id: trap.id,
            driveID: trap.driveID,
            timestamp: trap.timestamp,
            peakSpeedKPH: trap.peakSpeedKPH,
            latitude: trap.coordinate.latitude,
            longitude: trap.coordinate.longitude,
            isFavorite: trap.isFavorite
        )
    }

    var domainModel: SpeedTrap {
        SpeedTrap(
            id: id,
            driveID: driveID,
            timestamp: timestamp,
            peakSpeedKPH: peakSpeedKPH,
            coordinate: GeoCoordinate(latitude: latitude, longitude: longitude),
            isFavorite: isFavorite
        )
    }
}
