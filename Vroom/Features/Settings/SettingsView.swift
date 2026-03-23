import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var appState: AppStateStore

    @State private var showingPaywall = false
    @State private var confirmingDeleteData = false

    private var needsLocationRequest: Bool {
        appState.permissionState.location != .always
    }

    private var locationNeedsSettingsRecovery: Bool {
        appState.permissionState.location == .denied || appState.permissionState.location == .restricted
    }

    private var needsMotionRequest: Bool {
        appState.permissionState.motion != .authorized
    }

    private var motionNeedsSettingsRecovery: Bool {
        appState.permissionState.motion == .denied || appState.permissionState.motion == .restricted
    }

    private var needsNotificationRequest: Bool {
        appState.permissionState.notifications != .authorized && appState.permissionState.notifications != .provisional
    }

    private var notificationNeedsSettingsRecovery: Bool {
        appState.permissionState.notifications == .denied
    }

    var body: some View {
        Form {
            subscriptionSection
            preferencesSection
            permissionsSection
            privacySection
            dataSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                PaywallView()
                    .environmentObject(appState)
            }
        }
        .confirmationDialog("Delete local data?", isPresented: $confirmingDeleteData, titleVisibility: .visible) {
            Button("Delete Local Data", role: .destructive) {
                Task { await appState.resetLocalData() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes saved drives, vehicles, exports, and local Vroom data from this device.")
        }
    }

    private var subscriptionSection: some View {
        Section {
            Button(appState.subscriptionSnapshot.tier == .premium ? "Premium Active" : "Upgrade to Premium") {
                showingPaywall = true
            }

            Button("Restore Purchases") {
                Task { await appState.restorePremium() }
            }
        } header: {
            Text("Subscription")
        } footer: {
            Text("Premium status lives here so Garage can stay focused on vehicles and default context.")
        }
    }

    private var preferencesSection: some View {
        Section {
            Picker("Units", selection: binding(\.units)) {
                ForEach(UnitSystem.allCases) { unit in
                    Text(unit.displayTitle).tag(unit)
                }
            }

            Picker("Map Style", selection: binding(\.mapStyle)) {
                ForEach(AppMapStyle.allCases) { style in
                    Text(style.displayTitle).tag(style)
                }
            }

            Picker("Battery Mode", selection: binding(\.batteryMode)) {
                ForEach(BatteryMode.allCases) { mode in
                    Text(mode.displayTitle).tag(mode)
                }
            }

            Toggle("Replay Autoplay", isOn: Binding(
                get: { appState.preferences.replayAutoplay },
                set: { newValue in
                    var updated = appState.preferences
                    updated.replayAutoplay = newValue
                    Task { await appState.updatePreferences(updated) }
                }
            ))
        } header: {
            Text("Preferences")
        }
    }

    private var permissionsSection: some View {
        Section {
            HStack {
                Label("Location", systemImage: appState.permissionState.location.iconName)
                Spacer()
                Text(appState.permissionState.location.displayTitle)
                    .foregroundStyle(.secondary)
            }

            if needsLocationRequest {
                Button(locationNeedsSettingsRecovery ? "Open Settings for Location" : "Request Always Location Access") {
                    if locationNeedsSettingsRecovery {
                        openSettings()
                    } else {
                        Task { await appState.requestLocationPermissions() }
                    }
                }
            }

            HStack {
                Label("Motion", systemImage: appState.permissionState.motion.iconName)
                Spacer()
                Text(appState.permissionState.motion.displayTitle)
                    .foregroundStyle(.secondary)
            }

            if needsMotionRequest {
                Button(motionNeedsSettingsRecovery ? "Open Settings for Motion" : "Request Motion Access") {
                    if motionNeedsSettingsRecovery {
                        openSettings()
                    } else {
                        Task { await appState.requestMotionPermissions() }
                    }
                }
            }

            HStack {
                Label("Notifications", systemImage: appState.permissionState.notifications.iconName)
                Spacer()
                Text(appState.permissionState.notifications.displayTitle)
                    .foregroundStyle(.secondary)
            }

            if needsNotificationRequest {
                Button(notificationNeedsSettingsRecovery ? "Open Settings for Notifications" : "Request Notifications") {
                    if notificationNeedsSettingsRecovery {
                        openSettings()
                    } else {
                        Task { await appState.requestNotificationPermissions() }
                    }
                }
            }
        } header: {
            Text("Permissions")
        } footer: {
            Text("These states live here so Drive can stay focused on readiness and action instead of long setup controls.")
        }
    }

    private var privacySection: some View {
        Section {
            Toggle("Allow local analytics", isOn: privacyBinding(\.analyticsEnabled))
            Toggle("Include precise route data in exports", isOn: privacyBinding(\.preciseExports))
            Toggle("Retain deleted data for recovery", isOn: privacyBinding(\.retainDeletedData))
        } header: {
            Text("Privacy")
        } footer: {
            Text("These controls affect only what Vroom keeps or exports on this device.")
        }
    }

    private var dataSection: some View {
        Section {
            Button("Export Local Data") {
                Task { await appState.exportLocalData() }
            }

            if let exportedURL = appState.exportedDataURL {
                ShareLink(item: exportedURL) {
                    Label("Share Export", systemImage: "square.and.arrow.up")
                }
            }

            Button("Delete Local Data", role: .destructive) {
                confirmingDeleteData = true
            }
        } header: {
            Text("Data")
        } footer: {
            Text("Export gives you a local archive. Delete removes saved Vroom data from this device.")
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<AppPreferences, Value>) -> Binding<Value> {
        Binding(
            get: { appState.preferences[keyPath: keyPath] },
            set: { newValue in
                var updated = appState.preferences
                updated[keyPath: keyPath] = newValue
                Task { await appState.updatePreferences(updated) }
            }
        )
    }

    private func privacyBinding(_ keyPath: WritableKeyPath<PrivacyOptions, Bool>) -> Binding<Bool> {
        Binding(
            get: { appState.preferences.privacyOptions[keyPath: keyPath] },
            set: { newValue in
                var updated = appState.preferences
                updated.privacyOptions[keyPath: keyPath] = newValue
                Task { await appState.updatePreferences(updated) }
            }
        )
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}
