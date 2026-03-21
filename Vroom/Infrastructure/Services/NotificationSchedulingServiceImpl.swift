import Foundation
import UserNotifications

final class NotificationSchedulingServiceImpl: @unchecked Sendable, NotificationSchedulingService {
    private let center = UNUserNotificationCenter.current()

    func authorizationState() async -> NotificationAuthorizationStatus {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized: return .authorized
        case .provisional, .ephemeral: return .provisional
        @unknown default: return .notDetermined
        }
    }

    func requestAuthorization() async -> NotificationAuthorizationStatus {
        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        return await authorizationState()
    }

    func scheduleDriveSummary(for drive: Drive) async throws {
        let content = UNMutableNotificationContent()
        content.title = drive.summary.title
        content.body = drive.summary.highlight
        let request = UNNotificationRequest(identifier: drive.id.uuidString, content: content, trigger: nil)
        try await center.add(request)
    }

    func scheduleConvoyPrompt(for convoy: Convoy) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Convoy Ready"
        content.body = "Join convoy \(convoy.joinCode) when you are ready to roll."
        let request = UNNotificationRequest(identifier: convoy.id.uuidString, content: content, trigger: nil)
        try await center.add(request)
    }
}
