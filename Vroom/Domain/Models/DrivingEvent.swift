import Foundation

struct DrivingEvent: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var driveID: UUID
    var type: DrivingEventType
    var severity: DrivingEventSeverity
    var confidence: Double
    var timestamp: Date
    var coordinate: GeoCoordinate
    var metadata: [String: Double]
}
