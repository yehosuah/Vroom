import Foundation
import SwiftData

final class ProfileRepositoryImpl: @unchecked Sendable, ProfileRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func loadProfile() async throws -> UserProfile? {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<UserProfileRecord>(sortBy: [SortDescriptor(\.createdAt)])
        return try context.fetch(descriptor).first?.domainModel
    }

    func saveProfile(_ profile: UserProfile) async throws {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<UserProfileRecord>()
        if let existing = try context.fetch(descriptor).first(where: { $0.id == profile.id }) {
            existing.displayName = profile.displayName
            existing.avatarStyleRaw = profile.avatarStyle.rawValue
            existing.createdAt = profile.createdAt
            existing.defaultVehicleID = profile.defaultVehicleID
            existing.onboardingStateRaw = profile.onboardingState.rawValue
        } else {
            context.insert(UserProfileRecord(profile: profile))
        }
        try context.save()
    }

    func resetProfile() async throws {
        let context = ModelContext(container)
        try context.fetch(FetchDescriptor<UserProfileRecord>()).forEach(context.delete)
        try context.save()
    }
}
