import SwiftUI

struct RootScene: View {
    @EnvironmentObject private var appState: AppStateStore

    var body: some View {
        Group {
            if appState.isBootstrapping {
                RoadLoadingState(
                    title: "Loading your drives",
                    message: "Checking vehicles, routes, and settings."
                )
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
