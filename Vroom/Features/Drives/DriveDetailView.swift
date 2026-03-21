import SwiftUI

struct DriveDetailView: View {
    @EnvironmentObject private var appState: AppStateStore
    let drive: Drive

    @State private var trace: [RoutePointSample] = []
    @State private var sharePayload = SharePayload(text: "", imageURL: nil)

    private var currentDrive: Drive {
        appState.drives.first(where: { $0.id == drive.id }) ?? drive
    }

    private var metrics: [RoadMetricPresentation] {
        RoadPresentationBuilder.detailMetrics(
            drive: currentDrive,
            vehicle: appState.vehicle(for: currentDrive.vehicleID),
            eventCount: appState.events(for: currentDrive.id).count
        )
    }

    var body: some View {
        RoadScreenScaffold(bottomPadding: 40) {
            RoadPageHeader(
                title: currentDrive.summary.title,
                subtitle: currentDrive.summary.highlight,
                badgeText: "Score \(currentDrive.scoreSummary.overall)",
                badgeAccent: .success
            )

            RouteMapView(
                trace: trace,
                events: appState.events(for: drive.id),
                mode: .completed,
                style: appState.preferences.mapStyle
            )
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: RoadRadius.large, style: .continuous))

            RoadPanel {
                VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                    RoadSectionHeader(
                        title: "Summary",
                        subtitle: "Review the vehicle, pace, score, and recorded events for this drive."
                    )

                    RoadMetricGrid(metrics: metrics)
                }
            }

            eventsSection

            RoadActionGroup(actions: [
                RoadActionItem(id: "detail-replay-\(currentDrive.id)") {
                    NavigationLink {
                        RouteReplayView(drive: currentDrive)
                    } label: {
                        Label("Replay drive", systemImage: "play.circle")
                    }
                    .buttonStyle(RoadPrimaryButtonStyle())
                    .accessibilityIdentifier("DriveDetail.Replay")
                },
                RoadActionItem(id: "detail-share-\(currentDrive.id)") {
                    NavigationLink {
                        ShareComposerView(drive: currentDrive, payload: sharePayload)
                    } label: {
                        Label("Share drive", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(RoadSecondaryButtonStyle())
                    .accessibilityIdentifier("DriveDetail.Share")
                }
            ])
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await appState.toggleFavorite(for: currentDrive)
                    }
                } label: {
                    Image(systemName: currentDrive.favorite ? "star.fill" : "star")
                        .foregroundStyle(currentDrive.favorite ? RoadTheme.primaryAction : RoadTheme.textPrimary)
                }
                .accessibilityLabel(currentDrive.favorite ? "Remove saved drive" : "Save drive")
            }
        }
        .task(id: drive.id) {
            trace = await appState.loadTrace(for: drive.id)
            sharePayload = await appState.sharePayload(for: currentDrive)
        }
        .accessibilityIdentifier("DriveDetail.Screen")
    }

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            RoadSectionHeader(
                title: "Events",
                subtitle: appState.events(for: drive.id).isEmpty
                    ? "No driving events were recorded for this drive."
                    : "\(appState.events(for: drive.id).count) event\(appState.events(for: drive.id).count == 1 ? "" : "s") were recorded on this drive."
            )

            if appState.events(for: drive.id).isEmpty {
                RoadEmptyState(
                    title: "No events recorded",
                    message: "This drive did not include any saved driving events.",
                    icon: "checkmark.circle"
                )
            } else {
                ForEach(appState.events(for: drive.id)) { event in
                    RoadPanel {
                        HStack(spacing: RoadSpacing.regular) {
                            Image(systemName: event.type.iconName)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(accent(for: event.type))
                                .frame(width: RoadHeight.compact, height: RoadHeight.compact)
                                .background(
                                    RoundedRectangle(cornerRadius: RoadRadius.small, style: .continuous)
                                        .fill(accent(for: event.type).opacity(0.14))
                                )

                            VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                                Text(event.type.displayTitle)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(RoadTheme.textPrimary)

                                Text(RoadFormatting.shortDate.string(from: event.timestamp))
                                    .font(RoadTypography.caption)
                                    .foregroundStyle(RoadTheme.textMuted)
                            }

                            Spacer(minLength: 0)

                            RoadCapsuleLabel(text: event.severity.displayTitle, tint: accent(for: event.type))
                        }
                    }
                }
            }
        }
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
