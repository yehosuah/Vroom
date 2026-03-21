import Foundation
import SwiftData

final class VehicleRepositoryImpl: @unchecked Sendable, VehicleRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func listVehicles() async throws -> [Vehicle] {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<VehicleRecord>())
        return records
            .map(\.domainModel)
            .filter { $0.archivedAt == nil }
            .sorted { lhs, rhs in
                if lhs.isPrimary != rhs.isPrimary { return lhs.isPrimary && !rhs.isPrimary }
                return lhs.nickname.localizedCaseInsensitiveCompare(rhs.nickname) == .orderedAscending
            }
    }

    func saveVehicle(_ vehicle: Vehicle) async throws {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<VehicleRecord>())
        if vehicle.isPrimary {
            records.forEach { $0.isPrimary = $0.id == vehicle.id }
        }
        if let existing = records.first(where: { $0.id == vehicle.id }) {
            existing.nickname = vehicle.nickname
            existing.make = vehicle.make
            existing.model = vehicle.model
            existing.year = vehicle.year
            existing.isPrimary = vehicle.isPrimary
            existing.archivedAt = vehicle.archivedAt
        } else {
            context.insert(VehicleRecord(vehicle: vehicle))
        }
        try context.save()
    }

    func archiveVehicle(id: UUID) async throws {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<VehicleRecord>())
        if let record = records.first(where: { $0.id == id }) {
            record.archivedAt = Date()
            try context.save()
        }
    }

    func statsForVehicle(id: UUID) async throws -> VehicleStats {
        let context = ModelContext(container)
        let drives = try context.fetch(FetchDescriptor<DriveRecord>()).map(\.domainModel).filter { $0.vehicleID == id }
        guard !drives.isEmpty else { return .empty }
        return VehicleStats(
            driveCount: drives.count,
            distanceMeters: drives.reduce(0) { $0 + $1.distanceMeters },
            averageScore: drives.map { Double($0.scoreSummary.overall) }.reduce(0, +) / Double(drives.count),
            topSpeedKPH: drives.map(\.topSpeedKPH).max() ?? 0
        )
    }
}
