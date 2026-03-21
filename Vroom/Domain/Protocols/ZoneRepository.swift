import Foundation

protocol ZoneRepository: Sendable {
    func listZones(vehicleID: UUID?) async throws -> [SpeedZone]
    func runsForZone(id: UUID) async throws -> [SpeedZoneRun]
    func saveZone(_ zone: SpeedZone) async throws
    func recordRun(_ run: SpeedZoneRun) async throws
    func personalBest(zoneID: UUID) async throws -> SpeedZoneRun?
}
