import SwiftUI

struct GarageView: View {
    @EnvironmentObject private var appState: AppStateStore
    @State private var showingPaywall = false
    @State private var editingVehicle: Vehicle?
    @State private var showingVehicleEditor = false

    private var garageTitle: String {
        let name = appState.profile?.displayName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if name.isEmpty || name == "Driver" || name == "Vroom Driver" {
            return "Garage"
        }
        return name
    }

    private var summaryMetrics: [RoadMetricPresentation] {
        [
            RoadMetricPresentation(id: "garage-primary", label: "Primary vehicle", value: appState.primaryVehicle?.nickname ?? "Not set", icon: "car.fill", accent: .neutral),
            RoadMetricPresentation(id: "garage-drives", label: "Drives", value: "\(appState.drives.count)", icon: "road.lanes", accent: .electric),
            RoadMetricPresentation(id: "garage-tier", label: "Plan", value: appState.subscriptionSnapshot.tier.displayTitle, icon: appState.subscriptionSnapshot.tier.iconName, accent: .premium)
        ]
    }

    private var showsLocationRequest: Bool {
        appState.permissionState.location != .whenInUse && appState.permissionState.location != .always
    }

    private var showsMotionRequest: Bool {
        appState.permissionState.motion != .authorized
    }

    private var showsNotificationRequest: Bool {
        appState.permissionState.notifications != .authorized && appState.permissionState.notifications != .provisional
    }

    var body: some View {
        RoadScreenScaffold {
            RoadPageHeader(
                title: garageTitle,
                subtitle: "Manage vehicles, premium, preferences, permissions, and local data.",
                badgeText: appState.subscriptionSnapshot.tier.displayTitle,
                badgeAccent: appState.subscriptionSnapshot.tier == .premium ? .success : .premium
            )

            RoadPanel {
                RoadMetricGrid(metrics: summaryMetrics, minimumWidth: 120)
            }

            vehicleSection
            premiumSection
            preferencesSection
            permissionsSection
            dataSection
        }
        .task {
            await appState.refreshData()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingVehicleEditor) {
            VehicleEditorView(editingVehicle: editingVehicle)
                .environmentObject(appState)
        }
        .accessibilityIdentifier("Garage.Screen")
    }

    private var vehicleSection: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            RoadSectionHeader(
                title: "Vehicles",
                subtitle: "Add, edit, and choose the vehicles used by default.",
                actionLabel: "Add vehicle"
            ) {
                editingVehicle = nil
                showingVehicleEditor = true
            }

            if appState.vehicles.isEmpty {
                RoadEmptyState(
                    title: "No vehicles added",
                    message: "Add a vehicle to keep your drive history organized.",
                    icon: "car.fill",
                    actionLabel: "Add vehicle"
                ) {
                    editingVehicle = nil
                    showingVehicleEditor = true
                }
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 280), spacing: RoadSpacing.regular, alignment: .top)],
                    alignment: .leading,
                    spacing: RoadSpacing.regular
                ) {
                    ForEach(appState.vehicles) { vehicle in
                        Button {
                            editingVehicle = vehicle
                            showingVehicleEditor = true
                        } label: {
                            vehicleCard(for: vehicle)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("Garage.Vehicle.\(vehicle.nickname.replacingOccurrences(of: " ", with: ""))")
                    }
                }
            }
        }
    }

    private func vehicleCard(for vehicle: Vehicle) -> some View {
        let drives = appState.drives.filter { $0.vehicleID == vehicle.id }
        let averageScore = drives.isEmpty ? 0 : Double(drives.reduce(0) { $0 + $1.scoreSummary.overall }) / Double(drives.count)
        let topSpeed = drives.map(\.topSpeedKPH).max() ?? 0

        var metrics = [
            RoadMetricPresentation(id: "vehicle-drives-\(vehicle.id)", label: "Drives", value: "\(drives.count)", icon: "road.lanes", accent: .neutral)
        ]

        if !drives.isEmpty {
            metrics.append(RoadMetricPresentation(id: "vehicle-score-\(vehicle.id)", label: "Average score", value: RoadFormatting.decimal(averageScore, places: 0), icon: "rosette", accent: .success))
        }

        if topSpeed > 0 {
            metrics.append(RoadMetricPresentation(id: "vehicle-top-\(vehicle.id)", label: "Top speed", value: RoadFormatting.speed(topSpeed), icon: "hare.fill", accent: .alert))
        }

        return RoadPanel {
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                        Text(vehicle.nickname)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RoadTheme.textPrimary)

                        Text(vehicle.displayName)
                            .font(RoadTypography.caption)
                            .foregroundStyle(RoadTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    if vehicle.isPrimary {
                        RoadCapsuleLabel(text: "Primary", tint: RoadTheme.success)
                    }
                }

                if drives.isEmpty {
                    Text("No saved drives for this vehicle yet.")
                        .font(RoadTypography.supporting)
                        .foregroundStyle(RoadTheme.textSecondary)
                }

                RoadMetricGrid(metrics: metrics, minimumWidth: 120)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var premiumSection: some View {
        RoadPanel {
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                RoadSectionHeader(
                    title: "Premium",
                    subtitle: appState.subscriptionSnapshot.tier == .premium
                        ? "Premium is active on this device."
                        : "Review current plans and pricing."
                )

                RoadActionGroup(actions: [
                    RoadActionItem(id: "garage-premium") {
                        Button(appState.subscriptionSnapshot.tier == .premium ? "Manage Premium" : "Upgrade to Premium") {
                            showingPaywall = true
                        }
                        .buttonStyle(RoadPrimaryButtonStyle())
                        .accessibilityIdentifier("Garage.Premium")
                    },
                    RoadActionItem(id: "garage-restore") {
                        Button("Restore purchases") {
                            Task { await appState.restorePremium() }
                        }
                        .buttonStyle(RoadSecondaryButtonStyle())
                        .accessibilityIdentifier("Garage.Restore")
                    }
                ])
            }
        }
    }

    private var preferencesSection: some View {
        RoadPanel {
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                RoadSectionHeader(
                    title: "Preferences",
                    subtitle: "Choose how Vroom shows maps, units, and replay behavior."
                )

                RoadOptionSelector(
                    title: "Units",
                    helper: "Used for speed and distance throughout the app.",
                    selection: binding(\.units),
                    options: UnitSystem.allCases.map {
                        RoadOption(value: $0, title: $0.displayTitle, shortTitle: $0.displayTitle, icon: $0.iconName)
                    }
                )

                RoadOptionSelector(
                    title: "Map style",
                    helper: "Used on the drive screen, in History, and in replay.",
                    selection: binding(\.mapStyle),
                    options: AppMapStyle.allCases.map {
                        RoadOption(value: $0, title: $0.displayTitle, shortTitle: $0.shortTitle, icon: $0.iconName)
                    }
                )

                RoadOptionSelector(
                    title: "Battery mode",
                    helper: "Choose how aggressively Vroom prioritizes tracking.",
                    selection: binding(\.batteryMode),
                    options: BatteryMode.allCases.map {
                        RoadOption(value: $0, title: $0.displayTitle, shortTitle: $0.shortTitle, icon: $0.iconName)
                    }
                )

                RoadFormField(title: "Replay autoplay", helper: "Start replay automatically when a saved drive opens.") {
                    Toggle(isOn: Binding(get: { appState.preferences.replayAutoplay }, set: { newValue in
                        var updated = appState.preferences
                        updated.replayAutoplay = newValue
                        Task { await appState.updatePreferences(updated) }
                    })) {
                        Text(appState.preferences.replayAutoplay ? "On" : "Off")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RoadTheme.textPrimary)
                    }
                    .tint(RoadTheme.primaryAction)
                    .padding(.horizontal, RoadSpacing.regular)
                    .frame(minHeight: RoadHeight.regular)
                    .background(
                        RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                            .fill(RoadTheme.backgroundRaised)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                            .strokeBorder(RoadTheme.border)
                    }
                }
            }
        }
    }

    private var permissionsSection: some View {
        RoadPanel {
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                RoadSectionHeader(
                    title: "Permissions",
                    subtitle: "Check which permissions are available and request any that are still missing."
                )

                VStack(alignment: .leading, spacing: RoadSpacing.compact) {
                    permissionRow(title: "Location", value: appState.permissionState.location.displayTitle, icon: appState.permissionState.location.iconName)
                    permissionRow(title: "Motion", value: appState.permissionState.motion.displayTitle, icon: appState.permissionState.motion.iconName)
                    permissionRow(title: "Notifications", value: appState.permissionState.notifications.displayTitle, icon: appState.permissionState.notifications.iconName)
                }

                if showsLocationRequest || showsMotionRequest || showsNotificationRequest {
                    RoadActionGroup(actions: permissionActions)
                }
            }
        }
    }

    private var permissionActions: [RoadActionItem] {
        var actions: [RoadActionItem] = []

        if showsLocationRequest {
            actions.append(
                RoadActionItem(id: "garage-request-location") {
                    Button("Request location") {
                        Task { await appState.requestLocationPermissions() }
                    }
                    .buttonStyle(RoadSecondaryButtonStyle())
                }
            )
        }

        if showsMotionRequest {
            actions.append(
                RoadActionItem(id: "garage-request-motion") {
                    Button("Request motion") {
                        Task { await appState.requestMotionPermissions() }
                    }
                    .buttonStyle(RoadSecondaryButtonStyle())
                }
            )
        }

        if showsNotificationRequest {
            actions.append(
                RoadActionItem(id: "garage-request-notifications") {
                    Button("Request notifications") {
                        Task { await appState.requestNotificationPermissions() }
                    }
                    .buttonStyle(RoadSecondaryButtonStyle())
                }
            )
        }

        return actions
    }

    private func permissionRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: RoadSpacing.compact) {
            Image(systemName: icon)
                .foregroundStyle(RoadTheme.info)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RoadTheme.textPrimary)

            Spacer()

            Text(value)
                .font(RoadTypography.caption)
                .foregroundStyle(RoadTheme.textSecondary)
        }
        .padding(.horizontal, RoadSpacing.regular)
        .frame(minHeight: RoadHeight.regular)
        .background(
            RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                .fill(RoadTheme.backgroundRaised)
        )
        .overlay {
            RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                .strokeBorder(RoadTheme.border)
        }
    }

    private var dataSection: some View {
        RoadPanel {
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                RoadSectionHeader(
                    title: "Data",
                    subtitle: "Export or remove the data stored on this device."
                )

                RoadActionGroup(actions: [
                    RoadActionItem(id: "garage-export") {
                        Button("Export data") {
                            Task { await appState.exportLocalData() }
                        }
                        .buttonStyle(RoadPrimaryButtonStyle())
                    },
                    RoadActionItem(id: "garage-delete") {
                        Button("Delete local data", role: .destructive) {
                            Task { await appState.resetLocalData() }
                        }
                        .buttonStyle(RoadSecondaryButtonStyle())
                    }
                ])

                if let exportedURL = appState.exportedDataURL {
                    ShareLink(item: exportedURL) {
                        Label("Share export", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoadSecondaryButtonStyle())
                }
            }
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
