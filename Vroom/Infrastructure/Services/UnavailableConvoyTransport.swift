import Foundation

enum ConvoyUnavailableError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Convoys are unavailable until the backend transport is implemented."
    }
}

struct UnavailableConvoyTransport: ConvoyTransport {
    func createConvoy(hostProfileID: UUID, settings: ConvoySettings) async throws -> Convoy {
        throw ConvoyUnavailableError.unavailable
    }

    func joinConvoy(code: String, profileID: UUID, displayName: String) async throws -> Convoy {
        throw ConvoyUnavailableError.unavailable
    }

    func leaveConvoy(id: UUID, profileID: UUID) async throws {
        throw ConvoyUnavailableError.unavailable
    }

    func sendHeartbeat(convoyID: UUID, participant: ConvoyParticipant) async throws {
        throw ConvoyUnavailableError.unavailable
    }

    func observeParticipants(convoyID: UUID) -> AsyncStream<[ConvoyParticipant]> {
        AsyncStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }

    func observeSessionState(convoyID: UUID) -> AsyncStream<ConvoyStatus> {
        AsyncStream { continuation in
            continuation.yield(.ended)
            continuation.finish()
        }
    }
}
