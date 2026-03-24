import Foundation

struct DriveSession: Codable, Hashable, Identifiable, Sendable {
    var id: UUID { sessionID }
    var sessionID: UUID
    var state: DriveSessionState
    var recordingMode: DriveRecordingMode
    var startedAt: Date
    var activeVehicleID: UUID?
    var liveMetrics: DriveLiveMetrics
}
