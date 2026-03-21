import Foundation

protocol DriveTrackingService: Sendable {
    func startMonitoring() async
    func startManualDrive(vehicleID: UUID?) async throws
    func stopActiveDrive() async throws -> Drive?
}
