import SwiftUI

struct RootScene: View {
    @EnvironmentObject private var appState: AppStateStore

    var body: some View {
        Group {
            if appState.isBootstrapping {
                ZStack {
                    RoadBackdrop()
                    VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                        ProgressView()
                            .tint(RoadTheme.primaryAction)
                        Text("Preparing Vroom")
                            .font(RoadTypography.sectionTitle)
                            .foregroundStyle(RoadTheme.textPrimary)
                        Text("Loading your drives and settings.")
                            .font(RoadTypography.supporting)
                            .foregroundStyle(RoadTheme.textSecondary)
                    }
                    .padding(RoadSpacing.large)
                    .background(
                        RoundedRectangle(cornerRadius: RoadRadius.large, style: .continuous)
                            .fill(RoadTheme.surfaceRaised)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: RoadRadius.large, style: .continuous)
                            .strokeBorder(RoadTheme.border)
                    }
                }
                .task {
                    await appState.bootstrap()
                }
            } else if appState.requiresOnboarding {
                OnboardingFlowView()
            } else {
                AppTabShellView()
            }
        }
    }
}
