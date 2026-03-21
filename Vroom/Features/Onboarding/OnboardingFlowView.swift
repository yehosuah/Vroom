import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var appState: AppStateStore
    @State private var step = 0
    @State private var displayName = ""
    @State private var units: UnitSystem = .imperial
    @State private var vehicleDraft = VehicleEditorDraft()

    private let totalSteps = 3

    private var hasLocationPermission: Bool {
        appState.permissionState.location == .whenInUse || appState.permissionState.location == .always
    }

    private var hasMotionPermission: Bool {
        appState.permissionState.motion == .authorized
    }

    private var hasNotificationPermission: Bool {
        appState.permissionState.notifications == .authorized || appState.permissionState.notifications == .provisional
    }

    var body: some View {
        ZStack {
            RoadBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: RoadSpacing.large) {
                    progressHeader

                    RouteMapView(trace: PreviewFixtures.traceSamples, events: [PreviewFixtures.event], mode: .completed, style: .imagery)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: RoadRadius.hero, style: .continuous))
                        .overlay(alignment: .topLeading) {
                            RoadCapsuleLabel(text: "Vroom", tint: RoadTheme.primaryAction, icon: "steeringwheel")
                                .padding(RoadSpacing.regular)
                        }

                    RoadHeroPanel {
                        currentStepView
                    }
                }
                .padding(.top, RoadSpacing.hero)
                .padding(.bottom, 160)
                .roadScreenPadding()
            }
        }
        .safeAreaInset(edge: .bottom) {
            RoadHeroPanel {
                controls
            }
            .padding(.horizontal, RoadSpacing.regular)
            .padding(.top, RoadSpacing.compact)
            .padding(.bottom, RoadSpacing.compact)
            .background(Color.clear)
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            HStack(spacing: RoadSpacing.small) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? RoadTheme.primaryAction : RoadTheme.disabled)
                        .frame(height: 6)
                }
            }

            Text("Step \(step + 1) of \(totalSteps)")
                .font(RoadTypography.caption.weight(.semibold))
                .foregroundStyle(RoadTheme.textSecondary)
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch step {
        case 0:
            VStack(alignment: .leading, spacing: RoadSpacing.large) {
                RoadPageHeader(
                    title: "Track your drives automatically",
                    subtitle: "Vroom records your routes, shows what happened during each drive, and keeps completed trips ready to review."
                )

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 150), spacing: RoadSpacing.compact, alignment: .top)],
                    alignment: .leading,
                    spacing: RoadSpacing.compact
                ) {
                    onboardingFeature(
                        title: "See every route",
                        detail: "Keep a clean map history of each drive.",
                        symbol: "map"
                    )
                    onboardingFeature(
                        title: "Review key moments",
                        detail: "Check speed, score, and driving events in one place.",
                        symbol: "gauge.with.needle"
                    )
                    onboardingFeature(
                        title: "Replay and share",
                        detail: "Open a finished drive again any time.",
                        symbol: "play.circle"
                    )
                }
            }

        case 1:
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                RoadPageHeader(
                    title: "Allow access Vroom needs",
                    subtitle: "Vroom only asks for the permissions used to detect drives, record routes, and notify you when a drive ends."
                )

                permissionCard(
                    title: "Location",
                    detail: "Required to detect drives and map your route.",
                    state: appState.permissionState.location.displayTitle,
                    icon: appState.permissionState.location.iconName,
                    tint: .electric,
                    buttonTitle: hasLocationPermission ? "Location allowed" : "Allow location",
                    isEnabled: !hasLocationPermission
                ) {
                    await appState.requestLocationPermissions()
                }

                permissionCard(
                    title: "Motion",
                    detail: "Helps Vroom tell driving from walking or stopping.",
                    state: appState.permissionState.motion.displayTitle,
                    icon: appState.permissionState.motion.iconName,
                    tint: .premium,
                    buttonTitle: hasMotionPermission ? "Motion allowed" : "Allow motion",
                    isEnabled: !hasMotionPermission
                ) {
                    await appState.requestMotionPermissions()
                }

                permissionCard(
                    title: "Notifications",
                    detail: "Lets Vroom notify you when a drive ends or needs attention.",
                    state: appState.permissionState.notifications.displayTitle,
                    icon: appState.permissionState.notifications.iconName,
                    tint: .success,
                    buttonTitle: hasNotificationPermission ? "Notifications allowed" : "Allow notifications",
                    isEnabled: !hasNotificationPermission
                ) {
                    await appState.requestNotificationPermissions()
                }
            }

        default:
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                RoadPageHeader(
                    title: "Set up your account",
                    subtitle: "Add the name, units, and vehicle details Vroom should use by default."
                )

                RoadTextField(
                    title: "Name",
                    helper: "Used in Garage and shared drive summaries.",
                    text: $displayName
                )

                RoadOptionSelector(
                    title: "Units",
                    helper: "Choose the units used for distance and speed.",
                    selection: $units,
                    options: UnitSystem.allCases.map {
                        RoadOption(value: $0, title: $0.displayTitle, shortTitle: $0.displayTitle, icon: $0.iconName)
                    }
                )

                Divider()
                    .overlay(RoadTheme.divider)

                RoadSectionHeader(
                    title: "Add your first vehicle",
                    subtitle: "This is optional, but it keeps your drive history organized from the start."
                )

                RoadTextField(
                    title: "Vehicle name",
                    helper: "Shown in History and Garage.",
                    text: $vehicleDraft.nickname
                )
                RoadTextField(
                    title: "Make",
                    helper: "Optional.",
                    text: $vehicleDraft.make
                )
                RoadTextField(
                    title: "Model",
                    helper: "Optional.",
                    text: $vehicleDraft.model
                )

                RoadFormField(title: "Year", helper: "Use the model year that best matches this vehicle.") {
                    Stepper(value: $vehicleDraft.year, in: 1990...Calendar.current.component(.year, from: Date()) + 1) {
                        Text("\(vehicleDraft.year)")
                            .font(.headline.weight(.semibold))
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
        }
    }

    private var controls: some View {
        RoadActionGroup(actions: controlItems, minimumWidth: 180)
    }

    private var controlItems: [RoadActionItem] {
        var items: [RoadActionItem] = []

        if step > 0 {
            items.append(
                RoadActionItem(id: "onboarding-back") {
                    Button("Back") {
                        withAnimation(RoadMotion.interactiveSpring) {
                            step -= 1
                        }
                    }
                    .buttonStyle(RoadSecondaryButtonStyle())
                }
            )
        }

        items.append(
            RoadActionItem(id: "onboarding-next") {
                Button(step == totalSteps - 1 ? "Finish setup" : "Next") {
                    Task {
                        if step < totalSteps - 1 {
                            withAnimation(RoadMotion.heroSpring) {
                                step += 1
                            }
                        } else {
                            await appState.completeOnboarding(
                                displayName: displayName,
                                avatarStyle: .atlas,
                                units: units,
                                vehicleDraft: vehicleDraft.nickname.isEmpty ? nil : vehicleDraft
                            )
                        }
                    }
                }
                .buttonStyle(RoadPrimaryButtonStyle())
            }
        )

        return items
    }

    private func onboardingFeature(title: String, detail: String, symbol: String) -> some View {
        RoadPanel(padding: RoadSpacing.regular) {
            VStack(alignment: .leading, spacing: RoadSpacing.compact) {
                Image(systemName: symbol)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RoadTheme.info)

                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RoadTheme.textPrimary)

                Text(detail)
                    .font(RoadTypography.caption)
                    .foregroundStyle(RoadTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func permissionCard(
        title: String,
        detail: String,
        state: String,
        icon: String,
        tint: RoadAccent,
        buttonTitle: String,
        isEnabled: Bool,
        action: @escaping () async -> Void
    ) -> some View {
        RoadPanel {
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                HStack(spacing: RoadSpacing.compact) {
                    Image(systemName: icon)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RoadTheme.accent(tint))
                        .frame(width: RoadHeight.compact, height: RoadHeight.compact)
                        .background(
                            RoundedRectangle(cornerRadius: RoadRadius.small, style: .continuous)
                                .fill(RoadTheme.accent(tint).opacity(0.14))
                        )

                    VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                        Text(title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RoadTheme.textPrimary)

                        Text(state)
                            .font(RoadTypography.caption)
                            .foregroundStyle(RoadTheme.textMuted)
                    }
                }

                Text(detail)
                    .font(RoadTypography.supporting)
                    .foregroundStyle(RoadTheme.textSecondary)

                Button(buttonTitle) {
                    guard isEnabled else { return }
                    Task { await action() }
                }
                .buttonStyle(isEnabled ? AnyButtonStyle(RoadSecondaryButtonStyle()) : AnyButtonStyle(RoadTertiaryButtonStyle()))
                .disabled(!isEnabled)
            }
        }
    }
}

private struct AnyButtonStyle: ButtonStyle {
    private let makeBodyClosure: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        makeBodyClosure = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        makeBodyClosure(configuration)
    }
}
