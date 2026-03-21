import Foundation

protocol BackgroundExecutionService: Sendable {
    func beginTrackingSession(name: String) async -> UUID
    func endTrackingSession(id: UUID) async
}
