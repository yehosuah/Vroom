import SwiftUI

struct RoadScreenScaffold<Content: View>: View {
    let bottomPadding: CGFloat
    let content: Content

    init(bottomPadding: CGFloat = 112, @ViewBuilder content: () -> Content) {
        self.bottomPadding = bottomPadding
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoadBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: RoadSpacing.large) {
                    content
                }
                .padding(.top, RoadSpacing.large)
                .padding(.bottom, bottomPadding)
                .roadScreenPadding()
            }
        }
    }
}

struct RoadPageHeader: View {
    let title: String
    var subtitle: String?
    var badgeText: String?
    var badgeAccent: RoadAccent = .neutral

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: RoadSpacing.regular) {
                textBlock
                Spacer(minLength: RoadSpacing.regular)
                badgeView
            }

            VStack(alignment: .leading, spacing: RoadSpacing.compact) {
                textBlock
                badgeView
            }
        }
    }

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.small) {
            Text(title)
                .font(RoadTypography.screenTitle)
                .foregroundStyle(RoadTheme.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(RoadTypography.supporting)
                    .foregroundStyle(RoadTheme.textSecondary)
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

    var body: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            HStack(spacing: RoadSpacing.small) {
                Image(systemName: metric.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RoadTheme.accent(metric.accent))

                Text(metric.label)
                    .font(RoadTypography.caption)
                    .foregroundStyle(RoadTheme.textMuted)
                    .lineLimit(1)
            }

            Text(metric.value)
                .font(RoadTypography.metric)
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
        view = AnyView(content())
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
                                .foregroundStyle(selection == option.value ? RoadTheme.background : RoadTheme.accent(.electric))

                            VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                                Text(option.shortTitle ?? option.title)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)

                                if let subtitle = option.subtitle {
                                    Text(subtitle)
                                        .font(RoadTypography.caption)
                                        .foregroundStyle(selection == option.value ? RoadTheme.background.opacity(0.8) : RoadTheme.textMuted)
                                        .lineLimit(1)
                                }
                            }

                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(selection == option.value ? RoadTheme.background : RoadTheme.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: RoadHeight.regular, alignment: .leading)
                        .padding(.horizontal, RoadSpacing.regular)
                        .background(
                            RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                                .fill(selection == option.value ? RoadTheme.primaryAction : RoadTheme.backgroundRaised)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                                .strokeBorder(selection == option.value ? RoadTheme.primaryAction : RoadTheme.border)
                        }
                    }
                    .buttonStyle(.plain)
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
        RoadPanel {
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                HStack(spacing: RoadSpacing.compact) {
                    Image(systemName: icon)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RoadTheme.info)
                        .frame(width: RoadHeight.compact, height: RoadHeight.compact)
                        .background(
                            RoundedRectangle(cornerRadius: RoadRadius.small, style: .continuous)
                                .fill(RoadTheme.info.opacity(0.14))
                        )

                    VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                        Text(title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RoadTheme.textPrimary)

                        Text(message)
                            .font(RoadTypography.supporting)
                            .foregroundStyle(RoadTheme.textSecondary)
                    }
                }

                if let actionLabel, let action {
                    Button(actionLabel, action: action)
                        .buttonStyle(RoadSecondaryButtonStyle())
                }
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
                        .font(.subheadline.weight(.semibold))
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
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(isSelected ? RoadTheme.background : RoadTheme.textPrimary)
        .padding(.horizontal, RoadSpacing.compact)
        .frame(minHeight: RoadHeight.compact)
        .background(
            Capsule()
                .fill(isSelected ? RoadTheme.primaryAction : RoadTheme.backgroundRaised)
        )
        .overlay {
            Capsule()
                .strokeBorder(isSelected ? RoadTheme.primaryAction : RoadTheme.border)
        }
    }
}
