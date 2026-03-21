import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppStateStore
    @State private var showingPaywall = false
    @State private var editingVehicle: Vehicle?
    @State private var showingVehicleEditor = false

    var body: some View {
        List {
            Section("Subscription") {
                Button(appState.subscriptionSnapshot.tier == .premium ? "Premium Active" : "Upgrade to Premium") {
                    showingPaywall = true
                }
            }

            Section("Vehicles") {
                ForEach(appState.vehicles) { vehicle in
                    Button {
                        editingVehicle = vehicle
                        showingVehicleEditor = true
                    } label: {
                        HStack {
                            Text(vehicle.displayName)
                            Spacer()
                            if vehicle.isPrimary {
                                StatusBadge(text: "Primary", color: .orange)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                Button("Add Vehicle") {
                    editingVehicle = nil
                    showingVehicleEditor = true
                }
            }

            Section("Preferences") {
                Picker("Units", selection: binding(\.units)) {
                    ForEach(UnitSystem.allCases) { unit in
                        Text(unit.rawValue.capitalized).tag(unit)
                    }
                }
                Picker("Map Style", selection: binding(\.mapStyle)) {
                    ForEach(AppMapStyle.allCases) { style in
                        Text(style.rawValue.capitalized).tag(style)
                    }
                }
                Picker("Battery Mode", selection: binding(\.batteryMode)) {
                    ForEach(BatteryMode.allCases) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }
                Toggle("Replay Autoplay", isOn: Binding(get: { appState.preferences.replayAutoplay }, set: { newValue in
                    var updated = appState.preferences
                    updated.replayAutoplay = newValue
                    Task { await appState.updatePreferences(updated) }
                }))
            }

            Section("Permissions") {
                HStack { Text("Location") ; Spacer() ; Text(appState.permissionState.location.rawValue.capitalized).foregroundStyle(.secondary) }
                HStack { Text("Motion") ; Spacer() ; Text(appState.permissionState.motion.rawValue.capitalized).foregroundStyle(.secondary) }
                HStack { Text("Notifications") ; Spacer() ; Text(appState.permissionState.notifications.rawValue.capitalized).foregroundStyle(.secondary) }
                Button("Request Location Access") { Task { await appState.requestLocationPermissions() } }
                Button("Request Motion Access") { Task { await appState.requestMotionPermissions() } }
                Button("Request Notifications") { Task { await appState.requestNotificationPermissions() } }
            }

            Section("Privacy & Data") {
                Button("Export Local Data") {
                    Task { await appState.exportLocalData() }
                }
                if let exportedURL = appState.exportedDataURL {
                    ShareLink(item: exportedURL) {
                        Label("Share Export", systemImage: "square.and.arrow.up")
                    }
                }
                Button("Delete Local Data", role: .destructive) {
                    Task { await appState.resetLocalData() }
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingVehicleEditor) {
            VehicleEditorView(editingVehicle: editingVehicle)
                .environmentObject(appState)
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
}
