import SwiftUI
import UIKit

private extension Color {
    static func roadDynamic(light: UIColor, dark: UIColor) -> Color {
        Color(
            uiColor: UIColor { trait in
                trait.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
}

enum RoadTheme {
    static let background = Color(uiColor: .systemGroupedBackground)
    static let backgroundRaised = Color(uiColor: .secondarySystemGroupedBackground)
    static let backgroundMuted = Color(uiColor: .tertiarySystemGroupedBackground)
    static let surface = Color.roadDynamic(
        light: UIColor(red: 0.99, green: 0.99, blue: 1.00, alpha: 1.0),
        dark: UIColor(red: 0.12, green: 0.13, blue: 0.16, alpha: 1.0)
    )
    static let surfaceRaised = Color.roadDynamic(
        light: UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0),
        dark: UIColor(red: 0.16, green: 0.17, blue: 0.21, alpha: 1.0)
    )
    static let border = Color(uiColor: .separator).opacity(0.22)
    static let divider = Color(uiColor: .separator).opacity(0.14)
    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textMuted = Color(uiColor: .tertiaryLabel)
    static let primaryAction = Color.roadDynamic(
        light: UIColor(red: 0.86, green: 0.50, blue: 0.14, alpha: 1.0),
        dark: UIColor(red: 0.96, green: 0.70, blue: 0.25, alpha: 1.0)
    )
    static let primaryActionPressed = Color.roadDynamic(
        light: UIColor(red: 0.78, green: 0.45, blue: 0.13, alpha: 1.0),
        dark: UIColor(red: 0.90, green: 0.64, blue: 0.22, alpha: 1.0)
    )
    static let secondaryAction = Color(uiColor: .tertiarySystemFill)
    static let success = Color.roadDynamic(
        light: UIColor(red: 0.16, green: 0.60, blue: 0.33, alpha: 1.0),
        dark: UIColor(red: 0.33, green: 0.79, blue: 0.52, alpha: 1.0)
    )
    static let warning = Color.roadDynamic(
        light: UIColor(red: 0.84, green: 0.47, blue: 0.14, alpha: 1.0),
        dark: UIColor(red: 0.98, green: 0.60, blue: 0.24, alpha: 1.0)
    )
    static let destructive = Color(uiColor: .systemRed)
    static let info = Color(uiColor: .systemBlue)
    static let premium = Color.roadDynamic(
        light: UIColor(red: 0.71, green: 0.47, blue: 0.14, alpha: 1.0),
        dark: UIColor(red: 0.97, green: 0.74, blue: 0.30, alpha: 1.0)
    )
    static let disabled = Color(uiColor: .quaternaryLabel)
    static let selected = primaryAction.opacity(0.10)
    static let primaryFill = primaryAction.opacity(0.14)
    static let successFill = success.opacity(0.14)
    static let warningFill = warning.opacity(0.14)
    static let destructiveFill = destructive.opacity(0.12)
    static let infoFill = info.opacity(0.14)
    static let shadow = Color.black.opacity(0.12)
    static let mapScrimTop = Color.black.opacity(0.10)
    static let mapScrimBottom = Color.black.opacity(0.34)
    static let heroGradient = LinearGradient(
        colors: [
            Color.roadDynamic(
                light: UIColor(red: 1.00, green: 0.97, blue: 0.92, alpha: 1.0),
                dark: UIColor(red: 0.23, green: 0.18, blue: 0.12, alpha: 1.0)
            ),
            surfaceRaised
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let baseGradient = LinearGradient(
        colors: [backgroundRaised, background],
        startPoint: .top,
        endPoint: .bottom
    )

    // Compatibility aliases retained while feature surfaces migrate.
    static let graphite = background
    static let carbon = backgroundRaised
    static let obsidian = background
    static let fog = textMuted
    static let porcelain = textPrimary
    static let signalAmber = primaryAction
    static let amberGlow = premium
    static let liveGreen = success
    static let warningRed = destructive
    static let electricBlue = info
    static let lavenderMist = info.opacity(0.82)

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
            return premium
        }
    }
}

enum RoadSpacing {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let compact: CGFloat = 12
    static let regular: CGFloat = 16
    static let medium: CGFloat = 20
    static let roomy: CGFloat = 24
    static let large: CGFloat = 24
    static let xLarge: CGFloat = 32
    static let hero: CGFloat = 40
}

enum RoadRadius {
    static let small: CGFloat = 12
    static let medium: CGFloat = 16
    static let large: CGFloat = 20
    static let hero: CGFloat = 24
}

enum RoadHeight {
    static let compact: CGFloat = 44
    static let regular: CGFloat = 52
    static let large: CGFloat = 64
}

enum RoadTypography {
    static let screenTitle = Font.largeTitle.weight(.bold)
    static let sectionTitle = Font.title3.weight(.semibold)
    static let body = Font.body
    static let supporting = Font.callout
    static let label = Font.subheadline.weight(.semibold)
    static let meta = Font.footnote
    static let caption = Font.caption
    static let metric = Font.title2.weight(.semibold)
    static let heroValue = Font.system(.largeTitle, design: .rounded).weight(.bold)
}

enum RoadMotion {
    static let interactiveSpring = Animation.spring(response: 0.28, dampingFraction: 0.88)
    static let heroSpring = Animation.spring(response: 0.38, dampingFraction: 0.88)
    static let relaxed = Animation.easeInOut(duration: 0.12)
}

private extension View {
    func roadCardBackground(fill: AnyShapeStyle, radius: CGFloat, shadowOpacity: Double) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(fill)
                .shadow(color: RoadTheme.shadow.opacity(shadowOpacity), radius: 18, x: 0, y: 10)
        )
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(RoadTheme.border)
        }
    }
}

struct RoadBackdrop: View {
    var body: some View {
        ZStack {
            RoadTheme.baseGradient

            Circle()
                .fill(RoadTheme.info.opacity(0.10))
                .frame(width: 240, height: 240)
                .blur(radius: 72)
                .offset(x: -120, y: -260)

            Circle()
                .fill(RoadTheme.primaryAction.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 66)
                .offset(x: 150, y: -220)
        }
        .ignoresSafeArea()
    }
}

struct RoadPanel<Content: View>: View {
    let padding: CGFloat
    let content: Content

    init(padding: CGFloat = RoadSpacing.medium, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .roadCardBackground(fill: AnyShapeStyle(RoadTheme.surface), radius: RoadRadius.large, shadowOpacity: 0.08)
    }
}

struct RoadHeroPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(RoadSpacing.medium)
            .roadCardBackground(fill: AnyShapeStyle(RoadTheme.heroGradient), radius: RoadRadius.hero, shadowOpacity: 0.14)
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
                Text(eyebrow.uppercased())
                    .font(RoadTypography.caption.weight(.semibold))
                    .tracking(0.8)
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
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, RoadSpacing.compact)
        .padding(.vertical, 7)
        .background(tint.opacity(0.12), in: Capsule())
    }
}

struct RoadPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: RoadHeight.regular)
            .padding(.horizontal, RoadSpacing.regular)
            .background(
                RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                    .fill(configuration.isPressed ? RoadTheme.primaryActionPressed : RoadTheme.primaryAction)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
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
                    .fill(RoadTheme.secondaryAction.opacity(configuration.isPressed ? 0.78 : 1))
            )
            .overlay {
                RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                    .strokeBorder(RoadTheme.border)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(RoadMotion.relaxed, value: configuration.isPressed)
    }
}

struct RoadTertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RoadTypography.label)
            .foregroundStyle(RoadTheme.textPrimary.opacity(configuration.isPressed ? 0.7 : 0.9))
            .padding(.horizontal, RoadSpacing.compact)
            .padding(.vertical, RoadSpacing.small)
            .background(
                RoundedRectangle(cornerRadius: RoadRadius.small, style: .continuous)
                    .fill(RoadTheme.secondaryAction.opacity(configuration.isPressed ? 0.72 : 1))
            )
            .animation(RoadMotion.relaxed, value: configuration.isPressed)
    }
}

struct RoadSubtleButtonStyle: ButtonStyle {
    var tint: Color = RoadTheme.info

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RoadTypography.label)
            .foregroundStyle(tint.opacity(configuration.isPressed ? 0.72 : 1))
            .frame(minHeight: 36)
            .padding(.horizontal, RoadSpacing.compact)
            .background(
                RoundedRectangle(cornerRadius: RoadRadius.small, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.08 : 0.12))
            )
            .animation(RoadMotion.relaxed, value: configuration.isPressed)
    }
}

struct RoadIconButtonStyle: ButtonStyle {
    var tint: Color = RoadTheme.textPrimary
    var fill: Color = RoadTheme.backgroundRaised

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(tint.opacity(configuration.isPressed ? 0.72 : 1))
            .frame(width: 42, height: 42)
            .background(
                RoundedRectangle(cornerRadius: RoadRadius.small, style: .continuous)
                    .fill(fill.opacity(configuration.isPressed ? 0.78 : 1))
            )
            .overlay {
                RoundedRectangle(cornerRadius: RoadRadius.small, style: .continuous)
                    .strokeBorder(RoadTheme.border)
            }
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
            .padding(.vertical, 7)
            .background(RoadTheme.accent(accent).opacity(0.14), in: Capsule())
    }
}

extension View {
    func roadScreenPadding() -> some View {
        frame(maxWidth: 960, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 20)
    }
}
