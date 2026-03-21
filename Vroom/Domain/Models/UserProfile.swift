import Foundation

struct UserProfile: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var displayName: String
    var avatarStyle: AvatarStyle
    var createdAt: Date
    var defaultVehicleID: UUID?
    var onboardingState: OnboardingState
}
