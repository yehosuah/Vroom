import Foundation
import SwiftData

@Model
final class RoutePointRecord {
    @Attribute(.unique) var id: UUID
    var driveID: UUID
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var altitudeMeters: Double
    var verticalAccuracy: Double
    var horizontalAccuracy: Double
    var speedKPH: Double
    var courseDegrees: Double
    var headingAccuracy: Double
    var sequence: Int

    init(
        id: UUID,
        driveID: UUID,
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        altitudeMeters: Double,
        verticalAccuracy: Double,
        horizontalAccuracy: Double,
        speedKPH: Double,
        courseDegrees: Double,
        headingAccuracy: Double,
        sequence: Int
    ) {
        self.id = id
        self.driveID = driveID
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitudeMeters = altitudeMeters
        self.verticalAccuracy = verticalAccuracy
        self.horizontalAccuracy = horizontalAccuracy
        self.speedKPH = speedKPH
        self.courseDegrees = courseDegrees
        self.headingAccuracy = headingAccuracy
        self.sequence = sequence
    }
}

extension RoutePointRecord {
    convenience init(driveID: UUID, sample: RoutePointSample, sequence: Int) {
        self.init(
            id: UUID(),
            driveID: driveID,
            timestamp: sample.timestamp,
            latitude: sample.coordinate.latitude,
            longitude: sample.coordinate.longitude,
            altitudeMeters: sample.altitudeMeters,
            verticalAccuracy: sample.verticalAccuracy,
            horizontalAccuracy: sample.horizontalAccuracy,
            speedKPH: sample.speedKPH,
            courseDegrees: sample.courseDegrees,
            headingAccuracy: sample.headingAccuracy,
            sequence: sequence
        )
    }

    var domainModel: RoutePointSample {
        RoutePointSample(
            timestamp: timestamp,
            coordinate: GeoCoordinate(latitude: latitude, longitude: longitude),
            altitudeMeters: altitudeMeters,
            verticalAccuracy: verticalAccuracy,
            horizontalAccuracy: horizontalAccuracy,
            speedKPH: speedKPH,
            courseDegrees: courseDegrees,
            headingAccuracy: headingAccuracy
        )
    }
}
