import Foundation

protocol TrapRepository: Sendable {
    func listTraps(vehicleID: UUID?) async throws -> [SpeedTrap]
    func saveTrapCandidates(_ traps: [SpeedTrap]) async throws
    func favoriteTrap(id: UUID, isFavorite: Bool) async throws
}
