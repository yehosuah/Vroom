import Foundation
import SwiftData

@Model
final class UserProfileRecord {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var avatarStyleRaw: String
    var createdAt: Date
    var defaultVehicleID: UUID?
    var onboardingStateRaw: String

    init(id: UUID, displayName: String, avatarStyleRaw: String, createdAt: Date, defaultVehicleID: UUID?, onboardingStateRaw: String) {
        self.id = id
        self.displayName = displayName
        self.avatarStyleRaw = avatarStyleRaw
        self.createdAt = createdAt
        self.defaultVehicleID = defaultVehicleID
        self.onboardingStateRaw = onboardingStateRaw
    }
}

extension UserProfileRecord {
    convenience init(profile: UserProfile) {
        self.init(
            id: profile.id,
            displayName: profile.displayName,
            avatarStyleRaw: profile.avatarStyle.rawValue,
            createdAt: profile.createdAt,
            defaultVehicleID: profile.defaultVehicleID,
            onboardingStateRaw: profile.onboardingState.rawValue
        )
    }

    var domainModel: UserProfile {
        UserProfile(
            id: id,
            displayName: displayName,
            avatarStyle: AvatarStyle(rawValue: avatarStyleRaw) ?? .atlas,
            createdAt: createdAt,
            defaultVehicleID: defaultVehicleID,
            onboardingState: OnboardingState(rawValue: onboardingStateRaw) ?? .notStarted
        )
    }
}
