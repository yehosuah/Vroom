import Foundation

protocol VoiceChatService: Sendable {
    var isAvailable: Bool { get }
    func startSession(convoyID: UUID) async throws
    func endSession() async
}
