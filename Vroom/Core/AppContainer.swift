import Foundation
import SwiftData

final class AppContainer {
    let environment: AppEnvironment
    let logger = RoadTrackLogger(category: "App")
    let modelContainer: ModelContainer

    let profileRepository: any ProfileRepository
    let vehicleRepository: any VehicleRepository
    let driveRepository: any DriveRepository
    let routeTraceRepository: any RouteTraceRepository
    let drivingEventRepository: any DrivingEventRepository
    let insightsRepository: any InsightsRepository
    let trapRepository: any TrapRepository
    let zoneRepository: any ZoneRepository
    let preferencesRepository: any PreferencesRepository
    let subscriptionRepository: any SubscriptionRepository
    let configurationRepository: any DriveAnalysisConfigurationRepository
    let syncQueueRepository: any SyncQueueRepository
    let convoyCacheRepository: any ConvoyCacheRepository
    let activeDriveSessionRepository: any ActiveDriveSessionRepository

    let locationService: any LocationMonitoringService
    let motionActivityService: any MotionActivityMonitoringService
    let deviceMotionService: any DeviceMotionMonitoringService
    let backgroundExecutionService: any BackgroundExecutionService
    let notificationService: any NotificationSchedulingService
    let entitlementService: any EntitlementService
    let storefrontService: any StorefrontService
    let convoyTransport: any ConvoyTransport
    let mapRenderingService: any MapRenderingService
    let shareCardRenderingService: any ShareCardRenderingService
    let syncEngine: any SyncEngine
    let voiceChatService: any VoiceChatService
    let identityService: any IdentityService
    let driveTrackingService: any DriveTrackingService

    let driveSessionCoordinator: DriveSessionCoordinator
    let convoySessionCoordinator: ConvoySessionCoordinator

    init(
        environment: AppEnvironment,
        modelContainer: ModelContainer,
        profileRepository: any ProfileRepository,
        vehicleRepository: any VehicleRepository,
        driveRepository: any DriveRepository,
        routeTraceRepository: any RouteTraceRepository,
        drivingEventRepository: any DrivingEventRepository,
        insightsRepository: any InsightsRepository,
        trapRepository: any TrapRepository,
        zoneRepository: any ZoneRepository,
        preferencesRepository: any PreferencesRepository,
        subscriptionRepository: any SubscriptionRepository,
        configurationRepository: any DriveAnalysisConfigurationRepository,
        syncQueueRepository: any SyncQueueRepository,
        convoyCacheRepository: any ConvoyCacheRepository,
        activeDriveSessionRepository: any ActiveDriveSessionRepository,
        locationService: any LocationMonitoringService,
        motionActivityService: any MotionActivityMonitoringService,
        deviceMotionService: any DeviceMotionMonitoringService,
        backgroundExecutionService: any BackgroundExecutionService,
        notificationService: any NotificationSchedulingService,
        entitlementService: any EntitlementService,
        storefrontService: any StorefrontService,
        convoyTransport: any ConvoyTransport,
        mapRenderingService: any MapRenderingService,
        shareCardRenderingService: any ShareCardRenderingService,
        syncEngine: any SyncEngine,
        voiceChatService: any VoiceChatService,
        identityService: any IdentityService,
        driveTrackingService: any DriveTrackingService,
        driveSessionCoordinator: DriveSessionCoordinator,
        convoySessionCoordinator: ConvoySessionCoordinator
    ) {
        self.environment = environment
        self.modelContainer = modelContainer
        self.profileRepository = profileRepository
        self.vehicleRepository = vehicleRepository
        self.driveRepository = driveRepository
        self.routeTraceRepository = routeTraceRepository
        self.drivingEventRepository = drivingEventRepository
        self.insightsRepository = insightsRepository
        self.trapRepository = trapRepository
        self.zoneRepository = zoneRepository
        self.preferencesRepository = preferencesRepository
        self.subscriptionRepository = subscriptionRepository
        self.configurationRepository = configurationRepository
        self.syncQueueRepository = syncQueueRepository
        self.convoyCacheRepository = convoyCacheRepository
        self.activeDriveSessionRepository = activeDriveSessionRepository
        self.locationService = locationService
        self.motionActivityService = motionActivityService
        self.deviceMotionService = deviceMotionService
        self.backgroundExecutionService = backgroundExecutionService
        self.notificationService = notificationService
        self.entitlementService = entitlementService
        self.storefrontService = storefrontService
        self.convoyTransport = convoyTransport
        self.mapRenderingService = mapRenderingService
        self.shareCardRenderingService = shareCardRenderingService
        self.syncEngine = syncEngine
        self.voiceChatService = voiceChatService
        self.identityService = identityService
        self.driveTrackingService = driveTrackingService
        self.driveSessionCoordinator = driveSessionCoordinator
        self.convoySessionCoordinator = convoySessionCoordinator
    }

    static func live(inMemory: Bool = false) -> AppContainer {
        let environment = AppEnvironment.live
        let modelContainer = SwiftDataContainerFactory.makeModelContainer(inMemory: inMemory)
        let profileRepository = ProfileRepositoryImpl(container: modelContainer)
        let vehicleRepository = VehicleRepositoryImpl(container: modelContainer)
        let driveRepository = DriveRepositoryImpl(container: modelContainer)
        let routeTraceRepository = RouteTraceRepositoryImpl(container: modelContainer)
        let eventRepository = DrivingEventRepositoryImpl(container: modelContainer, clock: environment.clock)
        let insightsRepository = InsightsRepositoryImpl(container: modelContainer, clock: environment.clock)
        let trapRepository = TrapRepositoryImpl(container: modelContainer)
        let zoneRepository = ZoneRepositoryImpl(container: modelContainer)
        let preferencesRepository = PreferencesRepositoryImpl(container: modelContainer)
        let subscriptionRepository = SubscriptionRepositoryImpl(container: modelContainer)
        let configurationRepository = DriveAnalysisConfigurationRepositoryImpl()
        let syncQueueRepository = SyncQueueRepositoryImpl(container: modelContainer)
        let convoyCacheRepository = ConvoyCacheRepositoryImpl(container: modelContainer)
        let activeDriveSessionRepository = ActiveDriveSessionRepositoryImpl(container: modelContainer)

        let locationService = CoreLocationService()
        let motionActivityService = CoreMotionActivityService()
        let deviceMotionService = CoreDeviceMotionService()
        let backgroundExecutionService = UIApplicationBackgroundExecutionService()
        let notificationService = NotificationSchedulingServiceImpl()
        let mapRenderingService = DefaultMapRenderingService()
        let shareCardRenderingService = DefaultShareCardRenderingService(mapRenderingService: mapRenderingService)
        let identityService = IdentityServiceImpl(profileRepository: profileRepository)
        let convoyTransport = UnavailableConvoyTransport()
        let syncEngine = NoopSyncEngine()
        let voiceChatService = NoopVoiceChatService(isAvailable: false)
        let entitlementService = DefaultEntitlementService(subscriptionRepository: subscriptionRepository)
        let storefrontService = StoreKitStorefrontService(
            subscriptionRepository: subscriptionRepository,
            productIDs: Bundle.main.object(forInfoDictionaryKey: "PremiumProductIDs") as? [String] ?? []
        )

        let driveSessionCoordinator = DriveSessionCoordinator(
            clock: environment.clock,
            uuidGenerator: environment.uuidGenerator,
            routeTraceRepository: routeTraceRepository,
            driveRepository: driveRepository,
            eventRepository: eventRepository,
            trapRepository: trapRepository,
            zoneRepository: zoneRepository,
            configurationRepository: configurationRepository,
            notificationService: notificationService,
            mapRenderingService: mapRenderingService,
            activeSessionRepository: activeDriveSessionRepository
        )

        let driveTrackingService = DefaultDriveTrackingService(
            locationService: locationService,
            motionActivityService: motionActivityService,
            deviceMotionService: deviceMotionService,
            profileRepository: profileRepository,
            preferencesRepository: preferencesRepository,
            configurationRepository: configurationRepository,
            driveSessionCoordinator: driveSessionCoordinator
        )

        let convoySessionCoordinator = ConvoySessionCoordinator(
            transport: convoyTransport,
            cacheRepository: convoyCacheRepository,
            identityService: identityService
        )

        return AppContainer(
            environment: environment,
            modelContainer: modelContainer,
            profileRepository: profileRepository,
            vehicleRepository: vehicleRepository,
            driveRepository: driveRepository,
            routeTraceRepository: routeTraceRepository,
            drivingEventRepository: eventRepository,
            insightsRepository: insightsRepository,
            trapRepository: trapRepository,
            zoneRepository: zoneRepository,
            preferencesRepository: preferencesRepository,
            subscriptionRepository: subscriptionRepository,
            configurationRepository: configurationRepository,
            syncQueueRepository: syncQueueRepository,
            convoyCacheRepository: convoyCacheRepository,
            activeDriveSessionRepository: activeDriveSessionRepository,
            locationService: locationService,
            motionActivityService: motionActivityService,
            deviceMotionService: deviceMotionService,
            backgroundExecutionService: backgroundExecutionService,
            notificationService: notificationService,
            entitlementService: entitlementService,
            storefrontService: storefrontService,
            convoyTransport: convoyTransport,
            mapRenderingService: mapRenderingService,
            shareCardRenderingService: shareCardRenderingService,
            syncEngine: syncEngine,
            voiceChatService: voiceChatService,
            identityService: identityService,
            driveTrackingService: driveTrackingService,
            driveSessionCoordinator: driveSessionCoordinator,
            convoySessionCoordinator: convoySessionCoordinator
        )
    }
}
