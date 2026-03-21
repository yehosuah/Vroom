import Foundation

protocol ProfileRepository: Sendable {
    func loadProfile() async throws -> UserProfile?
    func saveProfile(_ profile: UserProfile) async throws
    func resetProfile() async throws
}
