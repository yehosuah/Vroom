import SwiftUI

struct GarageView: View {
    @EnvironmentObject private var appState: AppStateStore

    @State private var showingPaywall = false
    @State private var editingVehicle: Vehicle?
    @State private var showingVehicleEditor = false

    private var displayName: String {
        let name = appState.profile?.displayName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if name.isEmpty || name == "Driver" || name == "Vroom Driver" {
            return "Garage"
        }
        return name
    }

    private var readinessMessage: (title: String, message: String, tone: RoadStateTone, icon: String)? {
        if appState.vehicles.isEmpty {
            return (
                "Add a vehicle before the next drive",
                "Garage is ready, but a default vehicle will make history and drive details more coherent from the start.",
                .info,
                "car.fill"
            )
        }

        let locationReady = appState.permissionState.location == .always
        let motionReady = appState.permissionState.motion == .authorized
        let notificationsReady = appState.permissionState.notifications == .authorized || appState.permissionState.notifications == .provisional

        if !locationReady || !motionReady || !notificationsReady {
            return (
                "Settings still need attention",
                "Finish permissions in Settings so the next drive records more reliably and Vroom can confirm what happened after it ends.",
                .warning,
                "gearshape"
            )
        }

        return nil
    }

    var body: some View {
        RoadScreenScaffold(bottomPadding: 40) {
            profileSection

            if let readinessMessage {
                RoadStateCard(
                    title: readinessMessage.title,
                    message: readinessMessage.message,
                    icon: readinessMessage.icon,
                    tone: readinessMessage.tone
                )
            }

            manageSection
            premiumSection
            vehicleSection
        }
        .navigationTitle("Garage")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await appState.refreshData()
        }
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                PaywallView()
                    .environmentObject(appState)
            }
        }
        .sheet(isPresented: $showingVehicleEditor) {
            VehicleEditorView(editingVehicle: editingVehicle)
                .environmentObject(appState)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(RoadTheme.textPrimary)
                }
            }
        }
        .accessibilityIdentifier("Garage.Screen")
    }

    private var profileSection: some View {
        RoadHeroPanel {
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                HStack(alignment: .top, spacing: RoadSpacing.compact) {
                    VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                        Text(displayName)
                            .font(RoadTypography.sectionTitle)
                            .foregroundStyle(RoadTheme.textPrimary)

                        Text("Vehicles, plan status, and the defaults Vroom should remember.")
                            .font(RoadTypography.supporting)
                            .foregroundStyle(RoadTheme.textSecondary)
                    }

                    Spacer(minLength: 0)

                    RoadCapsuleLabel(
                        text: appState.subscriptionSnapshot.tier.displayTitle,
                        tint: appState.subscriptionSnapshot.tier == .premium ? RoadTheme.success : RoadTheme.primaryAction,
                        icon: appState.subscriptionSnapshot.tier.iconName
                    )
                }

                HStack(spacing: RoadSpacing.compact) {
                    profileStat(title: "Vehicles", value: "\(appState.vehicles.count)")
                    profileStat(title: "Drives", value: "\(appState.drives.count)")
                    profileStat(title: "Default", value: appState.primaryVehicle?.nickname ?? "None")
                }
            }
        }
    }

    private var manageSection: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            RoadSectionHeader(
                title: "Manage",
                subtitle: "Open the surfaces that should stay available, but not constantly compete with vehicle management."
            )

            RoadGroupedRows {
                NavigationLink {
                    SettingsView()
                } label: {
                    RoadNavigationRow(
                        icon: "gearshape.fill",
                        iconTint: RoadTheme.info,
                        title: "Settings and privacy",
                        subtitle: "Preferences, permissions, export, and local data controls."
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var premiumSection: some View {
        RoadPanel {
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                RoadSectionHeader(
                    title: appState.subscriptionSnapshot.tier == .premium ? "Premium is active" : "Vroom Premium",
                    subtitle: appState.subscriptionSnapshot.tier == .premium
                        ? "Premium is active on this device and ready wherever deeper insight appears."
                        : "Upgrade when you want deeper insight surfaces and future premium capabilities."
                )

                RoadActionGroup(actions: [
                    RoadActionItem(id: "garage-premium") {
                        Button(appState.subscriptionSnapshot.tier == .premium ? "Manage Premium" : "See Premium Plans") {
                            showingPaywall = true
                        }
                        .buttonStyle(RoadPrimaryButtonStyle())
                        .accessibilityIdentifier("Garage.Premium")
                    },
                    RoadActionItem(id: "garage-restore") {
                        Button("Restore Purchases") {
                            Task { await appState.restorePremium() }
                        }
                        .buttonStyle(RoadSecondaryButtonStyle())
                    }
                ])
            }
        }
    }

    private var vehicleSection: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            RoadSectionHeader(
                title: "Vehicles",
                subtitle: "Add, edit, and choose the default vehicle for new drives.",
                actionLabel: "Add Vehicle"
            ) {
                editingVehicle = nil
                showingVehicleEditor = true
            }

            if appState.vehicles.isEmpty {
                RoadEmptyState(
                    title: "No vehicles added",
                    message: "Add a vehicle so new drives land in history with clearer context from the start.",
                    icon: "car.fill",
                    actionLabel: "Add Vehicle"
                ) {
                    editingVehicle = nil
                    showingVehicleEditor = true
                }
            } else {
                RoadGroupedRows {
                    ForEach(Array(appState.vehicles.enumerated()), id: \.element.id) { index, vehicle in
                        Button {
                            editingVehicle = vehicle
                            showingVehicleEditor = true
                        } label: {
                            vehicleRow(vehicle)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("Garage.Vehicle.\(vehicle.nickname.replacingOccurrences(of: " ", with: ""))")

                        if index < appState.vehicles.count - 1 {
                            RoadRowDivider()
                        }
                    }
                }
            }
        }
    }

    private func vehicleRow(_ vehicle: Vehicle) -> some View {
        let drives = appState.drives.filter { $0.vehicleID == vehicle.id }
        let averageScore = drives.isEmpty ? 0 : Double(drives.reduce(0) { $0 + $1.scoreSummary.overall }) / Double(drives.count)

        return HStack(alignment: .top, spacing: RoadSpacing.compact) {
            VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                HStack(spacing: RoadSpacing.small) {
                    Text(vehicle.nickname)
                        .font(RoadTypography.label)
                        .foregroundStyle(RoadTheme.textPrimary)

                    if vehicle.isPrimary {
                        RoadCapsuleLabel(text: "Default", tint: RoadTheme.success)
                    }
                }

                Text(vehicle.displayName)
                    .font(RoadTypography.meta)
                    .foregroundStyle(RoadTheme.textSecondary)
                    .lineLimit(1)

                Text(drives.isEmpty ? "No saved drives yet" : "\(drives.count) drives • Avg score \(RoadFormatting.decimal(averageScore, places: 0))")
                    .font(RoadTypography.caption)
                    .foregroundStyle(RoadTheme.textMuted)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RoadTheme.textMuted)
                .padding(.top, 4)
        }
        .padding(.vertical, RoadSpacing.small)
    }

    private func profileStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(RoadTypography.caption)
                .foregroundStyle(RoadTheme.textMuted)

            Text(value)
                .font(RoadTypography.label)
                .foregroundStyle(RoadTheme.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RoadSpacing.compact)
        .background(
            RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                .fill(RoadTheme.backgroundRaised)
        )
    }
}
