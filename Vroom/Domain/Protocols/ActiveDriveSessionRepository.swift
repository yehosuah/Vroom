import Foundation

struct ActiveDriveSessionCheckpoint: Codable, Hashable, Sendable {
    var driveID: UUID
    var startedAt: Date
    var vehicleID: UUID?
    var recordingMode: DriveRecordingMode
}

protocol ActiveDriveSessionRepository: Sendable {
    func loadCheckpoint() async throws -> ActiveDriveSessionCheckpoint?
    func saveCheckpoint(_ checkpoint: ActiveDriveSessionCheckpoint) async throws
    func clearCheckpoint() async throws
}
