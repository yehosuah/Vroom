import Foundation

protocol UUIDGenerating: Sendable {
    func callAsFunction() -> UUID
}

struct UUIDGenerator: UUIDGenerating {
    func callAsFunction() -> UUID {
        UUID()
    }
}
