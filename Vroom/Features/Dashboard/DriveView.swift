import SwiftUI

struct DriveView: View {
    @EnvironmentObject private var appState: AppStateStore
    @State private var routeTrace: [RoutePointSample] = []
    @State private var showingConvoys = false

    private var hero: DriveHeroPresentation {
        RoadPresentationBuilder.hero(
            session: appState.activeDriveSession,
            latestDrive: appState.latestCompletedDrive,
            preferredVehicle: appState.vehicle(for: appState.activeDriveSession?.activeVehicleID) ?? appState.primaryVehicle
        )
    }

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

    private var mapMode: RouteMapMode {
        if appState.activeDriveSession != nil {
            return .live
        }
        return routeTrace.isEmpty ? .idle : .completed
    }

    private var headerSubtitle: String {
        if appState.activeDriveSession != nil {
            return "Recording your current drive."
        }
        if appState.latestCompletedDrive != nil {
            return "Start a new drive or review the last one."
        }
        return "Start your first drive when you are ready."
    }

    private var primaryButtonTitle: String {
        appState.activeDriveSession == nil ? "Start drive" : "Stop and save drive"
    }

    var body: some View {
        ZStack {
            RouteMapView(
                trace: routeTrace,
                events: displayedEvents,
                mode: mapMode,
                style: appState.preferences.mapStyle
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [RoadTheme.mapScrimTop, .clear, RoadTheme.mapScrimBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .overlay(alignment: .top) {
            RoadPageHeader(
                title: "Drive",
                subtitle: headerSubtitle,
                badgeText: hero.status,
                badgeAccent: hero.statusAccent
            )
            .padding(.horizontal, RoadSpacing.regular)
            .padding(.top, RoadSpacing.hero)
        }
        .safeAreaInset(edge: .bottom) {
            RoadHeroPanel {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: RoadSpacing.large) {
                        VStack(alignment: .leading, spacing: RoadSpacing.small) {
                            Text(hero.title)
                                .font(RoadTypography.sectionTitle)
                                .foregroundStyle(RoadTheme.textPrimary)

                            Text(hero.subtitle)
                                .font(RoadTypography.supporting)
                                .foregroundStyle(RoadTheme.textSecondary)
                        }

                        RoadMetricGrid(metrics: hero.metrics, minimumWidth: 132)

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

                        if let latestDrive = appState.latestCompletedDrive, appState.activeDriveSession == nil {
                            Divider()
                                .overlay(RoadTheme.divider)

                            VStack(alignment: .leading, spacing: RoadSpacing.compact) {
                                RoadSectionHeader(
                                    title: "Last drive",
                                    subtitle: "Open the most recent drive or replay the route."
                                )

                                NavigationLink {
                                    DriveDetailView(drive: latestDrive)
                                } label: {
                                    HStack(spacing: RoadSpacing.regular) {
                                        VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                                            Text(latestDrive.summary.title)
                                                .font(.headline.weight(.semibold))
                                                .foregroundStyle(RoadTheme.textPrimary)

                                            Text(latestDrive.summary.highlight)
                                                .font(RoadTypography.caption)
                                                .foregroundStyle(RoadTheme.textSecondary)
                                                .lineLimit(2)
                                        }

                                        Spacer(minLength: 0)

                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(RoadTheme.textMuted)
                                    }
                                    .padding(RoadSpacing.regular)
                                    .background(
                                        RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                                            .fill(RoadTheme.backgroundRaised)
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                                            .strokeBorder(RoadTheme.border)
                                    }
                                }
                                .buttonStyle(.plain)

                                NavigationLink {
                                    RouteReplayView(drive: latestDrive)
                                } label: {
                                    Label("Replay drive", systemImage: "play.circle")
                                }
                                .buttonStyle(RoadSecondaryButtonStyle())
                            }
                        } else if appState.latestCompletedDrive == nil, appState.activeDriveSession == nil {
                            Divider()
                                .overlay(RoadTheme.divider)

                            VStack(alignment: .leading, spacing: RoadSpacing.small) {
                                Text("No completed drives yet")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(RoadTheme.textPrimary)

                                Text("Your completed drives will appear here after you save one.")
                                    .font(RoadTypography.supporting)
                                    .foregroundStyle(RoadTheme.textSecondary)
                            }
                        }

                        Divider()
                            .overlay(RoadTheme.divider)

                        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
                            RoadSectionHeader(
                                title: "Convoys beta",
                                subtitle: "Room history is available, but live convoy syncing is still offline."
                            )

                            Button("Open convoys") {
                                showingConvoys = true
                            }
                            .buttonStyle(RoadSecondaryButtonStyle())
                            .accessibilityIdentifier("Drive.Convoys")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 360)
            }
            .padding(.horizontal, RoadSpacing.regular)
            .padding(.top, RoadSpacing.compact)
            .padding(.bottom, RoadSpacing.compact)
            .background(Color.clear)
        }
        .toolbar(.hidden, for: .navigationBar)
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
            .presentationDetents([.medium, .large])
        }
        .accessibilityIdentifier("Drive.Screen")
    }

    private func loadDisplayedTrace() async {
        if let liveSession = appState.activeDriveSession {
            routeTrace = await appState.loadTrace(for: liveSession.sessionID)
        } else if let latestDrive = appState.latestCompletedDrive {
            routeTrace = await appState.loadTrace(for: latestDrive.id)
        } else {
            routeTrace = []
        }
    }
}

private struct TraceTaskID: Hashable {
    let liveSessionID: UUID?
    let liveSamples: Int
    let fallbackDriveID: UUID?
}
