import Foundation
import SwiftData

final class TrapRepositoryImpl: @unchecked Sendable, TrapRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func listTraps(vehicleID: UUID?) async throws -> [SpeedTrap] {
        let context = ModelContext(container)
        let driveIDs: Set<UUID>
        if let vehicleID {
            let drives = try context.fetch(FetchDescriptor<DriveRecord>()).map(\.domainModel).filter { $0.vehicleID == vehicleID }
            driveIDs = Set(drives.map(\.id))
        } else {
            driveIDs = []
        }
        return try context.fetch(FetchDescriptor<SpeedTrapRecord>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])).map(\.domainModel).filter { trap in
            vehicleID == nil || driveIDs.contains(trap.driveID)
        }
    }

    func saveTrapCandidates(_ traps: [SpeedTrap]) async throws {
        let context = ModelContext(container)
        let existing = try context.fetch(FetchDescriptor<SpeedTrapRecord>())
        for trap in traps where !existing.contains(where: { $0.id == trap.id }) {
            context.insert(SpeedTrapRecord(trap: trap))
        }
        try context.save()
    }

    func favoriteTrap(id: UUID, isFavorite: Bool) async throws {
        let context = ModelContext(container)
        if let trap = try context.fetch(FetchDescriptor<SpeedTrapRecord>()).first(where: { $0.id == id }) {
            trap.isFavorite = isFavorite
            try context.save()
        }
    }
}
