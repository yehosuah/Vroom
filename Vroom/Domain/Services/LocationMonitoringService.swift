import Foundation

enum LocationMonitoringMode: Sendable {
    case passive
    case active(BatteryMode)
}

protocol LocationMonitoringService: Sendable {
    func authorizationState() async -> LocationAuthorizationStatus
    func requestWhenInUseAuthorization() async
    func requestAlwaysAuthorization() async
    func locationUpdates(mode: LocationMonitoringMode) -> AsyncStream<LocationSample>
    func stopUpdates()
}
