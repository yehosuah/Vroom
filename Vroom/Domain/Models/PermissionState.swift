import Foundation

struct PermissionState: Codable, Hashable, Sendable {
    var location: LocationAuthorizationStatus
    var motion: MotionAuthorizationStatus
    var notifications: NotificationAuthorizationStatus

    static let empty = PermissionState(location: .notDetermined, motion: .notDetermined, notifications: .notDetermined)
}
