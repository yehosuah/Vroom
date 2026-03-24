import Foundation
import Testing

@testable import Vroom

struct DefaultDriveTrackingServiceTests {
    @Test func manualDriveIgnoresAutomaticStopHeuristics() async throws {
        let harness = DriveTrackingHarness()

        await harness.service.startMonitoring()
        await harness.waitForMonitoring()

        try await harness.service.startManualDrive(vehicleID: nil)
        await harness.locationService.waitForModeCount(2)

        let baseTime = Date(timeIntervalSince1970: 1_710_000_000)
        for offset in 0..<6 {
            harness.locationService.yield(
                Self.sample(
                    at: baseTime.addingTimeInterval(Double(offset * 30)),
                    speed: 0,
                    horizontalAccuracy: 5
                )
            )
            await harness.flush()
        }

        let session = await harness.container.driveSessionCoordinator.sessionSnapshot()
        #expect(session?.recordingMode == .manual)
        #expect(session?.state == .active)

        _ = try await harness.service.stopActiveDrive()
    }

    @Test func automaticDriveClearsStaleSignalGapWhenSessionStarts() async throws {
        let harness = DriveTrackingHarness()

        await harness.service.startMonitoring()
        await harness.waitForMonitoring()

        try await harness.service.startManualDrive(vehicleID: nil)
        await harness.locationService.waitForModeCount(2)

        let baseTime = Date(timeIntervalSince1970: 1_710_100_000)
        harness.locationService.yield(Self.sample(at: baseTime, speed: 28, horizontalAccuracy: 5))
        await harness.flush()

        _ = try await harness.service.stopActiveDrive()
        await harness.locationService.waitForModeCount(3)

        harness.motionActivityService.yield(
            MotionActivitySample(
                timestamp: baseTime.addingTimeInterval(400),
                isAutomotive: true,
                confidence: 0.9
            )
        )
        await harness.flush()

        for second in 400...402 {
            harness.locationService.yield(
                Self.sample(
                    at: baseTime.addingTimeInterval(Double(second)),
                    speed: 24,
                    horizontalAccuracy: 5
                )
            )
            await harness.flush()
        }

        await harness.locationService.waitForModeCount(4)
        let automaticSession = await harness.container.driveSessionCoordinator.sessionSnapshot()
        #expect(automaticSession?.recordingMode == .automatic)

        harness.locationService.yield(
            Self.sample(
                at: baseTime.addingTimeInterval(403),
                speed: 0,
                horizontalAccuracy: 120
            )
        )
        await harness.flush()

        #expect(await harness.container.driveSessionCoordinator.sessionSnapshot() != nil)
    }

    @Test func automaticDriveStopsAfterFullStationaryWindow() async throws {
        let harness = DriveTrackingHarness()

        await harness.service.startMonitoring()
        await harness.waitForMonitoring()

        let baseTime = Date(timeIntervalSince1970: 1_710_200_000)
        harness.motionActivityService.yield(
            MotionActivitySample(
                timestamp: baseTime,
                isAutomotive: true,
                confidence: 0.9
            )
        )
        await harness.flush()

        for offset in 0..<3 {
            harness.locationService.yield(
                Self.sample(
                    at: baseTime.addingTimeInterval(Double(offset)),
                    speed: 24,
                    horizontalAccuracy: 5
                )
            )
            await harness.flush()
        }

        await harness.locationService.waitForModeCount(2)
        #expect(await harness.container.driveSessionCoordinator.sessionSnapshot()?.recordingMode == .automatic)

        let stationaryOffsets = [10, 40, 70, 100, 130, 160]
        for (index, offset) in stationaryOffsets.enumerated() {
            harness.locationService.yield(
                Self.sample(
                    at: baseTime.addingTimeInterval(Double(offset)),
                    speed: 0,
                    horizontalAccuracy: 5
                )
            )
            await harness.flush()

            if index < stationaryOffsets.count - 1 {
                #expect(await harness.container.driveSessionCoordinator.sessionSnapshot() != nil)
            }
        }

        #expect(await harness.container.driveSessionCoordinator.sessionSnapshot() == nil)

        let savedDrives = try await harness.container.driveRepository.fetchHistory(vehicleID: nil, query: nil)
        #expect(savedDrives.count == 1)
    }

    private static func sample(at timestamp: Date, speed: Double, horizontalAccuracy: Double) -> LocationSample {
        LocationSample(
            timestamp: timestamp,
            coordinate: GeoCoordinate(latitude: 34.0, longitude: -118.0),
            horizontalAccuracyMeters: horizontalAccuracy,
            verticalAccuracyMeters: 8,
            altitudeMeters: 120,
            speedKPH: speed,
            courseDegrees: 0,
            headingAccuracyDegrees: 5
        )
    }
}

private struct DriveTrackingHarness {
    let container: AppContainer
    let locationService: FakeLocationService
    let motionActivityService: FakeMotionActivityService
    let deviceMotionService: FakeDeviceMotionService
    let service: DefaultDriveTrackingService

    init() {
        let container = AppContainer.live(inMemory: true)
        let locationService = FakeLocationService()
        let motionActivityService = FakeMotionActivityService()
        let deviceMotionService = FakeDeviceMotionService()

        self.container = container
        self.locationService = locationService
        self.motionActivityService = motionActivityService
        self.deviceMotionService = deviceMotionService
        self.service = DefaultDriveTrackingService(
            locationService: locationService,
            motionActivityService: motionActivityService,
            deviceMotionService: deviceMotionService,
            profileRepository: container.profileRepository,
            preferencesRepository: container.preferencesRepository,
            configurationRepository: container.configurationRepository,
            driveSessionCoordinator: container.driveSessionCoordinator
        )
    }

    func waitForMonitoring() async {
        await locationService.waitForModeCount(1)
        await motionActivityService.waitForSubscriber()
        await deviceMotionService.waitForSubscriber()
    }

    func flush() async {
        for _ in 0..<6 {
            await Task.yield()
        }
        try? await Task.sleep(for: .milliseconds(10))
    }
}

private final class FakeLocationService: @unchecked Sendable, LocationMonitoringService {
    private let queue = DispatchQueue(label: "FakeLocationService")
    private var continuation: AsyncStream<LocationSample>.Continuation?
    private var requestedModeCount = 0
    private var readyModeCount = 0

    func authorizationState() async -> LocationAuthorizationStatus { .always }

    func requestWhenInUseAuthorization() async {}

    func requestAlwaysAuthorization() async {}

    func locationUpdates(mode: LocationMonitoringMode) -> AsyncStream<LocationSample> {
        let modeCount = queue.sync {
            requestedModeCount += 1
            return requestedModeCount
        }

        return AsyncStream { continuation in
            self.queue.sync {
                self.continuation = continuation
                self.readyModeCount = modeCount
            }
        }
    }

    func stopUpdates() {
        queue.sync {
            continuation?.finish()
            continuation = nil
        }
    }

    func yield(_ sample: LocationSample) {
        let continuation = queue.sync { self.continuation }
        continuation?.yield(sample)
    }

    func waitForModeCount(_ count: Int) async {
        while true {
            let currentCount = queue.sync { readyModeCount }

            if currentCount >= count {
                return
            }

            await Task.yield()
        }
    }
}

private final class FakeMotionActivityService: @unchecked Sendable, MotionActivityMonitoringService {
    private let queue = DispatchQueue(label: "FakeMotionActivityService")
    private var continuation: AsyncStream<MotionActivitySample>.Continuation?

    func authorizationState() async -> MotionAuthorizationStatus { .authorized }

    func requestAuthorization() async {}

    func activityUpdates() -> AsyncStream<MotionActivitySample> {
        AsyncStream { continuation in
            self.queue.sync {
                self.continuation = continuation
            }
        }
    }

    func stopUpdates() {
        queue.sync {
            continuation?.finish()
            continuation = nil
        }
    }

    func yield(_ sample: MotionActivitySample) {
        let continuation = queue.sync { self.continuation }
        continuation?.yield(sample)
    }

    func waitForSubscriber() async {
        while true {
            let hasContinuation = queue.sync { continuation != nil }

            if hasContinuation {
                return
            }

            await Task.yield()
        }
    }
}

private final class FakeDeviceMotionService: @unchecked Sendable, DeviceMotionMonitoringService {
    private let queue = DispatchQueue(label: "FakeDeviceMotionService")
    private var continuation: AsyncStream<DeviceMotionSample>.Continuation?

    func motionUpdates() -> AsyncStream<DeviceMotionSample> {
        AsyncStream { continuation in
            self.queue.sync {
                self.continuation = continuation
            }
        }
    }

    func stopUpdates() {
        queue.sync {
            continuation?.finish()
            continuation = nil
        }
    }

    func waitForSubscriber() async {
        while true {
            let hasContinuation = queue.sync { continuation != nil }

            if hasContinuation {
                return
            }

            await Task.yield()
        }
    }
}
