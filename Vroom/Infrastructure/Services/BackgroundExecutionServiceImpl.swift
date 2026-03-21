import Foundation

struct BackgroundExecutionServiceImpl: BackgroundExecutionService {
    func beginTrackingSession(name: String) async -> UUID {
        UUID()
    }

    func endTrackingSession(id: UUID) async {
    }
}
