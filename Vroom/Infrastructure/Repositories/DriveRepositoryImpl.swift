import Foundation
import SwiftData

final class DriveRepositoryImpl: @unchecked Sendable, DriveRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func saveDrive(_ drive: Drive) async throws {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<DriveRecord>())
        if let existing = records.first(where: { $0.id == drive.id }) {
            let replacement = DriveRecord(drive: drive)
            existing.vehicleID = replacement.vehicleID
            existing.startedAt = replacement.startedAt
            existing.endedAt = replacement.endedAt
            existing.distanceMeters = replacement.distanceMeters
            existing.duration = replacement.duration
            existing.avgSpeedKPH = replacement.avgSpeedKPH
            existing.topSpeedKPH = replacement.topSpeedKPH
            existing.favorite = replacement.favorite
            existing.overallScore = replacement.overallScore
            existing.scoreSubscoresData = replacement.scoreSubscoresData
            existing.scoreDeductionsData = replacement.scoreDeductionsData
            existing.scoreProfileID = replacement.scoreProfileID
            existing.traceRef = replacement.traceRef
            existing.summaryTitle = replacement.summaryTitle
            existing.summaryHighlight = replacement.summaryHighlight
            existing.summaryEventCount = replacement.summaryEventCount
        } else {
            context.insert(DriveRecord(drive: drive))
        }
        try context.save()
    }

    func fetchHistory(vehicleID: UUID?, query: String?) async throws -> [Drive] {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<DriveRecord>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)]))
        return records.map(\.domainModel).filter { drive in
            let vehicleMatches = vehicleID == nil || drive.vehicleID == vehicleID
            let queryMatches: Bool
            if let query, !query.isEmpty {
                let normalized = query.lowercased()
                queryMatches = drive.summary.title.lowercased().contains(normalized) || drive.summary.highlight.lowercased().contains(normalized)
            } else {
                queryMatches = true
            }
            return vehicleMatches && queryMatches
        }
    }

    func fetchDrive(id: UUID) async throws -> Drive? {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<DriveRecord>()).first(where: { $0.id == id })?.domainModel
    }

    func setFavorite(driveID: UUID, isFavorite: Bool) async throws {
        let context = ModelContext(container)
        if let record = try context.fetch(FetchDescriptor<DriveRecord>()).first(where: { $0.id == driveID }) {
            record.favorite = isFavorite
            try context.save()
        }
    }

    func assignVehicle(driveID: UUID, vehicleID: UUID?) async throws {
        let context = ModelContext(container)
        if let record = try context.fetch(FetchDescriptor<DriveRecord>()).first(where: { $0.id == driveID }) {
            record.vehicleID = vehicleID
            try context.save()
        }
    }
}
