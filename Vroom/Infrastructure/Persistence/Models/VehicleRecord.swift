import Foundation
import SwiftData

@Model
final class VehicleRecord {
    @Attribute(.unique) var id: UUID
    var nickname: String
    var make: String
    var model: String
    var year: Int
    var isPrimary: Bool
    var archivedAt: Date?

    init(id: UUID, nickname: String, make: String, model: String, year: Int, isPrimary: Bool, archivedAt: Date?) {
        self.id = id
        self.nickname = nickname
        self.make = make
        self.model = model
        self.year = year
        self.isPrimary = isPrimary
        self.archivedAt = archivedAt
    }
}

extension VehicleRecord {
    convenience init(vehicle: Vehicle) {
        self.init(
            id: vehicle.id,
            nickname: vehicle.nickname,
            make: vehicle.make,
            model: vehicle.model,
            year: vehicle.year,
            isPrimary: vehicle.isPrimary,
            archivedAt: vehicle.archivedAt
        )
    }

    var domainModel: Vehicle {
        Vehicle(
            id: id,
            nickname: nickname,
            make: make,
            model: model,
            year: year,
            isPrimary: isPrimary,
            archivedAt: archivedAt
        )
    }
}
