import Foundation
import SwiftData

final class ZoneRepositoryImpl: @unchecked Sendable, ZoneRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func listZones(vehicleID: UUID?) async throws -> [SpeedZone] {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<SpeedZoneRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])).map(\.domainModel).filter { zone in
            zone.status == .active && (vehicleID == nil || zone.vehicleScope == nil || zone.vehicleScope == vehicleID)
        }
    }

    func runsForZone(id: UUID) async throws -> [SpeedZoneRun] {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<SpeedZoneRunRecord>(sortBy: [SortDescriptor(\.completedAt, order: .reverse)])).map(\.domainModel).filter { $0.zoneID == id }
    }

    func saveZone(_ zone: SpeedZone) async throws {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<SpeedZoneRecord>())
        if let existing = records.first(where: { $0.id == zone.id }) {
            existing.name = zone.name
            existing.startLatitude = zone.startMarker.latitude
            existing.startLongitude = zone.startMarker.longitude
            existing.endLatitude = zone.endMarker.latitude
            existing.endLongitude = zone.endMarker.longitude
            existing.vehicleScope = zone.vehicleScope
            existing.createdAt = zone.createdAt
            existing.statusRaw = zone.status.rawValue
        } else {
            context.insert(SpeedZoneRecord(zone: zone))
        }
        try context.save()
    }

    func recordRun(_ run: SpeedZoneRun) async throws {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<SpeedZoneRunRecord>())
        if !records.contains(where: { $0.id == run.id }) {
            context.insert(SpeedZoneRunRecord(run: run))
            try context.save()
        }
    }

    func personalBest(zoneID: UUID) async throws -> SpeedZoneRun? {
        try await runsForZone(id: zoneID).min(by: { $0.elapsed < $1.elapsed })
    }
}
