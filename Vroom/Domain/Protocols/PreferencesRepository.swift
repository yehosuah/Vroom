import Foundation

protocol PreferencesRepository: Sendable {
    func loadPreferences() async throws -> AppPreferences
    func savePreferences(_ preferences: AppPreferences) async throws
}
