import Foundation
import SwiftData

@Model
final class ActiveDriveSessionRecord {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var vehicleID: UUID?
    var recordingModeRaw: String

    init(id: UUID, startedAt: Date, vehicleID: UUID?, recordingModeRaw: String) {
        self.id = id
        self.startedAt = startedAt
        self.vehicleID = vehicleID
        self.recordingModeRaw = recordingModeRaw
    }
}

extension ActiveDriveSessionRecord {
    convenience init(checkpoint: ActiveDriveSessionCheckpoint) {
        self.init(
            id: checkpoint.driveID,
            startedAt: checkpoint.startedAt,
            vehicleID: checkpoint.vehicleID,
            recordingModeRaw: checkpoint.recordingMode.rawValue
        )
    }

    var domainModel: ActiveDriveSessionCheckpoint {
        ActiveDriveSessionCheckpoint(
            driveID: id,
            startedAt: startedAt,
            vehicleID: vehicleID,
            recordingMode: DriveRecordingMode(rawValue: recordingModeRaw) ?? .automatic
        )
    }
}
