import Foundation

struct Drive: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var vehicleID: UUID?
    var startedAt: Date
    var endedAt: Date
    var distanceMeters: Double
    var duration: TimeInterval
    var avgSpeedKPH: Double
    var topSpeedKPH: Double
    var favorite: Bool
    var scoreSummary: DriveScoreSummary
    var traceRef: String
    var summary: DriveSummary
}
