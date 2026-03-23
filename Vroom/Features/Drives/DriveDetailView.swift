import SwiftUI

struct DriveDetailView: View {
    @EnvironmentObject private var appState: AppStateStore

    let drive: Drive

    @State private var sharePayload = SharePayload(text: "", imageURL: nil)
    @State private var mapCameraMode: RouteMapCameraMode = .fitRoute
    @State private var showingShareComposer = false
    @State private var showingVehicleAssignment = false

    private var currentDrive: Drive {
        appState.drives.first(where: { $0.id == drive.id }) ?? drive
    }

    private var eventList: [DrivingEvent] {
        appState.events(for: currentDrive.id).sorted(by: { $0.timestamp < $1.timestamp })
    }

    private var routeState: DriveRouteLoadState {
        appState.routeLoadState(for: currentDrive.id)
    }

    private var vehicleLabel: String {
        appState.vehicle(for: currentDrive.vehicleID)?.nickname ?? "No vehicle assigned"
    }

    private var primaryMetrics: [RoadMetricPresentation] {
        [
            RoadMetricPresentation(id: "detail-score", label: "Score", value: "\(currentDrive.scoreSummary.overall)", icon: "rosette", accent: .success),
            RoadMetricPresentation(id: "detail-distance", label: "Distance", value: RoadFormatting.distance(currentDrive.distanceMeters), icon: "arrow.left.and.right", accent: .neutral),
            RoadMetricPresentation(id: "detail-average", label: "Average speed", value: RoadFormatting.speed(currentDrive.avgSpeedKPH), icon: "gauge.with.needle", accent: .electric),
            RoadMetricPresentation(id: "detail-top", label: "Top speed", value: RoadFormatting.speed(currentDrive.topSpeedKPH), icon: "hare.fill", accent: .alert)
        ]
    }

    var body: some View {
        RoadScreenScaffold(bottomPadding: 144) {
            RoadPageHeader(
                title: currentDrive.summary.title,
                subtitle: currentDrive.summary.highlight,
                badgeText: "Score \(currentDrive.scoreSummary.overall)",
                badgeAccent: .success
            )

            routeMapSection

            RoadMetricGrid(metrics: primaryMetrics, minimumWidth: 120)

            overviewSection
            eventsSection
        }
        .navigationTitle("Drive")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            RoadBottomActionBar {
                VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                    NavigationLink("Watch Replay") {
                        RouteReplayView(drive: currentDrive)
                    }
                    .buttonStyle(RoadPrimaryButtonStyle())
                    .accessibilityIdentifier("DriveDetail.Replay")

                    Button("Share drive") {
                        showingShareComposer = true
                    }
                    .buttonStyle(RoadSubtleButtonStyle(tint: RoadTheme.info))
                    .accessibilityIdentifier("DriveDetail.Share")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(currentDrive.favorite ? "Remove saved drive" : "Save drive") {
                        Task { await appState.toggleFavorite(for: currentDrive) }
                    }

                    Button("Assign vehicle") {
                        showingVehicleAssignment = true
                    }

                    Button("Share drive") {
                        showingShareComposer = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(RoadTheme.textPrimary)
                }
            }
        }
        .confirmationDialog("Assign vehicle", isPresented: $showingVehicleAssignment, titleVisibility: .visible) {
            Button("No vehicle") {
                Task { await appState.assignVehicle(nil, to: currentDrive) }
            }

            ForEach(appState.vehicles) { vehicle in
                Button(vehicle.nickname) {
                    Task { await appState.assignVehicle(vehicle.id, to: currentDrive) }
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose the vehicle Vroom should associate with this drive.")
        }
        .navigationDestination(isPresented: $showingShareComposer) {
            ShareComposerView(drive: currentDrive, payload: sharePayload)
        }
        .task(id: drive.id) {
            await appState.ensureRouteAssets(for: drive.id)
            sharePayload = await appState.sharePayload(for: currentDrive)
        }
        .accessibilityIdentifier("DriveDetail.Screen")
    }

    @ViewBuilder
    private var routeMapSection: some View {
        switch routeState {
        case .idle, .loading:
            RouteMapStatusView(
                title: "Loading route",
                subtitle: "Fetching the saved route before showing the drive map.",
                icon: "point.3.filled.connected.trianglepath",
                showsProgress: true
            )
            .frame(height: 280)

        case .ready(let trace):
            RouteMapView(
                trace: trace,
                events: eventList,
                mode: .completed,
                cameraMode: mapCameraMode,
                style: appState.preferences.mapStyle,
                onCameraModeChange: { mapCameraMode = $0 }
            )
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: RoadRadius.large, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: RoadRadius.large, style: .continuous)
                    .strokeBorder(RoadTheme.border)
            }

        case .unavailable:
            RouteMapStatusView(
                title: "Route unavailable",
                subtitle: "This drive was saved, but the route map is not available on this device.",
                icon: "map",
                tone: .warning
            )
            .frame(height: 280)
        }
    }

    private var overviewSection: some View {
        RoadPanel {
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                RoadSectionHeader(
                    title: "Route summary",
                    subtitle: "The essentials from this drive, kept compact so the route stays primary."
                )

                RoadGroupedRows {
                    detailRow(title: "Vehicle", value: vehicleLabel, icon: "car.fill", tint: RoadTheme.info)
                    RoadRowDivider()
                    detailRow(title: "Started", value: RoadFormatting.shortDate.string(from: currentDrive.startedAt), icon: "clock.badge.checkmark", tint: RoadTheme.warning)
                    RoadRowDivider()
                    detailRow(title: "Driving events", value: "\(eventList.count)", icon: "waveform.path.ecg", tint: RoadTheme.success)
                }
            }
        }
    }

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            RoadSectionHeader(
                title: "Event timeline",
                subtitle: eventList.isEmpty
                    ? "This route finished without any recorded driving events."
                    : "\(eventList.count) event\(eventList.count == 1 ? "" : "s") were recorded in order."
            )

            if eventList.isEmpty {
                RoadStateCard(
                    title: "No events recorded",
                    message: "Nothing unusual was flagged on this route, so the replay can focus on the route itself.",
                    icon: "checkmark.circle",
                    tone: .success
                )
            } else {
                RoadGroupedRows {
                    ForEach(Array(eventList.enumerated()), id: \.element.id) { index, event in
                        eventRow(event)

                        if index < eventList.count - 1 {
                            RoadRowDivider()
                        }
                    }
                }
            }
        }
    }

    private func detailRow(title: String, value: String, icon: String, tint: Color) -> some View {
        RoadInfoRow(icon: icon, iconTint: tint, title: title, subtitle: nil) {
            Text(value)
                .font(RoadTypography.label)
                .foregroundStyle(RoadTheme.textSecondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, RoadSpacing.xSmall)
    }

    private func eventRow(_ event: DrivingEvent) -> some View {
        RoadInfoRow(
            icon: event.type.iconName,
            iconTint: accent(for: event.type),
            title: event.type.displayTitle,
            subtitle: RoadFormatting.shortDate.string(from: event.timestamp)
        ) {
            RoadCapsuleLabel(text: event.severity.displayTitle, tint: accent(for: event.type))
        }
        .padding(.vertical, RoadSpacing.xSmall)
    }

    private func accent(for type: DrivingEventType) -> Color {
        switch type {
        case .hardBrake, .gForceSpike:
            return RoadTheme.destructive
        case .hardAcceleration, .speedTrap:
            return RoadTheme.warning
        case .cornering, .speedZone:
            return RoadTheme.info
        }
    }
}
