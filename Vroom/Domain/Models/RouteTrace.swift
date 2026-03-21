import Foundation

struct RouteTrace: Codable, Hashable, Sendable {
    var driveID: UUID
    var sampleCount: Int
    var bounds: GeoBounds
    var storageRef: String
    var compression: RouteTraceCompression
    var quality: RouteTraceQuality
}

struct RoutePointSample: Codable, Hashable, Sendable {
    var timestamp: Date
    var coordinate: GeoCoordinate
    var altitudeMeters: Double
    var verticalAccuracy: Double
    var horizontalAccuracy: Double
    var speedKPH: Double
    var courseDegrees: Double
    var headingAccuracy: Double
}
