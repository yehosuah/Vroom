import Foundation
import SwiftData

@Model
final class AppPreferencesRecord {
    @Attribute(.unique) var id: String
    var unitsRaw: String
    var mapStyleRaw: String
    var replayAutoplay: Bool
    var batteryModeRaw: String
    var analyticsEnabled: Bool
    var preciseExports: Bool
    var retainDeletedData: Bool

    init(id: String = "default", unitsRaw: String, mapStyleRaw: String, replayAutoplay: Bool, batteryModeRaw: String, analyticsEnabled: Bool, preciseExports: Bool, retainDeletedData: Bool) {
        self.id = id
        self.unitsRaw = unitsRaw
        self.mapStyleRaw = mapStyleRaw
        self.replayAutoplay = replayAutoplay
        self.batteryModeRaw = batteryModeRaw
        self.analyticsEnabled = analyticsEnabled
        self.preciseExports = preciseExports
        self.retainDeletedData = retainDeletedData
    }
}

extension AppPreferencesRecord {
    convenience init(preferences: AppPreferences) {
        self.init(
            unitsRaw: preferences.units.rawValue,
            mapStyleRaw: preferences.mapStyle.rawValue,
            replayAutoplay: preferences.replayAutoplay,
            batteryModeRaw: preferences.batteryMode.rawValue,
            analyticsEnabled: preferences.privacyOptions.analyticsEnabled,
            preciseExports: preferences.privacyOptions.preciseExports,
            retainDeletedData: preferences.privacyOptions.retainDeletedData
        )
    }

    var domainModel: AppPreferences {
        AppPreferences(
            units: UnitSystem(rawValue: unitsRaw) ?? .imperial,
            mapStyle: AppMapStyle(rawValue: mapStyleRaw) ?? .standard,
            replayAutoplay: replayAutoplay,
            batteryMode: BatteryMode(rawValue: batteryModeRaw) ?? .balanced,
            privacyOptions: PrivacyOptions(
                analyticsEnabled: analyticsEnabled,
                preciseExports: preciseExports,
                retainDeletedData: retainDeletedData
            )
        )
    }
}
