import SwiftUI

struct ConvoysView: View {
    @EnvironmentObject private var appState: AppStateStore

    var body: some View {
        RoadScreenScaffold(bottomPadding: 40) {
            RoadPageHeader(
                title: "Convoys beta",
                subtitle: "Room history is available, but live convoy syncing is still offline."
            )

            availabilitySection

            if !appState.recentConvoys.isEmpty {
                recentConvoys
            }
        }
        .navigationTitle("Convoys")
    }

    private var availabilitySection: some View {
        RoadPanel {
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                RoadSectionHeader(
                    title: "Availability",
                    subtitle: "You can still create a room code and review saved rooms, but real-time updates are not active yet."
                )

                Button("Create room") {
                    Task { await appState.createConvoy() }
                }
                .buttonStyle(RoadPrimaryButtonStyle())
            }
        }
    }

    private var recentConvoys: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            RoadSectionHeader(
                title: "Recent rooms",
                subtitle: "Saved room codes remain visible even while live syncing is unavailable."
            )

            ForEach(appState.recentConvoys) { convoy in
                RoadPanel {
                    HStack {
                        VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                            Text(convoy.joinCode)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(RoadTheme.textPrimary)

                            Text(RoadFormatting.shortDate.string(from: convoy.createdAt))
                                .font(RoadTypography.caption)
                                .foregroundStyle(RoadTheme.textMuted)
                        }

                        Spacer()

                        RoadCapsuleLabel(text: convoy.status.displayTitle, tint: RoadTheme.primaryAction, icon: convoy.status.iconName)
                    }
                }
            }
        }
    }
}
