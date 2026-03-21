import Foundation
import SwiftData

final class DrivingEventRepositoryImpl: @unchecked Sendable, DrivingEventRepository {
    private let container: ModelContainer
    private let clock: any AppClock

    init(container: ModelContainer, clock: any AppClock) {
        self.container = container
        self.clock = clock
    }

    func saveEvents(_ events: [DrivingEvent]) async throws {
        let context = ModelContext(container)
        let existing = try context.fetch(FetchDescriptor<DrivingEventRecord>())
        for event in events {
            if existing.contains(where: { $0.id == event.id }) { continue }
            context.insert(DrivingEventRecord(event: event))
        }
        try context.save()
    }

    func eventsForDrive(id: UUID) async throws -> [DrivingEvent] {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<DrivingEventRecord>(sortBy: [SortDescriptor(\.timestamp)])).map(\.domainModel).filter { $0.driveID == id }
    }

    func eventCounts(period: InsightPeriod, vehicleID: UUID?) async throws -> [DrivingEventType: Int] {
        let context = ModelContext(container)
        let cutoff = period.startDate(from: clock.now)
        let drives = try context.fetch(FetchDescriptor<DriveRecord>()).map(\.domainModel)
        let driveIDs = Set(drives.filter { $0.startedAt >= cutoff && (vehicleID == nil || $0.vehicleID == vehicleID) }.map(\.id))
        let events = try context.fetch(FetchDescriptor<DrivingEventRecord>()).map(\.domainModel).filter { driveIDs.contains($0.driveID) }
        return Dictionary(grouping: events, by: \.type).mapValues(\.count)
    }
}
