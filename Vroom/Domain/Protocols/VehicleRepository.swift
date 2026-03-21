import Foundation

protocol VehicleRepository: Sendable {
    func listVehicles() async throws -> [Vehicle]
    func saveVehicle(_ vehicle: Vehicle) async throws
    func archiveVehicle(id: UUID) async throws
    func statsForVehicle(id: UUID) async throws -> VehicleStats
}
