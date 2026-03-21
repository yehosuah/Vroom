import Foundation
import SwiftData

@Model
final class SubscriptionSnapshotRecord {
    @Attribute(.unique) var id: String
    var tierRaw: String
    var productsData: Data
    var renewalStateRaw: String
    var expirationDate: Date?
    var lastValidatedAt: Date

    init(id: String = "default", tierRaw: String, productsData: Data, renewalStateRaw: String, expirationDate: Date?, lastValidatedAt: Date) {
        self.id = id
        self.tierRaw = tierRaw
        self.productsData = productsData
        self.renewalStateRaw = renewalStateRaw
        self.expirationDate = expirationDate
        self.lastValidatedAt = lastValidatedAt
    }
}

extension SubscriptionSnapshotRecord {
    convenience init(snapshot: SubscriptionSnapshot) {
        let encoder = JSONEncoder()
        self.init(
            tierRaw: snapshot.tier.rawValue,
            productsData: (try? encoder.encode(snapshot.products)) ?? Data(),
            renewalStateRaw: snapshot.renewalState.rawValue,
            expirationDate: snapshot.expirationDate,
            lastValidatedAt: snapshot.lastValidatedAt
        )
    }

    var domainModel: SubscriptionSnapshot {
        let decoder = JSONDecoder()
        return SubscriptionSnapshot(
            tier: SubscriptionTier(rawValue: tierRaw) ?? .free,
            products: (try? decoder.decode([StoreProductSnapshot].self, from: productsData)) ?? [],
            renewalState: RenewalState(rawValue: renewalStateRaw) ?? .none,
            expirationDate: expirationDate,
            lastValidatedAt: lastValidatedAt
        )
    }
}
