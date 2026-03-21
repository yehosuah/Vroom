import Foundation

protocol ConvoyTransport: Sendable {
    func createConvoy(hostProfileID: UUID, settings: ConvoySettings) async throws -> Convoy
    func joinConvoy(code: String, profileID: UUID, displayName: String) async throws -> Convoy
    func leaveConvoy(id: UUID, profileID: UUID) async throws
    func sendHeartbeat(convoyID: UUID, participant: ConvoyParticipant) async throws
    func observeParticipants(convoyID: UUID) -> AsyncStream<[ConvoyParticipant]>
    func observeSessionState(convoyID: UUID) -> AsyncStream<ConvoyStatus>
}
