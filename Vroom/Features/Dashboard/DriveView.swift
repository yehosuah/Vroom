import SwiftUI
import UIKit

struct DriveView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var appState: AppStateStore

    @State private var showingConvoys = false
    @State private var mapCameraMode: RouteMapCameraMode = .fitRoute

    private var traceTaskID: TraceTaskID {
        TraceTaskID(
            liveSessionID: appState.activeDriveSession?.sessionID,
            liveSamples: appState.activeDriveSession?.liveMetrics.sampleCount ?? 0,
            fallbackDriveID: appState.latestCompletedDrive?.id
        )
    }

    private var displayedEvents: [DrivingEvent] {
        guard let drive = appState.latestCompletedDrive, appState.activeDriveSession == nil else { return [] }
        return appState.events(for: drive.id)
    }

    private var displayedDriveID: UUID? {
        appState.activeDriveSession?.sessionID ?? appState.latestCompletedDrive?.id
    }

    private var displayedRouteState: DriveRouteLoadState {
        guard let displayedDriveID else { return .idle }
        return appState.routeLoadState(for: displayedDriveID)
    }

    private var mapMode: RouteMapMode {
        if appState.activeDriveSession != nil {
            return .live
        }
        return appState.latestCompletedDrive == nil ? .idle : .completed
    }

    private var hasLocationReady: Bool {
        appState.permissionState.location == .always
    }

    private var hasMotionReady: Bool {
        appState.permissionState.motion == .authorized
    }

    private var hasNotificationReady: Bool {
        appState.permissionState.notifications == .authorized || appState.permissionState.notifications == .provisional
    }

    private var hasDeniedPermission: Bool {
        let locationDenied = appState.permissionState.location == .denied || appState.permissionState.location == .restricted
        let motionDenied = appState.permissionState.motion == .denied || appState.permissionState.motion == .restricted
        let notificationDenied = appState.permissionState.notifications == .denied
        return locationDenied || motionDenied || notificationDenied
    }

    private var statusLabel: String {
        if let session = appState.activeDriveSession {
            return session.liveMetrics.signalQuality.displayTitle
        }
        if readinessItems.isEmpty {
            return "Ready"
        }
        return "Needs Setup"
    }

    private var statusTint: Color {
        if let session = appState.activeDriveSession {
            return signalTint(for: session.liveMetrics.signalQuality)
        }
        return readinessItems.isEmpty ? RoadTheme.success : RoadTheme.warning
    }

    private var heroTitle: String {
        appState.activeDriveSession == nil ? "Ready for your next drive" : "Drive in progress"
    }

    private var heroSubtitle: String {
        if let session = appState.activeDriveSession {
            return signalSubtitle(for: session.liveMetrics.signalQuality)
        }
        if !readinessItems.isEmpty {
            return "Finish the highlighted setup items before relying on automatic tracking."
        }
        if appState.latestCompletedDrive == nil {
            return "Start your first tracked drive when you're ready."
        }
        return "Tracking is ready. Start a new drive when you are."
    }

    private var heroValueTitle: String {
        if appState.activeDriveSession != nil {
            return "Current speed"
        }
        if appState.latestCompletedDrive != nil {
            return "Last score"
        }
        return "Status"
    }

    private var heroValue: String {
        if let session = appState.activeDriveSession {
            return RoadFormatting.speed(session.liveMetrics.currentSpeedKPH)
        }
        if let latestDrive = appState.latestCompletedDrive {
            return "\(latestDrive.scoreSummary.overall)"
        }
        return readinessItems.isEmpty ? "Ready" : "Finish setup"
    }

    private var heroMetrics: [RoadMetricPresentation] {
        if let session = appState.activeDriveSession {
            return [
                RoadMetricPresentation(id: "drive-distance", label: "Distance", value: RoadFormatting.distance(session.liveMetrics.distanceMeters), icon: "arrow.left.and.right", accent: .neutral),
                RoadMetricPresentation(id: "drive-time", label: "Drive time", value: RoadFormatting.duration(session.liveMetrics.duration), icon: "clock", accent: .electric),
                RoadMetricPresentation(id: "drive-top", label: "Top speed", value: RoadFormatting.speed(session.liveMetrics.topSpeedKPH), icon: "hare.fill", accent: .alert)
            ]
        }

        return [
            RoadMetricPresentation(
                id: "drive-home-vehicle",
                label: "Vehicle",
                value: appState.primaryVehicle?.nickname ?? "Add in Garage",
                icon: "car.fill",
                accent: appState.primaryVehicle == nil ? .alert : .neutral
            ),
            RoadMetricPresentation(
                id: "drive-home-tracking",
                label: "Tracking",
                value: readinessItems.isEmpty ? "Ready" : "\(readinessItems.count) items",
                icon: readinessItems.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                accent: readinessItems.isEmpty ? .success : .alert
            ),
            RoadMetricPresentation(
                id: "drive-home-history",
                label: "History",
                value: appState.latestCompletedDrive == nil ? "Waiting" : "Available",
                icon: "clock.arrow.circlepath",
                accent: appState.latestCompletedDrive == nil ? .neutral : .electric
            )
        ]
    }

    private var primaryButtonTitle: String {
        appState.activeDriveSession == nil ? "Start Drive" : "End Drive"
    }

    private var readinessItems: [RoadReadinessItem] {
        var items: [RoadReadinessItem] = []

        if !hasLocationReady {
            let denied = appState.permissionState.location == .denied || appState.permissionState.location == .restricted
            items.append(
                RoadReadinessItem(
                    id: "location",
                    icon: appState.permissionState.location.iconName,
                    title: "Location access",
                    message: denied
                        ? "Open Settings to allow Always location access for reliable drive capture."
                        : "Allow Always location access so Vroom can keep tracking a route after you start driving.",
                    status: appState.permissionState.location.displayTitle,
                    tone: denied ? .warning : .info,
                    actionTitle: denied ? "Open Settings" : "Enable Location",
                    action: denied ? openSettings : { Task { await appState.requestLocationPermissions() } }
                )
            )
        }

        if !hasMotionReady {
            let denied = appState.permissionState.motion == .denied || appState.permissionState.motion == .restricted
            items.append(
                RoadReadinessItem(
                    id: "motion",
                    icon: appState.permissionState.motion.iconName,
                    title: "Motion access",
                    message: denied
                        ? "Motion access is blocked. Open Settings so Vroom can separate driving from walking and waiting."
                        : "Allow motion access so Vroom can more confidently detect active driving.",
                    status: appState.permissionState.motion.displayTitle,
                    tone: denied ? .warning : .info,
                    actionTitle: denied ? "Open Settings" : "Enable Motion",
                    action: denied ? openSettings : { Task { await appState.requestMotionPermissions() } }
                )
            )
        }

        if !hasNotificationReady {
            let denied = appState.permissionState.notifications == .denied
            items.append(
                RoadReadinessItem(
                    id: "notifications",
                    icon: appState.permissionState.notifications.iconName,
                    title: "Drive notifications",
                    message: denied
                        ? "Notifications are blocked. Open Settings if you want confirmations when a drive ends or needs attention."
                        : "Allow notifications so Vroom can confirm when a drive is saved or needs your attention.",
                    status: appState.permissionState.notifications.displayTitle,
                    tone: denied ? .warning : .info,
                    actionTitle: denied ? "Open Settings" : "Enable Notifications",
                    action: denied ? openSettings : { Task { await appState.requestNotificationPermissions() } }
                )
            )
        }

        return items
    }

    var body: some View {
        RoadScreenScaffold(bottomPadding: 152) {
            RoadPageHeader(
                title: appState.activeDriveSession == nil ? "Drive" : "Live drive",
                subtitle: appState.activeDriveSession == nil
                    ? "Track a new route, then review the payoff in history, replay, and insights."
                    : "Stay focused while Vroom records the route in the background."
            )

            heroMapSection

            if !readinessItems.isEmpty {
                RoadReadinessChecklist(
                    title: "Tracking readiness",
                    subtitle: hasDeniedPermission
                        ? "At least one permission needs recovery in Settings before tracking is fully dependable."
                        : "Finish setup now so your next drive records cleanly from start to finish.",
                    items: readinessItems
                )
            }

            if let latestDrive = appState.latestCompletedDrive, appState.activeDriveSession == nil {
                latestDriveSection(latestDrive)
            }
        }
        .navigationTitle("Drive")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            RoadBottomActionBar {
                VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                    Button(primaryButtonTitle) {
                        Task {
                            if appState.activeDriveSession == nil {
                                await appState.startDrive()
                            } else {
                                await appState.stopDrive()
                            }
                        }
                    }
                    .buttonStyle(RoadPrimaryButtonStyle())

                    Button(appState.activeDriveSession == nil ? "Convoys preview" : "View convoy preview") {
                        showingConvoys = true
                    }
                    .buttonStyle(RoadSubtleButtonStyle(tint: RoadTheme.info))
                    .accessibilityIdentifier("Drive.ConvoysPreview")
                }
            }
        }
        .task {
            await appState.refreshData()
        }
        .task(id: traceTaskID) {
            await loadDisplayedTrace()
        }
        .sheet(isPresented: $showingConvoys) {
            NavigationStack {
                ConvoysView()
                    .environmentObject(appState)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .accessibilityIdentifier("Drive.Screen")
    }

    private var heroMapSection: some View {
        ZStack(alignment: .bottomLeading) {
            mapHeroSurface

            LinearGradient(
                colors: [RoadTheme.mapScrimTop, .clear, RoadTheme.mapScrimBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: RoadRadius.hero, style: .continuous))

            RoadHeroPanel {
                VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                    HStack(alignment: .top, spacing: RoadSpacing.compact) {
                        VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                            Text(heroTitle)
                                .font(RoadTypography.sectionTitle)
                                .foregroundStyle(RoadTheme.textPrimary)

                            Text(heroSubtitle)
                                .font(RoadTypography.supporting)
                                .foregroundStyle(RoadTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)

                        RoadCapsuleLabel(text: statusLabel, tint: statusTint)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(heroValueTitle)
                            .font(RoadTypography.meta)
                            .foregroundStyle(RoadTheme.textSecondary)

                        Text(heroValue)
                            .font(RoadTypography.heroValue)
                            .foregroundStyle(RoadTheme.textPrimary)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    RoadMetricGrid(metrics: heroMetrics, minimumWidth: 112)
                }
            }
            .padding(RoadSpacing.regular)
        }
    }

    @ViewBuilder
    private var mapHeroSurface: some View {
        switch displayedRouteState {
        case .idle:
            if displayedDriveID == nil {
                RouteMapView(
                    trace: [],
                    events: [],
                    mode: .idle,
                    cameraMode: .manual,
                    style: appState.preferences.mapStyle
                )
                .frame(height: 380)
                .clipShape(RoundedRectangle(cornerRadius: RoadRadius.hero, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: RoadRadius.hero, style: .continuous)
                        .strokeBorder(RoadTheme.border)
                }
            } else {
                RouteMapStatusView(
                    title: "Loading route",
                    subtitle: "Fetching the last saved route so Drive can show your current context.",
                    icon: "point.3.filled.connected.trianglepath",
                    showsProgress: true
                )
                .frame(height: 380)
            }

        case .loading:
            RouteMapStatusView(
                title: "Loading route",
                subtitle: "Fetching the last saved route so Drive can show your current context.",
                icon: "point.3.filled.connected.trianglepath",
                showsProgress: true
            )
            .frame(height: 380)

        case .ready(let trace):
            RouteMapView(
                trace: trace,
                events: displayedEvents,
                mode: mapMode,
                cameraMode: mapCameraMode,
                style: appState.preferences.mapStyle,
                onCameraModeChange: { mapCameraMode = $0 }
            )
            .frame(height: 380)
            .clipShape(RoundedRectangle(cornerRadius: RoadRadius.hero, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: RoadRadius.hero, style: .continuous)
                    .strokeBorder(RoadTheme.border)
            }

        case .unavailable:
            RouteMapStatusView(
                title: appState.activeDriveSession == nil ? "No route to show" : "Waiting for route points",
                subtitle: appState.activeDriveSession == nil
                    ? "Start another drive to bring a route back into focus here."
                    : "The map will begin following once location samples are recorded.",
                icon: appState.activeDriveSession == nil ? "map" : "location.slash",
                tone: appState.activeDriveSession == nil ? .warning : .info
            )
            .frame(height: 380)
        }
    }

    private func latestDriveSection(_ drive: Drive) -> some View {
        let vehicle = appState.vehicle(for: drive.vehicleID)

        return VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            RoadSectionHeader(
                title: "Last saved drive",
                subtitle: "Resume the story from where you left off."
            )

            RoadPanel {
                VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                    NavigationLink {
                        DriveDetailView(drive: drive)
                    } label: {
                        VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                            HStack(alignment: .top, spacing: RoadSpacing.compact) {
                                VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                                    Text(drive.summary.title)
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(RoadTheme.textPrimary)

                                    Text(drive.summary.highlight)
                                        .font(RoadTypography.meta)
                                        .foregroundStyle(RoadTheme.textSecondary)
                                        .lineLimit(2)
                                }

                                Spacer(minLength: 0)

                                RoadCapsuleLabel(text: "Score \(drive.scoreSummary.overall)", tint: RoadTheme.success)
                            }

                            HStack(spacing: RoadSpacing.compact) {
                                RoadCapsuleLabel(text: RoadFormatting.distance(drive.distanceMeters), tint: RoadTheme.info, icon: "arrow.left.and.right")
                                RoadCapsuleLabel(text: RoadFormatting.duration(drive.duration), tint: RoadTheme.warning, icon: "clock")

                                if let vehicle {
                                    RoadCapsuleLabel(text: vehicle.nickname, tint: RoadTheme.primaryAction, icon: "car.fill")
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: RoadSpacing.compact) {
                        NavigationLink("Review Drive") {
                            DriveDetailView(drive: drive)
                        }
                        .buttonStyle(RoadSecondaryButtonStyle())

                        NavigationLink("Watch Replay") {
                            RouteReplayView(drive: drive)
                        }
                        .buttonStyle(RoadSecondaryButtonStyle())
                    }
                }
            }
        }
    }

    private func loadDisplayedTrace() async {
        if let liveSession = appState.activeDriveSession {
            mapCameraMode = .followLatest
            await appState.ensureRouteAssets(for: liveSession.sessionID, forceReload: true)
        } else if let latestDrive = appState.latestCompletedDrive {
            mapCameraMode = .fitRoute
            await appState.ensureRouteAssets(for: latestDrive.id)
        } else {
            mapCameraMode = .fitRoute
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }

    private func signalTint(for quality: SignalQuality) -> Color {
        switch quality {
        case .unknown, .good:
            return RoadTheme.success
        case .degraded:
            return RoadTheme.warning
        case .poor:
            return RoadTheme.destructive
        }
    }

    private func signalSubtitle(for quality: SignalQuality) -> String {
        switch quality {
        case .unknown, .good:
            return "Route recording is active and updating normally."
        case .degraded:
            return "Recording continues, but location accuracy is reduced."
        case .poor:
            return "Signal is weak. Route detail should improve when reception recovers."
        }
    }
}

private struct TraceTaskID: Hashable {
    let liveSessionID: UUID?
    let liveSamples: Int
    let fallbackDriveID: UUID?
}
