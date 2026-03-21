import CoreMotion
import Foundation

final class CoreMotionActivityService: @unchecked Sendable, MotionActivityMonitoringService {
    private let manager = CMMotionActivityManager()
    private let queue = OperationQueue()
    private var continuation: AsyncStream<MotionActivitySample>.Continuation?

    func authorizationState() async -> MotionAuthorizationStatus {
        switch CMMotionActivityManager.authorizationStatus() {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }

    func requestAuthorization() async {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        manager.startActivityUpdates(to: queue) { _ in }
        manager.stopActivityUpdates()
    }

    func activityUpdates() -> AsyncStream<MotionActivitySample> {
        AsyncStream { continuation in
            self.continuation = continuation
            guard CMMotionActivityManager.isActivityAvailable() else {
                continuation.finish()
                return
            }
            manager.startActivityUpdates(to: queue) { activity in
                guard let activity else { return }
                let confidence: Double
                switch activity.confidence {
                case .low: confidence = 0.3
                case .medium: confidence = 0.6
                case .high: confidence = 0.9
                @unknown default: confidence = 0.5
                }
                continuation.yield(MotionActivitySample(timestamp: Date(), isAutomotive: activity.automotive, confidence: confidence))
            }
        }
    }

    func stopUpdates() {
        manager.stopActivityUpdates()
        continuation?.finish()
        continuation = nil
    }
}
