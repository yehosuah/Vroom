import Foundation

protocol MotionActivityMonitoringService: Sendable {
    func authorizationState() async -> MotionAuthorizationStatus
    func requestAuthorization() async
    func activityUpdates() -> AsyncStream<MotionActivitySample>
    func stopUpdates()
}
