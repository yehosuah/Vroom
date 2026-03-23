import SwiftUI

struct RoadScreenScaffold<Content: View>: View {
    let bottomPadding: CGFloat
    let topPadding: CGFloat
    let content: Content

    init(bottomPadding: CGFloat = 120, topPadding: CGFloat = RoadSpacing.regular, @ViewBuilder content: () -> Content) {
        self.bottomPadding = bottomPadding
        self.topPadding = topPadding
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoadBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: RoadSpacing.roomy) {
                    content
                }
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
                .roadScreenPadding()
            }
            .scrollIndicators(.hidden)
        }
    }
}

struct RoadPageHeader: View {
    let title: String
    var subtitle: String?
    var badgeText: String?
    var badgeAccent: RoadAccent = .neutral

    var body: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: RoadSpacing.regular) {
                    titleBlock
                    Spacer(minLength: RoadSpacing.regular)
                    badgeView
                }

                VStack(alignment: .leading, spacing: RoadSpacing.compact) {
                    titleBlock
                    badgeView
                }
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.small) {
            Text(title)
                .font(RoadTypography.screenTitle)
                .foregroundStyle(RoadTheme.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(RoadTypography.supporting)
                    .foregroundStyle(RoadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var badgeView: some View {
        if let badgeText {
            RoadStatusBadge(text: badgeText, accent: badgeAccent)
        }
    }
}

struct RoadMetricChip: View {
    let metric: RoadMetricPresentation
    var emphasizesValue = false

    var body: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.small) {
            HStack(spacing: RoadSpacing.small) {
                Image(systemName: metric.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RoadTheme.accent(metric.accent))

                Text(metric.label)
                    .font(RoadTypography.meta)
                    .foregroundStyle(RoadTheme.textSecondary)
                    .lineLimit(1)
            }

            Text(metric.value)
                .font(emphasizesValue ? RoadTypography.heroValue.weight(.semibold) : RoadTypography.metric)
                .monospacedDigit()
                .foregroundStyle(RoadTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RoadSpacing.regular)
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

struct RoadMetricGrid: View {
    let metrics: [RoadMetricPresentation]
    var minimumWidth: CGFloat = 140

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimumWidth), spacing: RoadSpacing.compact, alignment: .top)],
            alignment: .leading,
            spacing: RoadSpacing.compact
        ) {
            ForEach(metrics) { metric in
                RoadMetricChip(metric: metric)
            }
        }
    }
}

struct RoadActionItem: Identifiable {
    let id: String
    let view: AnyView

    init<Content: View>(id: String, @ViewBuilder content: () -> Content) {
        self.id = id
        self.view = AnyView(content())
    }
}

struct RoadActionGroup: View {
    let actions: [RoadActionItem]
    var minimumWidth: CGFloat = 176

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimumWidth), spacing: RoadSpacing.compact, alignment: .top)],
            alignment: .leading,
            spacing: RoadSpacing.compact
        ) {
            ForEach(actions) { action in
                action.view
            }
        }
    }
}

struct RoadOption<Value: Hashable>: Identifiable {
    let value: Value
    let title: String
    let shortTitle: String?
    let subtitle: String?
    let icon: String

    var id: String { title }

    init(value: Value, title: String, shortTitle: String? = nil, subtitle: String? = nil, icon: String) {
        self.value = value
        self.title = title
        self.shortTitle = shortTitle
        self.subtitle = subtitle
        self.icon = icon
    }
}

struct RoadOptionSelector<Value: Hashable>: View {
    let title: String
    var helper: String?
    @Binding var selection: Value
    let options: [RoadOption<Value>]
    var minimumWidth: CGFloat = 132

    var body: some View {
        RoadFormField(title: title, helper: helper) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: minimumWidth), spacing: RoadSpacing.compact, alignment: .top)],
                alignment: .leading,
                spacing: RoadSpacing.compact
            ) {
                ForEach(options) { option in
                    Button {
                        selection = option.value
                    } label: {
                        HStack(spacing: RoadSpacing.compact) {
                            Image(systemName: option.icon)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(selection == option.value ? RoadTheme.primaryAction : RoadTheme.accent(.electric))

                            VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                                Text(option.shortTitle ?? option.title)
                                    .font(RoadTypography.label)
                                    .lineLimit(1)

                                if let subtitle = option.subtitle {
                                    Text(subtitle)
                                        .font(RoadTypography.caption)
                                        .foregroundStyle(selection == option.value ? RoadTheme.textSecondary : RoadTheme.textMuted)
                                        .lineLimit(2)
                                }
                            }

                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(RoadTheme.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: RoadHeight.regular, alignment: .leading)
                        .padding(.horizontal, RoadSpacing.regular)
                        .background(
                            RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                                .fill(selection == option.value ? RoadTheme.selected : RoadTheme.backgroundRaised)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                                .strokeBorder(selection == option.value ? RoadTheme.primaryAction.opacity(0.35) : RoadTheme.border)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

enum RoadStateTone {
    case info
    case success
    case warning
    case destructive

    var tint: Color {
        switch self {
        case .info:
            return RoadTheme.info
        case .success:
            return RoadTheme.success
        case .warning:
            return RoadTheme.warning
        case .destructive:
            return RoadTheme.destructive
        }
    }

    var fill: Color {
        switch self {
        case .info:
            return RoadTheme.infoFill
        case .success:
            return RoadTheme.successFill
        case .warning:
            return RoadTheme.warningFill
        case .destructive:
            return RoadTheme.destructiveFill
        }
    }
}

struct RoadStateCard<Accessory: View>: View {
    let title: String
    let message: String
    let icon: String
    var tone: RoadStateTone = .info
    let accessory: Accessory

    init(
        title: String,
        message: String,
        icon: String,
        tone: RoadStateTone = .info,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.tone = tone
        self.accessory = accessory()
    }

    var body: some View {
        RoadPanel {
            HStack(alignment: .top, spacing: RoadSpacing.compact) {
                Image(systemName: icon)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tone.tint)
                    .frame(width: RoadHeight.compact, height: RoadHeight.compact)
                    .background(
                        RoundedRectangle(cornerRadius: RoadRadius.small, style: .continuous)
                            .fill(tone.fill)
                    )

                VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RoadTheme.textPrimary)

                    Text(message)
                        .font(RoadTypography.supporting)
                        .foregroundStyle(RoadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    accessory
                }
            }
        }
    }
}

struct RoadEmptyState: View {
    let title: String
    let message: String
    let icon: String
    var actionLabel: String?
    var action: (() -> Void)?

    var body: some View {
        RoadStateCard(title: title, message: message, icon: icon) {
            if let actionLabel, let action {
                Button(actionLabel, action: action)
                    .buttonStyle(RoadSecondaryButtonStyle())
                    .padding(.top, RoadSpacing.small)
            }
        }
    }
}

struct RoadFormField<Content: View>: View {
    let title: String
    var helper: String?
    let content: Content

    init(title: String, helper: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.helper = helper
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.small) {
            Text(title)
                .font(RoadTypography.label)
                .foregroundStyle(RoadTheme.textPrimary)

            if let helper {
                Text(helper)
                    .font(RoadTypography.caption)
                    .foregroundStyle(RoadTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content
        }
    }
}

struct RoadTextField: View {
    let title: String
    var helper: String?
    @Binding var text: String

    var body: some View {
        RoadFormField(title: title, helper: helper) {
            TextField(title, text: $text)
                .textInputAutocapitalization(.words)
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
                .foregroundStyle(RoadTheme.textPrimary)
        }
    }
}

struct RoadSelectionMenu<Value: Hashable>: View {
    let title: String
    var helper: String?
    let currentLabel: String
    let icon: String
    let options: [(title: String, value: Value)]
    let selection: Value
    let onSelect: (Value) -> Void

    var body: some View {
        RoadFormField(title: title, helper: helper) {
            Menu {
                ForEach(options, id: \.title) { option in
                    Button(option.title) {
                        onSelect(option.value)
                    }
                }
            } label: {
                HStack(spacing: RoadSpacing.compact) {
                    Image(systemName: icon)
                        .foregroundStyle(RoadTheme.info)

                    Text(currentLabel)
                        .font(RoadTypography.label)
                        .foregroundStyle(RoadTheme.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RoadTheme.textMuted)
                }
                .frame(maxWidth: .infinity, minHeight: RoadHeight.regular, alignment: .leading)
                .padding(.horizontal, RoadSpacing.regular)
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

struct RoadSelectableChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: RoadSpacing.small) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
            }

            Text(title)
                .lineLimit(1)
        }
        .font(RoadTypography.label)
        .foregroundStyle(isSelected ? RoadTheme.primaryAction : RoadTheme.textPrimary)
        .padding(.horizontal, RoadSpacing.compact)
        .frame(minHeight: RoadHeight.compact)
        .background(
            Capsule()
                .fill(isSelected ? RoadTheme.selected : RoadTheme.backgroundRaised)
        )
        .overlay {
            Capsule()
                .strokeBorder(isSelected ? RoadTheme.primaryAction.opacity(0.35) : RoadTheme.border)
        }
    }
}

struct RoadNavigationRow: View {
    let icon: String
    let iconTint: Color
    let title: String
    var subtitle: String? = nil
    var badge: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: RoadSpacing.compact) {
            Image(systemName: icon)
                .font(.headline.weight(.semibold))
                .foregroundStyle(iconTint)
                .frame(width: 28, height: 28)
                .background(iconTint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                HStack(spacing: RoadSpacing.small) {
                    Text(title)
                        .font(RoadTypography.label)
                        .foregroundStyle(RoadTheme.textPrimary)

                    if let badge {
                        RoadCapsuleLabel(text: badge, tint: iconTint)
                    }
                }

                if let subtitle {
                    Text(subtitle)
                        .font(RoadTypography.meta)
                        .foregroundStyle(RoadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RoadTheme.textMuted)
                .padding(.top, 4)
        }
        .padding(.vertical, RoadSpacing.small)
    }
}

struct RoadReadinessItem: Identifiable {
    let id: String
    let icon: String
    let title: String
    let message: String
    let status: String
    let tone: RoadStateTone
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
}

struct RoadReadinessChecklist: View {
    let title: String
    var subtitle: String?
    let items: [RoadReadinessItem]

    var body: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            RoadSectionHeader(title: title, subtitle: subtitle)

            RoadGroupedRows {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    VStack(alignment: .leading, spacing: RoadSpacing.small) {
                        RoadInfoRow(
                            icon: item.icon,
                            iconTint: item.tone.tint,
                            title: item.title,
                            subtitle: item.message
                        ) {
                            RoadCapsuleLabel(text: item.status, tint: item.tone.tint)
                        }

                        if let actionTitle = item.actionTitle, let action = item.action {
                            Button(actionTitle, action: action)
                                .buttonStyle(RoadSubtleButtonStyle(tint: item.tone.tint))
                                .accessibilityLabel("\(actionTitle) for \(item.title)")
                        }
                    }
                    .padding(.vertical, RoadSpacing.xSmall)

                    if index < items.count - 1 {
                        RoadRowDivider()
                    }
                }
            }
        }
    }
}

struct RoadInfoRow<Accessory: View>: View {
    let icon: String
    let iconTint: Color
    let title: String
    let subtitle: String?
    let accessory: Accessory

    init(icon: String, iconTint: Color = RoadTheme.info, title: String, subtitle: String? = nil, @ViewBuilder accessory: () -> Accessory) {
        self.icon = icon
        self.iconTint = iconTint
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory()
    }

    var body: some View {
        HStack(alignment: .top, spacing: RoadSpacing.compact) {
            Image(systemName: icon)
                .font(.headline.weight(.semibold))
                .foregroundStyle(iconTint)
                .frame(width: 28, height: 28)
                .background(iconTint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                Text(title)
                    .font(RoadTypography.label)
                    .foregroundStyle(RoadTheme.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(RoadTypography.meta)
                        .foregroundStyle(RoadTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)

            accessory
        }
        .padding(.vertical, RoadSpacing.small)
    }
}

struct RoadGroupedRows<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.horizontal, RoadSpacing.regular)
        .padding(.vertical, RoadSpacing.small)
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

struct RoadRowDivider: View {
    var body: some View {
        Divider()
            .overlay(RoadTheme.divider)
            .padding(.leading, 44)
    }
}

enum RoadBannerTone {
    case success
    case info
    case warning

    var tint: Color {
        switch self {
        case .success:
            return RoadTheme.success
        case .info:
            return RoadTheme.info
        case .warning:
            return RoadTheme.warning
        }
    }

    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        }
    }
}

struct RoadFloatingBanner: View {
    let title: String
    var message: String?
    var tone: RoadBannerTone

    var body: some View {
        HStack(alignment: .top, spacing: RoadSpacing.compact) {
            Image(systemName: tone.icon)
                .font(.headline)
                .foregroundStyle(tone.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(RoadTypography.label)
                    .foregroundStyle(RoadTheme.textPrimary)

                if let message {
                    Text(message)
                        .font(RoadTypography.caption)
                        .foregroundStyle(RoadTheme.textSecondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(RoadSpacing.regular)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: RoadRadius.large, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: RoadRadius.large, style: .continuous)
                .strokeBorder(RoadTheme.border)
        }
        .shadow(color: RoadTheme.shadow.opacity(0.16), radius: 18, x: 0, y: 12)
    }
}

struct RoadBottomActionBar<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        RoadHeroPanel {
            content
        }
        .padding(.horizontal, RoadSpacing.regular)
        .padding(.top, RoadSpacing.small)
        .padding(.bottom, RoadSpacing.small)
        .background(Color.clear)
    }
}

struct RoadLoadingState: View {
    let title: String
    let message: String

    var body: some View {
        RoadScreenScaffold(bottomPadding: 0, topPadding: RoadSpacing.hero) {
            Spacer(minLength: 0)

            RoadStateCard(title: title, message: message, icon: "arrow.triangle.2.circlepath", tone: .info) {
                ProgressView()
                    .tint(RoadTheme.primaryAction)
                    .padding(.top, RoadSpacing.small)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
    }
}
