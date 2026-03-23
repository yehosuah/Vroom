import Combine
import Foundation
import SwiftData
import SwiftUI

struct VehicleEditorDraft: Sendable {
    var nickname: String = ""
    var make: String = ""
    var model: String = ""
    var year: Int = Calendar.current.component(.year, from: Date())
    var isPrimary: Bool = false

    init() {}

    init(vehicle: Vehicle) {
        nickname = vehicle.nickname
        make = vehicle.make
        model = vehicle.model
        year = vehicle.year
        isPrimary = vehicle.isPrimary
    }
}

struct AppBanner: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String?
    let tone: RoadBannerTone
}

@MainActor
final class AppStateStore: ObservableObject {
    @Published var isBootstrapping = true
    @Published var profile: UserProfile?
    @Published var preferences: AppPreferences = .default
    @Published var permissionState: PermissionState = .empty
    @Published var vehicles: [Vehicle] = []
    @Published var drives: [Drive] = []
    @Published var activeDriveSession: DriveSession?
    @Published var latestCompletedDrive: Drive?
    @Published var presentedCompletedDrive: Drive?
    @Published var weeklySnapshot = InsightSnapshot(period: .week, distanceTotal: 0, durationAverage: 0, topSpeedTrend: 0, eventFrequency: 0, scoreTrend: 0, patternSummary: "Complete a drive to start weekly insights.")
    @Published var monthlySnapshot = InsightSnapshot(period: .month, distanceTotal: 0, durationAverage: 0, topSpeedTrend: 0, eventFrequency: 0, scoreTrend: 0, patternSummary: "Complete a drive to start monthly insights.")
    @Published var traps: [SpeedTrap] = []
    @Published var zones: [SpeedZone] = []
    @Published var recentConvoys: [Convoy] = []
    @Published var currentConvoy: Convoy?
    @Published var convoyParticipants: [ConvoyParticipant] = []
    @Published var convoyStatus: ConvoyStatus = .ended
    @Published var subscriptionSnapshot: SubscriptionSnapshot = .free
    @Published var storeProducts: [StoreProductSnapshot] = []
    @Published var exportedDataURL: URL?
    @Published var currentBanner: AppBanner?
    @Published var currentAlertMessage: String?
    @Published var selectedVehicleFilter: UUID?
    @Published private var routeAssetCache = DriveRouteAssetCache()

    private let container: AppContainer
    private var sessionObservationTask: Task<Void, Never>?
    private var completionObservationTask: Task<Void, Never>?
    private var driveEventsByID: [UUID: [DrivingEvent]] = [:]
    private var zoneRunsByID: [UUID: [SpeedZoneRun]] = [:]
    private var hasBootstrappedOnce = false
    private var routeLoadTasks: [UUID: Task<[RoutePointSample], Never>] = [:]
    private var routePreviewTasks: [DriveRoutePreviewKey: Task<Data?, Never>] = [:]

    init(container: AppContainer) {
        self.container = container
    }

    var requiresOnboarding: Bool {
        profile?.onboardingState != .completed
    }

    func bootstrap() async {
        guard !hasBootstrappedOnce else {
            isBootstrapping = false
            return
        }
        hasBootstrappedOnce = true
        await seedPreviewDataIfNeeded()
        await observeDriveCoordinator()
        await refreshPermissions()
        await refreshStoreProducts()
        await refreshData()
        await container.driveTrackingService.startMonitoring()
        isBootstrapping = false
    }

    func refreshData() async {
        let previousMapStyle = preferences.mapStyle
        do {
            profile = try await container.profileRepository.loadProfile()
            preferences = try await container.preferencesRepository.loadPreferences()
            vehicles = try await container.vehicleRepository.listVehicles()
            drives = try await container.driveRepository.fetchHistory(vehicleID: selectedVehicleFilter, query: nil)
            subscriptionSnapshot = try await container.subscriptionRepository.loadSnapshot()
            traps = try await container.trapRepository.listTraps(vehicleID: selectedVehicleFilter)
            zones = try await container.zoneRepository.listZones(vehicleID: selectedVehicleFilter)
            recentConvoys = try await container.convoyCacheRepository.loadRecentConvoys()
            weeklySnapshot = try await container.insightsRepository.snapshot(period: .week, vehicleID: selectedVehicleFilter)
            monthlySnapshot = try await container.insightsRepository.snapshot(period: .month, vehicleID: selectedVehicleFilter)
            latestCompletedDrive = drives.first
            driveEventsByID = [:]
            for drive in drives {
                driveEventsByID[drive.id] = try await container.drivingEventRepository.eventsForDrive(id: drive.id)
            }
            zoneRunsByID = [:]
            for zone in zones {
                zoneRunsByID[zone.id] = try await container.zoneRepository.runsForZone(id: zone.id)
            }
            if previousMapStyle != preferences.mapStyle {
                routeAssetCache.invalidatePreviews()
            }
            pruneRouteAssets()
        } catch {
            currentAlertMessage = error.localizedDescription
        }
    }

    func refreshStoreProducts() async {
        do {
            storeProducts = try await container.storefrontService.fetchProducts()
        } catch {
            currentAlertMessage = error.localizedDescription
        }
    }

    func refreshPermissions() async {
        let location = await container.locationService.authorizationState()
        let motion = await container.motionActivityService.authorizationState()
        let notifications = await container.notificationService.authorizationState()
        permissionState = PermissionState(location: location, motion: motion, notifications: notifications)
    }

    func requestLocationPermissions() async {
        await container.locationService.requestWhenInUseAuthorization()
        await container.locationService.requestAlwaysAuthorization()
        await refreshPermissions()
    }

    func requestMotionPermissions() async {
        await container.motionActivityService.requestAuthorization()
        await refreshPermissions()
    }

    func requestNotificationPermissions() async {
        _ = await container.notificationService.requestAuthorization()
        await refreshPermissions()
    }

    func completeOnboarding(displayName: String, avatarStyle: AvatarStyle, units: UnitSystem, vehicleDraft: VehicleEditorDraft?) async {
        do {
            let vehicleID = vehicleDraft?.nickname.isEmpty == false ? UUID() : nil
            let profile = UserProfile(
                id: UUID(),
                displayName: displayName.isEmpty ? "Vroom Driver" : displayName,
                avatarStyle: avatarStyle,
                createdAt: Date(),
                defaultVehicleID: vehicleID,
                onboardingState: .completed
            )
            try await container.profileRepository.saveProfile(profile)
            try await container.preferencesRepository.savePreferences(
                AppPreferences(
                    units: units,
                    mapStyle: preferences.mapStyle,
                    replayAutoplay: preferences.replayAutoplay,
                    batteryMode: preferences.batteryMode,
                    privacyOptions: preferences.privacyOptions
                )
            )
            if let vehicleDraft, let vehicleID, !vehicleDraft.nickname.isEmpty {
                let vehicle = Vehicle(id: vehicleID, nickname: vehicleDraft.nickname, make: vehicleDraft.make, model: vehicleDraft.model, year: vehicleDraft.year, isPrimary: true, archivedAt: nil)
                try await container.vehicleRepository.saveVehicle(vehicle)
            }
            await refreshData()
            showBanner(title: "Setup complete", message: "Your drives will appear here after the first route is saved.", tone: .success)
        } catch {
            currentAlertMessage = error.localizedDescription
        }
    }

    func saveVehicle(draft: VehicleEditorDraft, editing vehicle: Vehicle? = nil) async {
        do {
            let savedVehicle = Vehicle(
                id: vehicle?.id ?? UUID(),
                nickname: draft.nickname,
                make: draft.make,
                model: draft.model,
                year: draft.year,
                isPrimary: draft.isPrimary || vehicles.isEmpty,
                archivedAt: vehicle?.archivedAt
            )
            try await container.vehicleRepository.saveVehicle(savedVehicle)
            if var profile {
                if profile.defaultVehicleID == nil || savedVehicle.isPrimary {
                    profile.defaultVehicleID = savedVehicle.id
                    try await container.profileRepository.saveProfile(profile)
                }
            }
            await refreshData()
            showBanner(title: vehicle == nil ? "Vehicle added" : "Vehicle saved", message: savedVehicle.nickname, tone: .success)
        } catch {
            currentAlertMessage = error.localizedDescription
        }
    }

    func archiveVehicle(_ vehicle: Vehicle) async {
        do {
            try await container.vehicleRepository.archiveVehicle(id: vehicle.id)
            await refreshData()
            showBanner(title: "Vehicle archived", message: "\(vehicle.nickname) was removed from the active garage.", tone: .warning)
        } catch {
            currentAlertMessage = error.localizedDescription
        }
    }

    func startDrive() async {
        do {
            let vehicleID = selectedVehicleFilter ?? profile?.defaultVehicleID ?? vehicles.first?.id
            try await container.driveTrackingService.startManualDrive(vehicleID: vehicleID)
            showBanner(title: "Drive started", message: "Vroom is tracking this route now.", tone: .info)
        } catch {
            currentAlertMessage = error.localizedDescription
        }
    }

    func stopDrive() async {
        do {
            latestCompletedDrive = try await container.driveTrackingService.stopActiveDrive()
            presentedCompletedDrive = latestCompletedDrive
            await refreshData()
        } catch {
            currentAlertMessage = error.localizedDescription
        }
    }

    func toggleFavorite(for drive: Drive) async {
        do {
            try await container.driveRepository.setFavorite(driveID: drive.id, isFavorite: !drive.favorite)
            await refreshData()
            showBanner(
                title: drive.favorite ? "Removed from saved drives" : "Saved drive",
                message: drive.summary.title,
                tone: .success
            )
        } catch {
            currentAlertMessage = error.localizedDescription
        }
    }

    func assignVehicle(_ vehicleID: UUID?, to drive: Drive) async {
        do {
            try await container.driveRepository.assignVehicle(driveID: drive.id, vehicleID: vehicleID)
            await refreshData()
        } catch {
            currentAlertMessage = error.localizedDescription
        }
    }

    func setVehicleFilter(_ vehicleID: UUID?) async {
        selectedVehicleFilter = vehicleID
        await refreshData()
    }

    func events(for driveID: UUID) -> [DrivingEvent] {
        driveEventsByID[driveID] ?? []
    }

    func zoneRuns(for zoneID: UUID) -> [SpeedZoneRun] {
        zoneRunsByID[zoneID] ?? []
    }

    func personalBest(for zoneID: UUID) -> SpeedZoneRun? {
        zoneRunsByID[zoneID]?.min(by: { $0.elapsed < $1.elapsed })
    }

    func loadTrace(for driveID: UUID) async -> [RoutePointSample] {
        await ensureRouteAssets(for: driveID)
        return routeAssetCache.loadState(for: driveID).trace ?? []
    }

    func routeLoadState(for driveID: UUID) -> DriveRouteLoadState {
        routeAssetCache.loadState(for: driveID)
    }

    func routePreviewState(for driveID: UUID, size: CGSize, style: AppMapStyle? = nil) -> DriveRoutePreviewState {
        let key = DriveRoutePreviewKey(driveID: driveID, mapStyle: style ?? preferences.mapStyle, size: size)
        return routeAssetCache.previewState(for: key)
    }

    func ensureRouteAssets(
        for driveID: UUID,
        includePreview: Bool = false,
        previewSize: CGSize = .zero,
        forceReload: Bool = false,
        mapStyle: AppMapStyle? = nil
    ) async {
        let trace = await resolveRouteTrace(for: driveID, forceReload: forceReload)
        guard includePreview else { return }

        let key = DriveRoutePreviewKey(driveID: driveID, mapStyle: mapStyle ?? preferences.mapStyle, size: previewSize)
        guard previewSize.width > 0, previewSize.height > 0 else { return }
        await resolveRoutePreview(for: key, trace: trace)
    }

    func sharePayload(for drive: Drive) async -> SharePayload {
        let trace = await loadTrace(for: drive.id)
        let events = self.events(for: drive.id)
        return await container.shareCardRenderingService.renderPayload(for: drive, trace: trace, events: events)
    }

    func vehicle(for id: UUID?) -> Vehicle? {
        guard let id else { return nil }
        return vehicles.first { $0.id == id }
    }

    var primaryVehicle: Vehicle? {
        vehicles.first(where: \.isPrimary) ?? vehicles.first
    }

    func purchasePremium(productID: String) async {
        do {
            subscriptionSnapshot = try await container.storefrontService.purchase(productID: productID)
            await refreshStoreProducts()
            if subscriptionSnapshot.tier == .premium {
                showBanner(title: "Premium unlocked", message: "More insight is now available after each drive.", tone: .success)
            }
        } catch {
            currentAlertMessage = error.localizedDescription
        }
    }

    func updatePreferences(_ updated: AppPreferences) async {
        let previousStyle = preferences.mapStyle
        do {
            try await container.preferencesRepository.savePreferences(updated)
            preferences = updated
            if previousStyle != updated.mapStyle {
                routeAssetCache.invalidatePreviews()
            }
            await refreshData()
            await container.driveTrackingService.startMonitoring()
        } catch {
            currentAlertMessage = error.localizedDescription
        }
    }

    func restorePremium() async {
        do {
            subscriptionSnapshot = try await container.storefrontService.restorePurchases()
            if subscriptionSnapshot.tier == .premium {
                showBanner(title: "Purchases restored", message: "Premium is active on this device.", tone: .success)
            } else {
                showBanner(title: "No purchases found", message: "This Apple ID does not have an active Vroom Premium plan.", tone: .info)
            }
        } catch {
            currentAlertMessage = error.localizedDescription
        }
    }

    func exportLocalData() async {
        struct ExportBundle: Codable {
            let profile: UserProfile?
            let preferences: AppPreferences
            let vehicles: [Vehicle]
            let drives: [Drive]
            let traps: [SpeedTrap]
            let zones: [SpeedZone]
        }

        do {
            let bundle = ExportBundle(profile: profile, preferences: preferences, vehicles: vehicles, drives: drives, traps: traps, zones: zones)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("vroom-export.json")
            let data = try JSONEncoder().encode(bundle)
            try data.write(to: url, options: .atomic)
            exportedDataURL = url
            showBanner(title: "Export ready", message: "Use Share Export to send the file.", tone: .success)
        } catch {
            currentAlertMessage = error.localizedDescription
        }
    }

    func resetLocalData() async {
        do {
            let context = ModelContext(container.modelContainer)
            try context.fetch(FetchDescriptor<UserProfileRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<VehicleRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<DriveRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<DrivingEventRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<SpeedTrapRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<SpeedZoneRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<SpeedZoneRunRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<AppPreferencesRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<SubscriptionSnapshotRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<SyncChangeEnvelopeRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<ConvoyCacheRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<RoutePointRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<ActiveDriveSessionRecord>()).forEach(context.delete)
            try context.save()
            try await container.subscriptionRepository.clearSnapshot()
            exportedDataURL = nil
            routeAssetCache = DriveRouteAssetCache()
            routeLoadTasks.removeAll()
            routePreviewTasks.removeAll()
            await refreshData()
            showBanner(title: "Local data deleted", message: "This device no longer has saved Vroom data.", tone: .warning)
        } catch {
            currentAlertMessage = error.localizedDescription
        }
    }

    func createConvoy() async {
        currentAlertMessage = ConvoyUnavailableError.unavailable.localizedDescription
    }

    func joinConvoy(code: String) async {
        currentAlertMessage = ConvoyUnavailableError.unavailable.localizedDescription
    }

    func leaveConvoy() async {
        currentConvoy = nil
        convoyParticipants = []
        convoyStatus = .ended
    }

    func dismissCompletedDrive() {
        presentedCompletedDrive = nil
    }

    func clearAlert() {
        currentAlertMessage = nil
    }

    func clearBanner() {
        currentBanner = nil
    }

    private func showBanner(title: String, message: String? = nil, tone: RoadBannerTone) {
        currentBanner = AppBanner(title: title, message: message, tone: tone)
        switch tone {
        case .success:
            RoadFeedback.notify(.success)
        case .info:
            RoadFeedback.impact(.light)
        case .warning:
            RoadFeedback.notify(.warning)
        }
    }

    private func observeDriveCoordinator() async {
        guard sessionObservationTask == nil, completionObservationTask == nil else { return }
        let sessionStream = await container.driveSessionCoordinator.sessionStream()
        sessionObservationTask = Task { [weak self] in
            for await session in sessionStream {
                await MainActor.run {
                    self?.activeDriveSession = session
                }
            }
        }
        let completionStream = await container.driveSessionCoordinator.completedDriveStream()
        completionObservationTask = Task { [weak self] in
            for await drive in completionStream {
                await MainActor.run {
                    self?.latestCompletedDrive = drive
                    self?.presentedCompletedDrive = drive
                }
            }
        }
    }

    private func seedPreviewDataIfNeeded() async {
        guard ProcessInfo.processInfo.arguments.contains("UITestingSeedPreviewData") else { return }

        struct SeedDrive {
            let drive: Drive
            let trace: [RoutePointSample]
            let events: [DrivingEvent]
            let traps: [SpeedTrap]
        }

        do {
            if try await container.profileRepository.loadProfile() != nil {
                return
            }

            try await container.profileRepository.saveProfile(PreviewFixtures.profile)

            var preferences = AppPreferences.default
            preferences.mapStyle = .imagery
            try await container.preferencesRepository.savePreferences(preferences)

            let secondVehicle = Vehicle(
                id: UUID(uuidString: "22222222-3333-4444-5555-666666666666") ?? UUID(),
                nickname: "Atlas",
                make: "BMW",
                model: "M2",
                year: 2023,
                isPrimary: false,
                archivedAt: nil
            )

            try await container.vehicleRepository.saveVehicle(PreviewFixtures.vehicle)
            try await container.vehicleRepository.saveVehicle(secondVehicle)

            let firstTrace = shiftedTrace(
                from: PreviewFixtures.traceSamples,
                latitudeDelta: 0,
                longitudeDelta: 0,
                timeOffset: 0
            )
            let firstEvents = [
                DrivingEvent(
                    id: UUID(),
                    driveID: PreviewFixtures.drive.id,
                    type: .hardBrake,
                    severity: .medium,
                    confidence: 0.8,
                    timestamp: firstTrace[1].timestamp,
                    coordinate: firstTrace[1].coordinate,
                    metadata: ["deltaKPH": 18]
                ),
                DrivingEvent(
                    id: UUID(),
                    driveID: PreviewFixtures.drive.id,
                    type: .cornering,
                    severity: .low,
                    confidence: 0.7,
                    timestamp: firstTrace[2].timestamp,
                    coordinate: firstTrace[2].coordinate,
                    metadata: ["lateralG": 0.6]
                )
            ]

            let secondDriveID = UUID(uuidString: "BBBBBBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF") ?? UUID()
            let secondTrace = shiftedTrace(
                from: PreviewFixtures.traceSamples,
                latitudeDelta: 0.012,
                longitudeDelta: -0.018,
                timeOffset: 12_000
            )
            let secondEvents = [
                DrivingEvent(
                    id: UUID(),
                    driveID: secondDriveID,
                    type: .hardAcceleration,
                    severity: .medium,
                    confidence: 0.82,
                    timestamp: secondTrace[1].timestamp,
                    coordinate: secondTrace[1].coordinate,
                    metadata: ["deltaKPH": 14]
                ),
                DrivingEvent(
                    id: UUID(),
                    driveID: secondDriveID,
                    type: .speedTrap,
                    severity: .high,
                    confidence: 0.9,
                    timestamp: secondTrace[2].timestamp,
                    coordinate: secondTrace[2].coordinate,
                    metadata: ["peakKPH": 96]
                )
            ]

            let thirdDriveID = UUID(uuidString: "CCCCCCCC-DDDD-EEEE-FFFF-AAAAAAAAAAAA") ?? UUID()
            let thirdTrace = shiftedTrace(
                from: PreviewFixtures.traceSamples,
                latitudeDelta: -0.016,
                longitudeDelta: 0.011,
                timeOffset: 22_000
            )
            let thirdEvents = [
                DrivingEvent(
                    id: UUID(),
                    driveID: thirdDriveID,
                    type: .gForceSpike,
                    severity: .high,
                    confidence: 0.88,
                    timestamp: thirdTrace[2].timestamp,
                    coordinate: thirdTrace[2].coordinate,
                    metadata: ["g": 1.1]
                )
            ]

            let seedDrives: [SeedDrive] = [
                SeedDrive(
                    drive: Drive(
                        id: PreviewFixtures.drive.id,
                        vehicleID: PreviewFixtures.vehicle.id,
                        startedAt: firstTrace.first?.timestamp ?? Date(),
                        endedAt: firstTrace.last?.timestamp ?? Date(),
                        distanceMeters: 6_300,
                        duration: 1_080,
                        avgSpeedKPH: 49,
                        topSpeedKPH: 84,
                        favorite: true,
                        scoreSummary: DriveScoreSummary(overall: 88, subscores: ["smoothness": 91], deductions: ["hardBrake": 6], profileID: ScoringProfile.casual.id),
                        traceRef: PreviewFixtures.drive.traceRef,
                        summary: DriveSummary(title: "Sunset Canyon Run", highlight: "Balanced pace with crisp corner entry through the mid-route section.", eventCount: firstEvents.count)
                    ),
                    trace: firstTrace,
                    events: firstEvents,
                    traps: [
                        SpeedTrap(id: UUID(), driveID: PreviewFixtures.drive.id, timestamp: firstTrace[2].timestamp, peakSpeedKPH: 84, coordinate: firstTrace[2].coordinate, isFavorite: true)
                    ]
                ),
                SeedDrive(
                    drive: Drive(
                        id: secondDriveID,
                        vehicleID: secondVehicle.id,
                        startedAt: secondTrace.first?.timestamp ?? Date(),
                        endedAt: secondTrace.last?.timestamp ?? Date(),
                        distanceMeters: 11_800,
                        duration: 1_560,
                        avgSpeedKPH: 57,
                        topSpeedKPH: 96,
                        favorite: false,
                        scoreSummary: DriveScoreSummary(overall: 84, subscores: ["pace": 89], deductions: ["speedTrap": 8], profileID: ScoringProfile.casual.id),
                        traceRef: secondDriveID.uuidString,
                        summary: DriveSummary(title: "Harbor Sprint", highlight: "Longer route with a harder acceleration phase and one major peak moment.", eventCount: secondEvents.count)
                    ),
                    trace: secondTrace,
                    events: secondEvents,
                    traps: [
                        SpeedTrap(id: UUID(), driveID: secondDriveID, timestamp: secondTrace[2].timestamp, peakSpeedKPH: 96, coordinate: secondTrace[2].coordinate, isFavorite: false)
                    ]
                ),
                SeedDrive(
                    drive: Drive(
                        id: thirdDriveID,
                        vehicleID: PreviewFixtures.vehicle.id,
                        startedAt: thirdTrace.first?.timestamp ?? Date(),
                        endedAt: thirdTrace.last?.timestamp ?? Date(),
                        distanceMeters: 9_400,
                        duration: 1_320,
                        avgSpeedKPH: 51,
                        topSpeedKPH: 78,
                        favorite: false,
                        scoreSummary: DriveScoreSummary(overall: 90, subscores: ["smoothness": 93], deductions: ["gForceSpike": 4], profileID: ScoringProfile.casual.id),
                        traceRef: thirdDriveID.uuidString,
                        summary: DriveSummary(title: "Night Loop", highlight: "Cleaner session with one high-load spike and a calmer closing sector.", eventCount: thirdEvents.count)
                    ),
                    trace: thirdTrace,
                    events: thirdEvents,
                    traps: []
                )
            ]

            for item in seedDrives {
                try await container.driveRepository.saveDrive(item.drive)
                try await container.drivingEventRepository.saveEvents(item.events)
                try await container.trapRepository.saveTrapCandidates(item.traps)

                let handle = try await container.routeTraceRepository.openWriter(for: item.drive.id)
                for sample in item.trace {
                    try await container.routeTraceRepository.append(sample: sample, to: handle)
                }
                _ = try await container.routeTraceRepository.finalize(handle: handle)
            }

            try await container.zoneRepository.saveZone(PreviewFixtures.zone)
            try await container.zoneRepository.recordRun(PreviewFixtures.zoneRun)
            try await container.subscriptionRepository.saveSnapshot(
                SubscriptionSnapshot(
                    tier: .premium,
                    products: [],
                    renewalState: .active,
                    expirationDate: nil,
                    lastValidatedAt: Date()
                )
            )
        } catch {
            currentAlertMessage = error.localizedDescription
        }
    }

    private func shiftedTrace(
        from trace: [RoutePointSample],
        latitudeDelta: Double,
        longitudeDelta: Double,
        timeOffset: TimeInterval
    ) -> [RoutePointSample] {
        trace.enumerated().map { index, sample in
            RoutePointSample(
                timestamp: sample.timestamp.addingTimeInterval(timeOffset + Double(index * 45)),
                coordinate: GeoCoordinate(
                    latitude: sample.coordinate.latitude + latitudeDelta,
                    longitude: sample.coordinate.longitude + longitudeDelta
                ),
                altitudeMeters: sample.altitudeMeters,
                verticalAccuracy: sample.verticalAccuracy,
                horizontalAccuracy: sample.horizontalAccuracy,
                speedKPH: sample.speedKPH + Double(index * 3),
                courseDegrees: sample.courseDegrees,
                headingAccuracy: sample.headingAccuracy
            )
        }
    }

    private func resolveRouteTrace(for driveID: UUID, forceReload: Bool) async -> [RoutePointSample] {
        if !forceReload, let trace = routeAssetCache.loadState(for: driveID).trace {
            return trace
        }

        if let existingTask = routeLoadTasks[driveID] {
            return await existingTask.value
        }

        routeAssetCache.setLoadState(.loading, for: driveID)
        let task = Task { [container] in
            (try? await container.routeTraceRepository.loadTrace(for: driveID)) ?? []
        }
        routeLoadTasks[driveID] = task
        let trace = await task.value
        routeLoadTasks[driveID] = nil
        routeAssetCache.setLoadState(trace.isEmpty ? .unavailable : .ready(trace), for: driveID)
        return trace
    }

    private func resolveRoutePreview(for key: DriveRoutePreviewKey, trace: [RoutePointSample]) async {
        guard !trace.isEmpty else {
            routeAssetCache.setPreviewState(.unavailable, for: key)
            return
        }

        switch routeAssetCache.previewState(for: key) {
        case .ready, .loading:
            if let existingTask = routePreviewTasks[key] {
                _ = await existingTask.value
            }
            return
        case .idle, .unavailable:
            break
        }

        routeAssetCache.setPreviewState(.loading, for: key)
        let task = Task { [container] in
            await container.mapRenderingService.renderRouteSnapshot(
                RouteSnapshotRequest(
                    driveID: key.driveID,
                    trace: trace,
                    size: key.size,
                    style: key.mapStyle
                )
            )
        }
        routePreviewTasks[key] = task
        let data = await task.value
        routePreviewTasks[key] = nil
        routeAssetCache.setPreviewState(data.map(DriveRoutePreviewState.ready) ?? .unavailable, for: key)
    }

    private func pruneRouteAssets() {
        var keepIDs = Set(drives.map(\.id))
        if let activeDriveID = activeDriveSession?.sessionID {
            keepIDs.insert(activeDriveID)
        }
        routeAssetCache.prune(keeping: keepIDs)
    }
}
