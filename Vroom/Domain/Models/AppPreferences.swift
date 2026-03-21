import Foundation

struct AppPreferences: Codable, Hashable, Sendable {
    var units: UnitSystem
    var mapStyle: AppMapStyle
    var replayAutoplay: Bool
    var batteryMode: BatteryMode
    var privacyOptions: PrivacyOptions

    static let `default` = AppPreferences(
        units: .imperial,
        mapStyle: .standard,
        replayAutoplay: true,
        batteryMode: .balanced,
        privacyOptions: .default
    )
}
