import Foundation

protocol EntitlementService: Sendable {
    func decision(for feature: PremiumFeature) async throws -> FeatureGateDecision
    func currentSnapshot() async throws -> SubscriptionSnapshot
}
