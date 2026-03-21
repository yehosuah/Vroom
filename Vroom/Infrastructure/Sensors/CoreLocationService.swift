import CoreLocation
import Foundation

final class CoreLocationService: NSObject, @unchecked Sendable, LocationMonitoringService {
    private let manager = CLLocationManager()
    private var continuation: AsyncStream<LocationSample>.Continuation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 10
        manager.activityType = .automotiveNavigation
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = true
        manager.showsBackgroundLocationIndicator = true
    }

    func authorizationState() async -> LocationAuthorizationStatus {
        switch manager.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .authorizedWhenInUse: return .whenInUse
        case .authorizedAlways: return .always
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }

    func requestWhenInUseAuthorization() async {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() async {
        manager.requestAlwaysAuthorization()
    }

    func locationUpdates(mode: LocationMonitoringMode) -> AsyncStream<LocationSample> {
        AsyncStream { continuation in
            self.continuation = continuation
            switch mode {
            case .passive:
                manager.stopUpdatingLocation()
                manager.distanceFilter = kCLDistanceFilterNone
                manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
                manager.startMonitoringSignificantLocationChanges()
            case .active(let batteryMode):
                manager.stopMonitoringSignificantLocationChanges()
                configureActiveMode(for: batteryMode)
                manager.startUpdatingLocation()
            }
        }
    }

    func stopUpdates() {
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
        continuation?.finish()
        continuation = nil
    }

    private func configureActiveMode(for batteryMode: BatteryMode) {
        manager.activityType = .automotiveNavigation
        switch batteryMode {
        case .performance:
            manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            manager.distanceFilter = 5
            manager.pausesLocationUpdatesAutomatically = false
        case .balanced:
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            manager.distanceFilter = 10
            manager.pausesLocationUpdatesAutomatically = true
        case .lowPower:
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            manager.distanceFilter = 25
            manager.pausesLocationUpdatesAutomatically = true
        }
    }
}

extension CoreLocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            continuation?.yield(
                LocationSample(
                    timestamp: location.timestamp,
                    coordinate: GeoCoordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
                    horizontalAccuracyMeters: location.horizontalAccuracy,
                    verticalAccuracyMeters: location.verticalAccuracy,
                    altitudeMeters: location.altitude,
                    speedKPH: max(location.speed, 0) * 3.6,
                    courseDegrees: location.course,
                    headingAccuracyDegrees: location.courseAccuracy
                )
            )
        }
    }
}
