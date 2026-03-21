import CoreMotion
import Foundation

final class CoreDeviceMotionService: @unchecked Sendable, DeviceMotionMonitoringService {
    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    private var continuation: AsyncStream<DeviceMotionSample>.Continuation?

    func motionUpdates() -> AsyncStream<DeviceMotionSample> {
        AsyncStream { continuation in
            self.continuation = continuation
            guard manager.isDeviceMotionAvailable else {
                continuation.finish()
                return
            }
            manager.deviceMotionUpdateInterval = 0.2
            manager.startDeviceMotionUpdates(to: queue) { motion, _ in
                guard let motion else { return }
                continuation.yield(
                    DeviceMotionSample(
                        timestamp: Date(),
                        lateralG: motion.userAcceleration.x,
                        longitudinalG: motion.userAcceleration.y
                    )
                )
            }
        }
    }

    func stopUpdates() {
        manager.stopDeviceMotionUpdates()
        continuation?.finish()
        continuation = nil
    }
}
