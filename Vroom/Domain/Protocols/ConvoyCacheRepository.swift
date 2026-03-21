import Foundation

protocol ConvoyCacheRepository: Sendable {
    func saveRecentConvoy(_ convoy: Convoy) async throws
    func loadRecentConvoys() async throws -> [Convoy]
}
