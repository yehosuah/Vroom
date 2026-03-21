import Foundation

protocol SubscriptionRepository: Sendable {
    func loadSnapshot() async throws -> SubscriptionSnapshot
    func saveSnapshot(_ snapshot: SubscriptionSnapshot) async throws
    func clearSnapshot() async throws
}
