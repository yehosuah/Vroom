import SwiftUI
import UIKit

struct OnboardingFlowView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var appState: AppStateStore

    @State private var step = 0
    @State private var displayName = ""
    @State private var units: UnitSystem = .imperial
    @State private var vehicleDraft = VehicleEditorDraft()
    @State private var showsVehicleSetup = false

    private let totalSteps = 3

    private var hasLocationPermission: Bool {
        appState.permissionState.location == .always
    }

    private var hasMotionPermission: Bool {
        appState.permissionState.motion == .authorized
    }

    private var hasNotificationPermission: Bool {
        appState.permissionState.notifications == .authorized || appState.permissionState.notifications == .provisional
    }

    private var hasDeniedPermission: Bool {
        let locationDenied = appState.permissionState.location == .denied || appState.permissionState.location == .restricted
        let motionDenied = appState.permissionState.motion == .denied || appState.permissionState.motion == .restricted
        let notificationsDenied = appState.permissionState.notifications == .denied
        return locationDenied || motionDenied || notificationsDenied
    }

    private var permissionItems: [RoadReadinessItem] {
        [
            RoadReadinessItem(
                id: "onboarding-location",
                icon: appState.permissionState.location.iconName,
                title: "Location",
                message: "Needed to detect a drive and keep the route recording after you leave the app.",
                status: appState.permissionState.location.displayTitle,
                tone: hasLocationPermission ? .success : (hasDeniedPermission ? .warning : .info)
            ),
            RoadReadinessItem(
                id: "onboarding-motion",
                icon: appState.permissionState.motion.iconName,
                title: "Motion",
                message: "Helps Vroom tell the difference between driving, walking, and waiting.",
                status: appState.permissionState.motion.displayTitle,
                tone: hasMotionPermission ? .success : (hasDeniedPermission ? .warning : .info)
            ),
            RoadReadinessItem(
                id: "onboarding-notifications",
                icon: appState.permissionState.notifications.iconName,
                title: "Notifications",
                message: "Lets Vroom confirm when a drive ends or when something needs your attention.",
                status: appState.permissionState.notifications.displayTitle,
                tone: hasNotificationPermission ? .success : (hasDeniedPermission ? .warning : .info)
            )
        ]
    }

    private var permissionPrimaryTitle: String {
        if hasDeniedPermission {
            return "Open Settings"
        }
        if !hasLocationPermission {
            return "Enable Location"
        }
        if !hasMotionPermission {
            return "Enable Motion"
        }
        if !hasNotificationPermission {
            return "Enable Notifications"
        }
        return "Continue"
    }

    var body: some View {
        ZStack {
            RoadBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: RoadSpacing.roomy) {
                    progressHeader

                    RouteMapView(
                        trace: PreviewFixtures.traceSamples,
                        events: [PreviewFixtures.event],
                        mode: .completed,
                        cameraMode: .fitRoute,
                        style: .imagery
                    )
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: RoadRadius.hero, style: .continuous))
                    .overlay {
                        LinearGradient(
                            colors: [RoadTheme.mapScrimTop, .clear, RoadTheme.mapScrimBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .overlay(alignment: .topLeading) {
                        RoadCapsuleLabel(text: "Vroom", tint: RoadTheme.primaryAction, icon: "steeringwheel")
                            .padding(RoadSpacing.regular)
                    }
                    .offset(y: reduceMotion ? 0 : CGFloat(step) * -2)
                    .animation(reduceMotion ? nil : RoadMotion.heroSpring, value: step)
                    .accessibilityHidden(true)

                    currentStepCard
                }
                .padding(.top, RoadSpacing.hero)
                .padding(.bottom, 148)
                .roadScreenPadding()
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            RoadBottomActionBar {
                RoadActionGroup(actions: footerActions, minimumWidth: 180)
            }
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            HStack(spacing: RoadSpacing.small) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? RoadTheme.primaryAction : RoadTheme.secondaryAction)
                        .frame(height: 6)
                }
            }

            Text("Step \(step + 1) of \(totalSteps)")
                .font(RoadTypography.caption.weight(.semibold))
                .foregroundStyle(RoadTheme.textSecondary)
        }
    }

    private var currentStepCard: some View {
        RoadHeroPanel {
            VStack(alignment: .leading, spacing: RoadSpacing.roomy) {
                switch step {
                case 0:
                    welcomeStep
                case 1:
                    permissionsStep
                default:
                    setupStep
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.roomy) {
            RoadPageHeader(
                title: "Track the next drive with confidence",
                subtitle: "Vroom is built to capture the route, show what mattered, and make the payoff easy to revisit."
            )

            RoadStateCard(
                title: "First value happens on your first saved drive",
                message: "You do not need to learn the whole app up front. The goal of setup is simple: be ready to record one complete route.",
                icon: "flag.pattern.checkered",
                tone: .success
            )

            VStack(alignment: .leading, spacing: RoadSpacing.small) {
                RoadInfoRow(icon: "map.fill", iconTint: RoadTheme.info, title: "Reopen any route later", subtitle: "Your drive history stays easy to scan and easy to return to.") {
                    RoadCapsuleLabel(text: "History", tint: RoadTheme.info)
                }

                RoadRowDivider()

                RoadInfoRow(icon: "gauge.with.needle", iconTint: RoadTheme.primaryAction, title: "See the moments that mattered", subtitle: "Score, pace, and driving events are prepared after each drive.") {
                    RoadCapsuleLabel(text: "Review", tint: RoadTheme.primaryAction)
                }

                RoadRowDivider()

                RoadInfoRow(icon: "play.circle.fill", iconTint: RoadTheme.success, title: "Replay or share when you want", subtitle: "The route stays available after the drive instead of disappearing into a generic summary.") {
                    RoadCapsuleLabel(text: "Replay", tint: RoadTheme.success)
                }
            }
        }
    }

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.roomy) {
            RoadPageHeader(
                title: "Turn on what Vroom needs",
                subtitle: "These permissions exist to protect the first saved drive from feeling incomplete or unreliable."
            )

            RoadReadinessChecklist(
                title: "Drive tracking checklist",
                subtitle: hasDeniedPermission
                    ? "At least one permission was denied. Open Settings to finish setup."
                    : "Enable each item in order so the next drive is ready to record cleanly.",
                items: permissionItems
            )

            RoadStateCard(
                title: "What changes after this step",
                message: "Once these are enabled, the Drive tab becomes a readiness surface instead of a permission reminder.",
                icon: "checkmark.shield",
                tone: readinessTone
            )
        }
    }

    private var readinessTone: RoadStateTone {
        if hasLocationPermission && hasMotionPermission && hasNotificationPermission {
            return .success
        }
        return hasDeniedPermission ? .warning : .info
    }

    private var setupStep: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.roomy) {
            RoadPageHeader(
                title: "Finish the details Vroom should remember",
                subtitle: "This keeps Garage, summaries, and new drives grounded in your defaults from the start."
            )

            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                RoadTextField(
                    title: "Your name",
                    helper: "Optional. Leave blank if you want to keep the default local profile name.",
                    text: $displayName
                )

                RoadOptionSelector(
                    title: "Units",
                    helper: "Used for distance and speed throughout the app.",
                    selection: $units,
                    options: UnitSystem.allCases.map {
                        RoadOption(value: $0, title: $0.displayTitle, shortTitle: $0.displayTitle, icon: $0.iconName)
                    }
                )
            }

            DisclosureGroup(isExpanded: $showsVehicleSetup) {
                VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                    RoadTextField(
                        title: "Vehicle name",
                        helper: "This is the label you will see in History, Garage, and drive details.",
                        text: $vehicleDraft.nickname
                    )

                    RoadTextField(title: "Make", helper: "Optional.", text: $vehicleDraft.make)
                    RoadTextField(title: "Model", helper: "Optional.", text: $vehicleDraft.model)

                    RoadFormField(title: "Year", helper: "Use the model year that best matches this vehicle.") {
                        Stepper(value: $vehicleDraft.year, in: 1990...Calendar.current.component(.year, from: Date()) + 1) {
                            Text("\(vehicleDraft.year)")
                                .font(RoadTypography.label)
                                .foregroundStyle(RoadTheme.textPrimary)
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
                        .tint(RoadTheme.primaryAction)
                    }
                }
                .padding(.top, RoadSpacing.regular)
            } label: {
                VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                    Text("Add a default vehicle")
                        .font(RoadTypography.label)
                        .foregroundStyle(RoadTheme.textPrimary)

                    Text("Optional, but useful if you want your first saved drives organized from the start.")
                        .font(RoadTypography.meta)
                        .foregroundStyle(RoadTheme.textSecondary)
                }
            }
            .tint(RoadTheme.textPrimary)

            RoadStateCard(
                title: "You’re almost ready to record your first drive",
                message: "Finish setup and Vroom will drop you into the Drive tab with the app focused on the next meaningful action: start driving.",
                icon: "steeringwheel",
                tone: .success
            )
        }
    }

    private var footerActions: [RoadActionItem] {
        var actions: [RoadActionItem] = []

        if step > 0 {
            actions.append(
                RoadActionItem(id: "onboarding-back") {
                    Button("Back") {
                        withAnimation(reduceMotion ? nil : RoadMotion.interactiveSpring) {
                            step -= 1
                        }
                    }
                    .buttonStyle(RoadSecondaryButtonStyle())
                }
            )
        }

        actions.append(
            RoadActionItem(id: "onboarding-primary") {
                Button(primaryButtonTitle) {
                    Task { await handlePrimaryAction() }
                }
                .buttonStyle(RoadPrimaryButtonStyle())
            }
        )

        return actions
    }

    private var primaryButtonTitle: String {
        switch step {
        case 0:
            return "Continue"
        case 1:
            return permissionPrimaryTitle
        default:
            return "Finish and Open Drive"
        }
    }

    private func handlePrimaryAction() async {
        if step == 0 {
            withAnimation(reduceMotion ? nil : RoadMotion.heroSpring) {
                step = 1
            }
            return
        }

        if step == 1 {
            if hasDeniedPermission {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
                return
            }

            if !hasLocationPermission {
                await appState.requestLocationPermissions()
                return
            }

            if !hasMotionPermission {
                await appState.requestMotionPermissions()
                return
            }

            if !hasNotificationPermission {
                await appState.requestNotificationPermissions()
                return
            }

            withAnimation(reduceMotion ? nil : RoadMotion.heroSpring) {
                step = 2
            }
            return
        }

        await appState.completeOnboarding(
            displayName: displayName,
            avatarStyle: .atlas,
            units: units,
            vehicleDraft: showsVehicleSetup && !vehicleDraft.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? vehicleDraft : nil
        )
    }
}
