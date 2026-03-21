import Foundation

struct NoopVoiceChatService: VoiceChatService {
    let isAvailable: Bool

    init(isAvailable: Bool = false) {
        self.isAvailable = isAvailable
    }

    func startSession(convoyID: UUID) async throws {
    }

    func endSession() async {
    }
}
