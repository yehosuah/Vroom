import Foundation

final class DefaultEntitlementService: @unchecked Sendable, EntitlementService {
    private let subscriptionRepository: SubscriptionRepository

    init(subscriptionRepository: SubscriptionRepository) {
        self.subscriptionRepository = subscriptionRepository
    }

    func decision(for feature: PremiumFeature) async throws -> FeatureGateDecision {
        let snapshot = try await subscriptionRepository.loadSnapshot()
        let unlocked = snapshot.tier == .premium
        return FeatureGateDecision(
            feature: feature,
            isUnlocked: unlocked,
            reason: unlocked ? .unlocked : .premiumRequired,
            source: unlocked ? .subscription : .launchPolicy
        )
    }

    func currentSnapshot() async throws -> SubscriptionSnapshot {
        try await subscriptionRepository.loadSnapshot()
    }
}
