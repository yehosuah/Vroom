import Foundation

final class IdentityServiceImpl: @unchecked Sendable, IdentityService {
    private let profileRepository: ProfileRepository

    init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }

    func currentProfileID() async throws -> UUID? {
        try await profileRepository.loadProfile()?.id
    }
}
