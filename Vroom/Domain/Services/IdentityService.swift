import Foundation

protocol IdentityService: Sendable {
    func currentProfileID() async throws -> UUID?
}
