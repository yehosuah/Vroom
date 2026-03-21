import Foundation

protocol StorefrontService: Sendable {
    func fetchProducts() async throws -> [StoreProductSnapshot]
    func purchase(productID: String) async throws -> SubscriptionSnapshot
    func restorePurchases() async throws -> SubscriptionSnapshot
}
