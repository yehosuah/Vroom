import SwiftUI

struct DriveSummaryView: View {
    @EnvironmentObject private var appState: AppStateStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let drive: Drive

    @State private var sharePayload = SharePayload(text: "", imageURL: nil)
    @State private var displayedScore = 0
    @State private var mapCameraMode: RouteMapCameraMode = .fitRoute

    private var currentDrive: Drive {
        appState.drives.first(where: { $0.id == drive.id }) ?? drive
    }

    private var routeState: DriveRouteLoadState {
        appState.routeLoadState(for: currentDrive.id)
    }

    private var summaryMetrics: [RoadMetricPresentation] {
        [
            RoadMetricPresentation(id: "summary-distance", label: "Distance", value: RoadFormatting.distance(currentDrive.distanceMeters), icon: "arrow.left.and.right", accent: .neutral),
            RoadMetricPresentation(id: "summary-duration", label: "Drive time", value: RoadFormatting.duration(currentDrive.duration), icon: "clock", accent: .electric),
            RoadMetricPresentation(id: "summary-top", label: "Top speed", value: RoadFormatting.speed(currentDrive.topSpeedKPH), icon: "hare.fill", accent: .alert)
        ]
    }

    var body: some View {
        RoadScreenScaffold(bottomPadding: 148) {
            RoadHeroPanel {
                VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                    HStack(alignment: .top, spacing: RoadSpacing.compact) {
                        VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                            Text("Drive saved")
                                .font(RoadTypography.sectionTitle)
                                .foregroundStyle(RoadTheme.textPrimary)

                            Text("Your route, score, and summary are ready to review whenever you want them.")
                                .font(RoadTypography.supporting)
                                .foregroundStyle(RoadTheme.textSecondary)
                        }

                        Spacer(minLength: 0)

                        RoadCapsuleLabel(text: "Saved", tint: RoadTheme.success, icon: "checkmark.circle.fill")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Final score")
                            .font(RoadTypography.meta)
                            .foregroundStyle(RoadTheme.textSecondary)

                        Text("\(displayedScore)")
                            .font(RoadTypography.heroValue)
                            .foregroundStyle(RoadTheme.textPrimary)
                            .monospacedDigit()
                    }

                    Text(currentDrive.summary.highlight)
                        .font(RoadTypography.supporting)
                        .foregroundStyle(RoadTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            routeMapSection

            RoadPanel {
                VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                    HStack(alignment: .top, spacing: RoadSpacing.compact) {
                        VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                            Text(currentDrive.summary.title)
                                .font(RoadTypography.sectionTitle)
                                .foregroundStyle(RoadTheme.textPrimary)

                            Text(RoadFormatting.shortDate.string(from: currentDrive.startedAt))
                                .font(RoadTypography.meta)
                                .foregroundStyle(RoadTheme.textSecondary)
                        }

                        Spacer(minLength: 0)

                        RoadCapsuleLabel(text: "\(appState.events(for: currentDrive.id).count) events", tint: RoadTheme.info)
                    }

                    RoadMetricGrid(metrics: summaryMetrics, minimumWidth: 120)
                }
            }
        }
        .navigationTitle("Drive saved")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            RoadBottomActionBar {
                VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                    Button("Done") {
                        appState.dismissCompletedDrive()
                        dismiss()
                    }
                    .buttonStyle(RoadPrimaryButtonStyle())

                    HStack(spacing: RoadSpacing.compact) {
                        NavigationLink("Review drive") {
                            DriveDetailView(drive: currentDrive)
                        }
                        .buttonStyle(RoadSecondaryButtonStyle())

                        NavigationLink("Share") {
                            ShareComposerView(drive: currentDrive, payload: sharePayload)
                        }
                        .buttonStyle(RoadSecondaryButtonStyle())
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    appState.dismissCompletedDrive()
                    dismiss()
                }
            }
        }
        .task(id: drive.id) {
            await appState.ensureRouteAssets(for: drive.id)
            sharePayload = await appState.sharePayload(for: currentDrive)
            await animateScore()
        }
    }

    @ViewBuilder
    private var routeMapSection: some View {
        switch routeState {
        case .idle, .loading:
            RouteMapStatusView(
                title: "Loading route",
                subtitle: "Preparing the route so the saved drive opens with context.",
                icon: "point.3.filled.connected.trianglepath",
                showsProgress: true
            )
            .frame(height: 220)

        case .ready(let trace):
            RouteMapView(
                trace: trace,
                events: appState.events(for: drive.id),
                mode: .completed,
                cameraMode: mapCameraMode,
                style: appState.preferences.mapStyle,
                onCameraModeChange: { mapCameraMode = $0 }
            )
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: RoadRadius.large, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: RoadRadius.large, style: .continuous)
                    .strokeBorder(RoadTheme.border)
            }

        case .unavailable:
            RouteMapStatusView(
                title: "Route unavailable",
                subtitle: "This drive was saved, but the route preview is not available on this device.",
                icon: "map",
                tone: .warning
            )
            .frame(height: 220)
        }
    }

    private func animateScore() async {
        let finalScore = currentDrive.scoreSummary.overall
        if reduceMotion {
            displayedScore = finalScore
            return
        }

        displayedScore = 0
        let stepCount = max(1, min(finalScore, 18))
        let increment = max(1, finalScore / stepCount)

        for value in stride(from: 0, through: finalScore, by: increment) {
            displayedScore = min(value, finalScore)
            try? await Task.sleep(for: .milliseconds(24))
        }

        displayedScore = finalScore
    }
}
