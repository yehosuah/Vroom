import SwiftUI

enum RoadTheme {
    static let background = Color(red: 0.08, green: 0.09, blue: 0.11)
    static let backgroundRaised = Color(red: 0.11, green: 0.12, blue: 0.15)
    static let surface = Color(red: 0.14, green: 0.15, blue: 0.18)
    static let surfaceRaised = Color(red: 0.17, green: 0.18, blue: 0.22)
    static let border = Color.white.opacity(0.08)
    static let divider = Color.white.opacity(0.08)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.74)
    static let textMuted = Color.white.opacity(0.56)
    static let primaryAction = Color(red: 0.96, green: 0.69, blue: 0.25)
    static let secondaryAction = Color.white.opacity(0.08)
    static let success = Color(red: 0.29, green: 0.76, blue: 0.52)
    static let warning = Color(red: 0.96, green: 0.55, blue: 0.29)
    static let destructive = Color(red: 0.92, green: 0.35, blue: 0.31)
    static let info = Color(red: 0.41, green: 0.67, blue: 0.97)
    static let disabled = Color.white.opacity(0.14)
    static let selected = Color.white.opacity(0.12)
    static let shadow = Color.black.opacity(0.18)
    static let mapScrimTop = Color.black.opacity(0.34)
    static let mapScrimBottom = Color.black.opacity(0.72)

    // Compatibility aliases for older surfaces that still read these names.
    static let graphite = background
    static let carbon = backgroundRaised
    static let obsidian = background
    static let fog = textMuted
    static let porcelain = textPrimary
    static let signalAmber = primaryAction
    static let amberGlow = primaryAction
    static let liveGreen = success
    static let warningRed = destructive
    static let electricBlue = info
    static let lavenderMist = info.opacity(0.8)

    static let baseGradient = LinearGradient(
        colors: [backgroundRaised, background],
        startPoint: .top,
        endPoint: .bottom
    )

    static func accent(_ accent: RoadAccent) -> Color {
        switch accent {
        case .neutral:
            return textPrimary
        case .electric:
            return info
        case .alert:
            return warning
        case .success:
            return success
        case .premium:
            return primaryAction
        }
    }
}

enum RoadSpacing {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let compact: CGFloat = 12
    static let regular: CGFloat = 16
    static let roomy: CGFloat = 24
    static let large: CGFloat = 24
    static let xLarge: CGFloat = 32
    static let hero: CGFloat = 40
}

enum RoadRadius {
    static let small: CGFloat = 12
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let hero: CGFloat = 24
}

enum RoadHeight {
    static let compact: CGFloat = 44
    static let regular: CGFloat = 52
    static let large: CGFloat = 64
}

enum RoadTypography {
    static let screenTitle = Font.system(size: 30, weight: .bold)
    static let sectionTitle = Font.system(size: 22, weight: .semibold)
    static let body = Font.body
    static let supporting = Font.callout
    static let label = Font.footnote.weight(.semibold)
    static let caption = Font.caption
    static let metric = Font.system(size: 24, weight: .semibold)
}

enum RoadMotion {
    static let interactiveSpring = Animation.spring(response: 0.4, dampingFraction: 0.88)
    static let heroSpring = Animation.spring(response: 0.56, dampingFraction: 0.9)
    static let relaxed = Animation.easeInOut(duration: 0.25)
}

struct RoadBackdrop: View {
    var body: some View {
        ZStack {
            RoadTheme.baseGradient

            Circle()
                .fill(RoadTheme.info.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: -120, y: -220)

            Circle()
                .fill(RoadTheme.primaryAction.opacity(0.08))
                .frame(width: 220, height: 220)
                .blur(radius: 70)
                .offset(x: 140, y: -260)
        }
        .ignoresSafeArea()
    }
}

struct RoadPanel<Content: View>: View {
    let padding: CGFloat
    let content: Content

    init(padding: CGFloat = RoadSpacing.large, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: RoadRadius.large, style: .continuous)
                    .fill(RoadTheme.surface)
            )
            .overlay {
                RoundedRectangle(cornerRadius: RoadRadius.large, style: .continuous)
                    .strokeBorder(RoadTheme.border)
            }
    }
}

struct RoadHeroPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
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
}

struct RoadSectionHeader: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?
    var action: (() -> Void)?
    var actionLabel: String?

    init(eyebrow: String? = nil, title: String, subtitle: String? = nil, actionLabel: String? = nil, action: (() -> Void)? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionLabel = actionLabel
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: RoadSpacing.regular) {
                copyBlock
                Spacer(minLength: RoadSpacing.regular)
                headerAction
            }

            VStack(alignment: .leading, spacing: RoadSpacing.compact) {
                copyBlock
                headerAction
            }
        }
    }

    private var copyBlock: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.small) {
            if let eyebrow {
                Text(eyebrow)
                    .font(RoadTypography.caption)
                    .foregroundStyle(RoadTheme.textMuted)
            }

            Text(title)
                .font(RoadTypography.sectionTitle)
                .foregroundStyle(RoadTheme.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(RoadTypography.supporting)
                    .foregroundStyle(RoadTheme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var headerAction: some View {
        if let actionLabel, let action {
            Button(actionLabel, action: action)
                .buttonStyle(RoadTertiaryButtonStyle())
        }
    }
}

struct RoadCapsuleLabel: View {
    let text: String
    var tint: Color = RoadTheme.info
    var icon: String?

    var body: some View {
        HStack(spacing: RoadSpacing.small) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
            }

            Text(text)
                .font(RoadTypography.caption.weight(.semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, RoadSpacing.compact)
        .padding(.vertical, RoadSpacing.small)
        .background(tint.opacity(0.14), in: Capsule())
    }
}

struct RoadPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .foregroundStyle(RoadTheme.background)
            .frame(maxWidth: .infinity)
            .frame(minHeight: RoadHeight.regular)
            .padding(.horizontal, RoadSpacing.regular)
            .background(
                RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                    .fill(RoadTheme.primaryAction.opacity(configuration.isPressed ? 0.9 : 1))
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(RoadMotion.relaxed, value: configuration.isPressed)
    }
}

struct RoadSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .foregroundStyle(RoadTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: RoadHeight.regular)
            .padding(.horizontal, RoadSpacing.regular)
            .background(
                RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                    .fill(RoadTheme.secondaryAction.opacity(configuration.isPressed ? 0.8 : 1))
            )
            .overlay {
                RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                    .strokeBorder(RoadTheme.border)
            }
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(RoadMotion.relaxed, value: configuration.isPressed)
    }
}

struct RoadTertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(RoadTheme.textPrimary.opacity(configuration.isPressed ? 0.7 : 0.9))
            .padding(.horizontal, RoadSpacing.compact)
            .padding(.vertical, RoadSpacing.small)
            .background(
                RoundedRectangle(cornerRadius: RoadRadius.small, style: .continuous)
                    .fill(RoadTheme.secondaryAction.opacity(configuration.isPressed ? 0.8 : 1))
            )
            .animation(RoadMotion.relaxed, value: configuration.isPressed)
    }
}

struct RoadStatPill: View {
    let label: String
    let value: String
    var tint: Color = .white

    var body: some View {
        RoadMetricChip(
            metric: RoadMetricPresentation(
                id: label,
                label: label,
                value: value,
                icon: "circle.fill",
                accent: .neutral
            )
        )
    }
}

struct RoadMetricRail: View {
    let metrics: [RoadMetricPresentation]

    var body: some View {
        RoadMetricGrid(metrics: metrics)
    }
}

struct RoadStatusBadge: View {
    let text: String
    let accent: RoadAccent

    var body: some View {
        Text(text)
            .font(RoadTypography.caption.weight(.semibold))
            .foregroundStyle(RoadTheme.accent(accent))
            .padding(.horizontal, RoadSpacing.compact)
            .padding(.vertical, RoadSpacing.small)
            .background(RoadTheme.accent(accent).opacity(0.14), in: Capsule())
    }
}

extension View {
    func roadScreenPadding() -> some View {
        frame(maxWidth: 960, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, RoadSpacing.regular)
    }
}
