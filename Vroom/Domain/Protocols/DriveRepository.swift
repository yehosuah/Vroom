import Foundation

protocol DriveRepository: Sendable {
    func saveDrive(_ drive: Drive) async throws
    func fetchHistory(vehicleID: UUID?, query: String?) async throws -> [Drive]
    func fetchDrive(id: UUID) async throws -> Drive?
    func setFavorite(driveID: UUID, isFavorite: Bool) async throws
    func assignVehicle(driveID: UUID, vehicleID: UUID?) async throws
}
