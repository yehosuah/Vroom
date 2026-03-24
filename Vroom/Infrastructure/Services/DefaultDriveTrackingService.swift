import Foundation

actor DefaultDriveTrackingService: DriveTrackingService {
    private let locationService: any LocationMonitoringService
    private let motionActivityService: any MotionActivityMonitoringService
    private let deviceMotionService: any DeviceMotionMonitoringService
    private let profileRepository: any ProfileRepository
    private let preferencesRepository: any PreferencesRepository
    private let configurationRepository: any DriveAnalysisConfigurationRepository
    private let driveSessionCoordinator: DriveSessionCoordinator

    private var trackingTask: Task<Void, Never>?
    private var motionTask: Task<Void, Never>?
    private var deviceMotionTask: Task<Void, Never>?
    private var latestMotionActivity: MotionActivitySample?
    private var latestDeviceMotion: DeviceMotionSample?
    private var detector: TripDetector?
    private var isActiveTracking = false
    private var lastAcceptedSampleAt: Date?

    init(
        locationService: any LocationMonitoringService,
        motionActivityService: any MotionActivityMonitoringService,
        deviceMotionService: any DeviceMotionMonitoringService,
        profileRepository: any ProfileRepository,
        preferencesRepository: any PreferencesRepository,
        configurationRepository: any DriveAnalysisConfigurationRepository,
        driveSessionCoordinator: DriveSessionCoordinator
    ) {
        self.locationService = locationService
        self.motionActivityService = motionActivityService
        self.deviceMotionService = deviceMotionService
        self.profileRepository = profileRepository
        self.preferencesRepository = preferencesRepository
        self.configurationRepository = configurationRepository
        self.driveSessionCoordinator = driveSessionCoordinator
    }

    func startMonitoring() async {
        guard trackingTask == nil else { return }
        let configuration = (try? await configurationRepository.loadConfiguration()) ?? .default
        detector = TripDetector(configuration: configuration)
        resetTrackingState()
        try? await driveSessionCoordinator.restoreIfNeeded()
        let hasActiveSession = await driveSessionCoordinator.sessionSnapshot() != nil
        isActiveTracking = hasActiveSession
        startMotionStreams()
        let mode: LocationMonitoringMode = hasActiveSession ? .active(await currentBatteryMode()) : .passive
        startLocationStream(mode: mode)
    }

    func startManualDrive(vehicleID: UUID?) async throws {
        try await driveSessionCoordinator.startManualDrive(vehicleID: vehicleID)
        resetTrackingState()
        isActiveTracking = true
        startLocationStream(mode: .active(await currentBatteryMode()))
    }

    func stopActiveDrive() async throws -> Drive? {
        isActiveTracking = false
        resetTrackingState()
        startLocationStream(mode: .passive)
        return try await driveSessionCoordinator.stopDrive()
    }

    private func startMotionStreams() {
        guard motionTask == nil else { return }
        let activityStream = motionActivityService.activityUpdates()
        motionTask = Task { [weak self] in
            for await activity in activityStream {
                await self?.ingest(activity: activity)
            }
        }
        let deviceStream = deviceMotionService.motionUpdates()
        deviceMotionTask = Task { [weak self] in
            for await motion in deviceStream {
                await self?.ingest(deviceMotion: motion)
            }
        }
    }

    private func startLocationStream(mode: LocationMonitoringMode) {
        trackingTask?.cancel()
        trackingTask = Task { [weak self] in
            guard let self else { return }
            let stream = locationService.locationUpdates(mode: mode)
            for await location in stream {
                await self.ingest(location: location)
            }
        }
    }

    private func ingest(activity: MotionActivitySample) {
        latestMotionActivity = activity
    }

    private func ingest(deviceMotion: DeviceMotionSample) {
        latestDeviceMotion = deviceMotion
    }

    private func ingest(location: LocationSample) async {
        let configuration = (try? await configurationRepository.loadConfiguration()) ?? .default
        let signalQuality: SignalQuality
        switch location.horizontalAccuracyMeters {
        case ..<0:
            signalQuality = .unknown
        case ..<configuration.signalFiltering.degradedHorizontalAccuracyMeters:
            signalQuality = .good
        case ..<configuration.signalFiltering.discardedHorizontalAccuracyMeters:
            signalQuality = .degraded
        default:
            signalQuality = .poor
        }

        let sample = RoutePointSample(
            timestamp: location.timestamp,
            coordinate: location.coordinate,
            altitudeMeters: location.altitudeMeters,
            verticalAccuracy: location.verticalAccuracyMeters,
            horizontalAccuracy: location.horizontalAccuracyMeters,
            speedKPH: location.speedKPH,
            courseDegrees: location.courseDegrees,
            headingAccuracy: location.headingAccuracyDegrees
        )

        if !isActiveTracking {
            var localDetector = detector
            let transition = localDetector?.ingest(sample: sample, motion: latestMotionActivity) ?? .none
            detector = localDetector
            if signalQuality != .poor, transition == .started {
                let profile = try? await profileRepository.loadProfile()
                try? await driveSessionCoordinator.startAutomaticDrive(vehicleID: profile?.defaultVehicleID)
                if await driveSessionCoordinator.sessionSnapshot() != nil {
                    resetTrackingState()
                    isActiveTracking = true
                    startLocationStream(mode: .active(await currentBatteryMode()))
                }
            }
            return
        }

        guard let session = await driveSessionCoordinator.sessionSnapshot() else {
            isActiveTracking = false
            resetTrackingState()
            startLocationStream(mode: .passive)
            return
        }

        if signalQuality != .poor {
            lastAcceptedSampleAt = sample.timestamp
            try? await driveSessionCoordinator.appendTelemetry(sample: sample, motion: latestDeviceMotion, signalQuality: signalQuality)
            if session.recordingMode == .automatic {
                var localDetector = detector
                let transition = localDetector?.ingest(sample: sample, motion: latestMotionActivity) ?? .none
                detector = localDetector
                if transition == .stopped {
                    _ = try? await stopActiveDrive()
                    return
                }
            }
        } else if session.recordingMode == .automatic,
                  let lastAcceptedSampleAt,
                  sample.timestamp.timeIntervalSince(lastAcceptedSampleAt) >= configuration.signalFiltering.stopAfterSignalGap {
            _ = try? await stopActiveDrive()
        }
    }

    private func currentBatteryMode() async -> BatteryMode {
        let preferences = try? await preferencesRepository.loadPreferences()
        return preferences?.batteryMode ?? .balanced
    }

    private func resetTrackingState() {
        detector?.reset()
        lastAcceptedSampleAt = nil
    }
}
