import Foundation

struct SubscriptionSnapshot: Codable, Hashable, Sendable {
    var tier: SubscriptionTier
    var products: [StoreProductSnapshot]
    var renewalState: RenewalState
    var expirationDate: Date?
    var lastValidatedAt: Date

    static let free = SubscriptionSnapshot(
        tier: .free,
        products: [],
        renewalState: .none,
        expirationDate: nil,
        lastValidatedAt: .distantPast
    )
}

struct FeatureGateDecision: Codable, Hashable, Sendable {
    var feature: PremiumFeature
    var isUnlocked: Bool
    var reason: FeatureGateReason
    var source: FeatureGateSource
}
