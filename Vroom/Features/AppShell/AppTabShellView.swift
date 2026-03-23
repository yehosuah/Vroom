import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case drive
    case history
    case insights
    case garage

    var title: String {
        switch self {
        case .drive: "Drive"
        case .history: "History"
        case .insights: "Insights"
        case .garage: "Garage"
        }
    }

    var symbol: String {
        switch self {
        case .drive: "steeringwheel"
        case .history: "clock.arrow.circlepath"
        case .insights: "chart.line.uptrend.xyaxis"
        case .garage: "car.rear"
        }
    }
}

struct AppTabShellView: View {
    @State private var selection: AppTab = .drive
    @EnvironmentObject private var appState: AppStateStore

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                DriveView()
            }
            .tabItem {
                Label(AppTab.drive.title, systemImage: AppTab.drive.symbol)
            }
            .tag(AppTab.drive)

            NavigationStack {
                DriveListView()
            }
            .tabItem {
                Label(AppTab.history.title, systemImage: AppTab.history.symbol)
            }
            .tag(AppTab.history)

            NavigationStack {
                AnalyzeView()
            }
            .tabItem {
                Label(AppTab.insights.title, systemImage: AppTab.insights.symbol)
            }
            .tag(AppTab.insights)

            NavigationStack {
                GarageView()
            }
            .tabItem {
                Label(AppTab.garage.title, systemImage: AppTab.garage.symbol)
            }
            .tag(AppTab.garage)
        }
        .tint(RoadTheme.primaryAction)
        .alert("Vroom", isPresented: Binding(get: { appState.currentAlertMessage != nil }, set: { if !$0 { appState.clearAlert() } })) {
            Button("OK", role: .cancel) {
                appState.clearAlert()
            }
        } message: {
            Text(appState.currentAlertMessage ?? "")
        }
        .sheet(item: Binding(get: { appState.presentedCompletedDrive }, set: { _ in appState.dismissCompletedDrive() })) { drive in
            NavigationStack {
                DriveSummaryView(drive: drive)
                    .environmentObject(appState)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .top) {
            if let banner = appState.currentBanner {
                RoadFloatingBanner(title: banner.title, message: banner.message, tone: banner.tone)
                    .padding(.horizontal, RoadSpacing.regular)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: banner.id) {
                        try? await Task.sleep(for: .seconds(2.2))
                        guard appState.currentBanner?.id == banner.id else { return }
                        withAnimation(RoadMotion.relaxed) {
                            appState.clearBanner()
                        }
                    }
            }
        }
    }
}
