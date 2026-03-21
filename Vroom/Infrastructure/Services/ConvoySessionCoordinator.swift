import Foundation

actor ConvoySessionCoordinator {
    private let transport: ConvoyTransport
    private let cacheRepository: ConvoyCacheRepository
    private let identityService: IdentityService

    init(transport: ConvoyTransport, cacheRepository: ConvoyCacheRepository, identityService: IdentityService) {
        self.transport = transport
        self.cacheRepository = cacheRepository
        self.identityService = identityService
    }

    func createConvoy(settings: ConvoySettings) async throws -> Convoy {
        let profileID = try await identityService.currentProfileID() ?? UUID()
        let convoy = try await transport.createConvoy(hostProfileID: profileID, settings: settings)
        try await cacheRepository.saveRecentConvoy(convoy)
        return convoy
    }

    func joinConvoy(code: String, displayName: String) async throws -> Convoy {
        let profileID = try await identityService.currentProfileID() ?? UUID()
        let convoy = try await transport.joinConvoy(code: code, profileID: profileID, displayName: displayName)
        try await cacheRepository.saveRecentConvoy(convoy)
        return convoy
    }

    func leaveConvoy(id: UUID) async throws {
        let profileID = try await identityService.currentProfileID() ?? UUID()
        try await transport.leaveConvoy(id: id, profileID: profileID)
    }

    func participantStream(for convoyID: UUID) -> AsyncStream<[ConvoyParticipant]> {
        transport.observeParticipants(convoyID: convoyID)
    }

    func stateStream(for convoyID: UUID) -> AsyncStream<ConvoyStatus> {
        transport.observeSessionState(convoyID: convoyID)
    }
}
