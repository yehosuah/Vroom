import Foundation
import SwiftData

final class PreferencesRepositoryImpl: @unchecked Sendable, PreferencesRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func loadPreferences() async throws -> AppPreferences {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<AppPreferencesRecord>()).first?.domainModel ?? .default
    }

    func savePreferences(_ preferences: AppPreferences) async throws {
        let context = ModelContext(container)
        if let existing = try context.fetch(FetchDescriptor<AppPreferencesRecord>()).first {
            existing.unitsRaw = preferences.units.rawValue
            existing.mapStyleRaw = preferences.mapStyle.rawValue
            existing.replayAutoplay = preferences.replayAutoplay
            existing.batteryModeRaw = preferences.batteryMode.rawValue
            existing.analyticsEnabled = preferences.privacyOptions.analyticsEnabled
            existing.preciseExports = preferences.privacyOptions.preciseExports
            existing.retainDeletedData = preferences.privacyOptions.retainDeletedData
        } else {
            context.insert(AppPreferencesRecord(preferences: preferences))
        }
        try context.save()
    }
}
