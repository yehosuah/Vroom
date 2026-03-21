import SwiftUI

struct DriveSummaryView: View {
    @EnvironmentObject private var appState: AppStateStore
    @Environment(\.dismiss) private var dismiss
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
                title: "Drive saved",
                subtitle: "Your drive is ready to review, replay, or share."
            )

            RouteMapView(
                trace: trace,
                events: appState.events(for: drive.id),
                mode: .completed,
                style: appState.preferences.mapStyle
            )
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: RoadRadius.large, style: .continuous))

            RoadPanel {
                VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                    Text(currentDrive.summary.title)
                        .font(RoadTypography.sectionTitle)
                        .foregroundStyle(RoadTheme.textPrimary)

                    Text(currentDrive.summary.highlight)
                        .font(RoadTypography.supporting)
                        .foregroundStyle(RoadTheme.textSecondary)

                    RoadMetricGrid(metrics: metrics)
                }
            }

            RoadActionGroup(actions: [
                RoadActionItem(id: "summary-detail-\(currentDrive.id)") {
                    NavigationLink {
                        DriveDetailView(drive: currentDrive)
                    } label: {
                        Label("Review drive", systemImage: "list.bullet.rectangle")
                    }
                    .buttonStyle(RoadPrimaryButtonStyle())
                },
                RoadActionItem(id: "summary-share-\(currentDrive.id)") {
                    NavigationLink {
                        ShareComposerView(drive: currentDrive, payload: sharePayload)
                    } label: {
                        Label("Share drive", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(RoadSecondaryButtonStyle())
                },
                RoadActionItem(id: "summary-done-\(currentDrive.id)") {
                    Button("Done") {
                        appState.dismissCompletedDrive()
                        dismiss()
                    }
                    .buttonStyle(RoadSecondaryButtonStyle())
                }
            ])
        }
        .navigationTitle("Drive saved")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    appState.dismissCompletedDrive()
                    dismiss()
                }
            }
        }
        .task(id: drive.id) {
            trace = await appState.loadTrace(for: drive.id)
            sharePayload = await appState.sharePayload(for: currentDrive)
        }
    }
}
