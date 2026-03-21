import Foundation

protocol NotificationSchedulingService: Sendable {
    func authorizationState() async -> NotificationAuthorizationStatus
    func requestAuthorization() async -> NotificationAuthorizationStatus
    func scheduleDriveSummary(for drive: Drive) async throws
    func scheduleConvoyPrompt(for convoy: Convoy) async throws
}
