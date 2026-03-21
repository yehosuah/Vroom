import Foundation
import StoreKit

final class StoreKitStorefrontService: @unchecked Sendable, StorefrontService {
    private let subscriptionRepository: any SubscriptionRepository
    private let productIDs: [String]

    init(subscriptionRepository: any SubscriptionRepository, productIDs: [String]) {
        self.subscriptionRepository = subscriptionRepository
        self.productIDs = productIDs
    }

    func fetchProducts() async throws -> [StoreProductSnapshot] {
        guard !productIDs.isEmpty else { return [] }
        let products = try await Product.products(for: productIDs)
        return products.map {
            StoreProductSnapshot(
                productID: $0.id,
                displayName: $0.displayName,
                priceDisplay: $0.displayPrice,
                tier: .premium
            )
        }
        .sorted { $0.productID < $1.productID }
    }

    func purchase(productID: String) async throws -> SubscriptionSnapshot {
        guard let product = try await Product.products(for: [productID]).first else {
            throw StoreKitError.unknown
        }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            _ = try checkVerified(verification)
            return try await refreshSnapshot()
        case .userCancelled, .pending:
            return try await refreshSnapshot()
        @unknown default:
            return try await refreshSnapshot()
        }
    }

    func restorePurchases() async throws -> SubscriptionSnapshot {
        try await AppStore.sync()
        return try await refreshSnapshot()
    }

    func refreshSnapshot() async throws -> SubscriptionSnapshot {
        let products = try await fetchProducts()
        var hasPremium = false
        var expirationDate: Date?

        for await result in Transaction.currentEntitlements {
            let transaction = try checkVerified(result)
            if productIDs.contains(transaction.productID) {
                hasPremium = true
                if let currentExpiration = transaction.expirationDate {
                    expirationDate = max(expirationDate ?? .distantPast, currentExpiration)
                }
            }
        }

        let snapshot = SubscriptionSnapshot(
            tier: hasPremium ? .premium : .free,
            products: products,
            renewalState: hasPremium ? .active : .none,
            expirationDate: expirationDate,
            lastValidatedAt: Date()
        )
        try await subscriptionRepository.saveSnapshot(snapshot)
        return snapshot
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.notEntitled
        case .verified(let value):
            return value
        }
    }
}
