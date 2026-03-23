import SwiftUI

struct ConvoysView: View {
    @EnvironmentObject private var appState: AppStateStore

    var body: some View {
        RoadScreenScaffold(bottomPadding: 40) {
            RoadPageHeader(
                title: "Convoys preview",
                subtitle: "This build does not include live convoy rooms yet. The preview stays here so the future direction is visible without pretending the feature is active."
            )

            RoadStateCard(
                title: "What Convoys is for",
                message: "When it ships, Convoys will help nearby drivers stay coordinated without turning the Drive tab into a social dashboard.",
                icon: "person.3.fill",
                tone: .info
            )

            if appState.recentConvoys.isEmpty {
                RoadEmptyState(
                    title: "No saved rooms",
                    message: "Any room codes that were previously stored on this device will appear here.",
                    icon: "person.3.sequence"
                )
            } else {
                VStack(alignment: .leading, spacing: RoadSpacing.compact) {
                    RoadSectionHeader(
                        title: "Recent rooms",
                        subtitle: "Previously saved room codes remain visible even while live convoy syncing is unavailable."
                    )

                    RoadGroupedRows {
                        ForEach(Array(appState.recentConvoys.enumerated()), id: \.element.id) { index, convoy in
                            RoadInfoRow(
                                icon: convoy.status.iconName,
                                iconTint: RoadTheme.info,
                                title: convoy.joinCode,
                                subtitle: RoadFormatting.shortDate.string(from: convoy.createdAt)
                            ) {
                                RoadCapsuleLabel(text: convoy.status.displayTitle, tint: RoadTheme.info)
                            }
                            .padding(.vertical, RoadSpacing.xSmall)

                            if index < appState.recentConvoys.count - 1 {
                                RoadRowDivider()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Convoys")
        .navigationBarTitleDisplayMode(.inline)
    }
}
