import Foundation

protocol DeviceMotionMonitoringService: Sendable {
    func motionUpdates() -> AsyncStream<DeviceMotionSample>
    func stopUpdates()
}
