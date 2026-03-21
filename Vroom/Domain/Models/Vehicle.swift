import Foundation

struct Vehicle: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var nickname: String
    var make: String
    var model: String
    var year: Int
    var isPrimary: Bool
    var archivedAt: Date?

    var displayName: String {
        let details = [make, model].filter { !$0.isEmpty }.joined(separator: " ")
        if details.isEmpty { return nickname }
        return "\(nickname) • \(details)"
    }
}
