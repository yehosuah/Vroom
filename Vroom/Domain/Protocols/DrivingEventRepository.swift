import Foundation

protocol DrivingEventRepository: Sendable {
    func saveEvents(_ events: [DrivingEvent]) async throws
    func eventsForDrive(id: UUID) async throws -> [DrivingEvent]
    func eventCounts(period: InsightPeriod, vehicleID: UUID?) async throws -> [DrivingEventType: Int]
}
