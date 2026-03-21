import Foundation
import SwiftData

final class ActiveDriveSessionRepositoryImpl: @unchecked Sendable, ActiveDriveSessionRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func loadCheckpoint() async throws -> ActiveDriveSessionCheckpoint? {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<ActiveDriveSessionRecord>()).first?.domainModel
    }

    func saveCheckpoint(_ checkpoint: ActiveDriveSessionCheckpoint) async throws {
        let context = ModelContext(container)
        if let existing = try context.fetch(FetchDescriptor<ActiveDriveSessionRecord>()).first {
            existing.id = checkpoint.driveID
            existing.startedAt = checkpoint.startedAt
            existing.vehicleID = checkpoint.vehicleID
            existing.recordingModeRaw = checkpoint.recordingMode.rawValue
        } else {
            context.insert(ActiveDriveSessionRecord(checkpoint: checkpoint))
        }
        try context.save()
    }

    func clearCheckpoint() async throws {
        let context = ModelContext(container)
        try context.fetch(FetchDescriptor<ActiveDriveSessionRecord>()).forEach(context.delete)
        try context.save()
    }
}
