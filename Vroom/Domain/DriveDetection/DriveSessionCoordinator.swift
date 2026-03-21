import Foundation

actor DriveSessionCoordinator {
    private let clock: any AppClock
    private let uuidGenerator: any UUIDGenerating
    private let routeTraceRepository: any RouteTraceRepository
    private let driveRepository: any DriveRepository
    private let eventRepository: any DrivingEventRepository
    private let trapRepository: any TrapRepository
    private let zoneRepository: any ZoneRepository
    private let configurationRepository: any DriveAnalysisConfigurationRepository
    private let notificationService: any NotificationSchedulingService
    private let mapRenderingService: any MapRenderingService
    private let activeSessionRepository: any ActiveDriveSessionRepository

    private var sessionContinuations: [AsyncStream<DriveSession?>.Continuation] = []
    private var completedDriveContinuations: [AsyncStream<Drive>.Continuation] = []
    private var currentSession: DriveSession?
    private var currentWriterHandle: RouteTraceWriterHandle?
    private var routeRecorder: RouteRecorder?
    private var bufferedSamples: [RoutePointSample] = []
    private var eventDetector: DrivingEventDetector?
    private var detectedEvents: [DrivingEvent] = []

    init(
        clock: any AppClock,
        uuidGenerator: any UUIDGenerating,
        routeTraceRepository: any RouteTraceRepository,
        driveRepository: any DriveRepository,
        eventRepository: any DrivingEventRepository,
        trapRepository: any TrapRepository,
        zoneRepository: any ZoneRepository,
        configurationRepository: any DriveAnalysisConfigurationRepository,
        notificationService: any NotificationSchedulingService,
        mapRenderingService: any MapRenderingService,
        activeSessionRepository: any ActiveDriveSessionRepository
    ) {
        self.clock = clock
        self.uuidGenerator = uuidGenerator
        self.routeTraceRepository = routeTraceRepository
        self.driveRepository = driveRepository
        self.eventRepository = eventRepository
        self.trapRepository = trapRepository
        self.zoneRepository = zoneRepository
        self.configurationRepository = configurationRepository
        self.notificationService = notificationService
        self.mapRenderingService = mapRenderingService
        self.activeSessionRepository = activeSessionRepository
    }

    func sessionStream() -> AsyncStream<DriveSession?> {
        AsyncStream { continuation in
            sessionContinuations.append(continuation)
            continuation.yield(currentSession)
        }
    }

    func completedDriveStream() -> AsyncStream<Drive> {
        AsyncStream { continuation in
            completedDriveContinuations.append(continuation)
        }
    }

    func sessionSnapshot() -> DriveSession? {
        currentSession
    }

    func restoreIfNeeded() async throws {
        guard currentSession == nil, let checkpoint = try await activeSessionRepository.loadCheckpoint() else { return }
        try await startDrive(vehicleID: checkpoint.vehicleID, mode: checkpoint.recordingMode, driveID: checkpoint.driveID, startedAt: checkpoint.startedAt)
    }

    func startManualDrive(vehicleID: UUID?) async throws {
        try await startDrive(vehicleID: vehicleID, mode: .manual, driveID: uuidGenerator(), startedAt: clock.now)
    }

    func startAutomaticDrive(vehicleID: UUID?) async throws {
        try await startDrive(vehicleID: vehicleID, mode: .automatic, driveID: uuidGenerator(), startedAt: clock.now)
    }

    private func startDrive(vehicleID: UUID?, mode: DriveRecordingMode, driveID: UUID, startedAt: Date) async throws {
        guard currentSession == nil else { return }
        let configuration = try await configurationRepository.loadConfiguration()
        currentWriterHandle = try await routeTraceRepository.openWriter(for: driveID)
        routeRecorder = RouteRecorder(policy: configuration.samplingPolicy)
        eventDetector = DrivingEventDetector(configuration: configuration)
        detectedEvents = []
        bufferedSamples = try await routeTraceRepository.loadTrace(for: driveID)
        currentSession = DriveSession(
            sessionID: driveID,
            state: .active,
            startedAt: startedAt,
            activeVehicleID: vehicleID,
            liveMetrics: .zero
        )
        try await activeSessionRepository.saveCheckpoint(
            ActiveDriveSessionCheckpoint(
                driveID: driveID,
                startedAt: startedAt,
                vehicleID: vehicleID,
                recordingMode: mode
            )
        )
        broadcastSession()
    }

    func appendTelemetry(sample: RoutePointSample, motion: DeviceMotionSample?, signalQuality: SignalQuality) async throws {
        guard let handle = currentWriterHandle, var session = currentSession, var recorder = routeRecorder else { return }
        let kept = recorder.append(sample)
        routeRecorder = recorder
        if kept {
            bufferedSamples.append(sample)
            try await routeTraceRepository.append(sample: sample, to: handle)
            if var eventDetector {
                let events = eventDetector.ingest(driveID: session.sessionID, sample: sample, motion: motion)
                self.eventDetector = eventDetector
                if !events.isEmpty {
                    detectedEvents.append(contentsOf: events)
                    try await eventRepository.saveEvents(events)
                }
            }
        }

        let recordedSamples = recorder.samples.isEmpty ? bufferedSamples : recorder.samples
        let stats = DriveStatsCalculator().calculate(samples: recordedSamples, startedAt: session.startedAt, endedAt: sample.timestamp)
        session.liveMetrics = DriveLiveMetrics(
            currentSpeedKPH: sample.speedKPH,
            distanceMeters: stats.distanceMeters,
            duration: stats.duration,
            topSpeedKPH: stats.topSpeedKPH,
            sampleCount: bufferedSamples.count,
            signalQuality: signalQuality
        )
        currentSession = session
        broadcastSession()
    }

    func stopDrive(profile: ScoringProfile = .casual) async throws -> Drive? {
        guard var session = currentSession, let handle = currentWriterHandle else { return nil }
        session.state = .finalizing
        currentSession = session
        broadcastSession()

        let trace = try await routeTraceRepository.finalize(handle: handle)
        let configuration = try await configurationRepository.loadConfiguration()
        let trapExtractor = TrapExtractor(configuration: configuration)
        let scoringEngine = DriveScoringEngine(configuration: configuration)
        let zoneMatcher = ZoneMatcher()

        let samples = try await routeTraceRepository.loadTrace(for: session.sessionID)
        let endedAt = samples.last?.timestamp ?? clock.now
        let stats = DriveStatsCalculator().calculate(samples: samples, startedAt: session.startedAt, endedAt: endedAt)
        let traps = trapExtractor.extract(driveID: session.sessionID, samples: samples)
        let zones = try await zoneRepository.listZones(vehicleID: session.activeVehicleID)
        let zoneRuns = zoneMatcher.match(driveID: session.sessionID, vehicleID: session.activeVehicleID, samples: samples, zones: zones)
        let score = scoringEngine.score(events: detectedEvents, profile: profile)
        let summary = await mapRenderingService.summary(for: samples, events: detectedEvents)

        let drive = Drive(
            id: session.sessionID,
            vehicleID: session.activeVehicleID,
            startedAt: session.startedAt,
            endedAt: endedAt,
            distanceMeters: stats.distanceMeters,
            duration: stats.duration,
            avgSpeedKPH: stats.averageSpeedKPH,
            topSpeedKPH: stats.topSpeedKPH,
            favorite: false,
            scoreSummary: score,
            traceRef: trace.storageRef,
            summary: summary
        )

        try await driveRepository.saveDrive(drive)
        try await trapRepository.saveTrapCandidates(traps)
        for run in zoneRuns {
            try await zoneRepository.recordRun(run)
        }
        try? await notificationService.scheduleDriveSummary(for: drive)
        try? await activeSessionRepository.clearCheckpoint()

        currentSession = nil
        currentWriterHandle = nil
        routeRecorder = nil
        bufferedSamples = []
        detectedEvents = []
        eventDetector = nil
        broadcastSession()
        broadcastCompletedDrive(drive)
        return drive
    }

    private func broadcastSession() {
        for continuation in sessionContinuations {
            continuation.yield(currentSession)
        }
    }

    private func broadcastCompletedDrive(_ drive: Drive) {
        for continuation in completedDriveContinuations {
            continuation.yield(drive)
        }
    }
}
