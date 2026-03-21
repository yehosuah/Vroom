import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppStateStore

    private var statusSubtitle: String {
        if appState.subscriptionSnapshot.tier == .premium {
            return "Premium is already active on this device."
        }
        return "Review current plans and restore an existing purchase if needed."
    }

    var body: some View {
        NavigationStack {
            RoadScreenScaffold(bottomPadding: 40) {
                RoadPageHeader(
                    title: "Premium",
                    subtitle: statusSubtitle,
                    badgeText: appState.subscriptionSnapshot.tier.displayTitle,
                    badgeAccent: appState.subscriptionSnapshot.tier == .premium ? .success : .premium
                )

                benefitsSection
                productSection
            }
            .navigationTitle("Premium")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var benefitsSection: some View {
        RoadPanel {
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                RoadSectionHeader(
                    title: "Included today",
                    subtitle: "Only benefits that are currently reflected in the app are listed here."
                )

                featureRow(
                    title: "Expanded insights",
                    detail: "Review trend summaries, top speeds, and saved segments in one place."
                )
                featureRow(
                    title: "Drive sharing",
                    detail: "Generate a summary and image for completed drives."
                )
                featureRow(
                    title: "Future premium updates",
                    detail: "Convoys are still limited while live syncing is offline."
                )
            }
        }
    }

    private var productSection: some View {
        RoadPanel {
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                RoadSectionHeader(
                    title: "Plans",
                    subtitle: "Choose a plan below or restore a purchase made on this Apple ID."
                )

                if appState.storeProducts.isEmpty {
                    RoadEmptyState(
                        title: "Plans are unavailable",
                        message: "Restore your purchases or try again when products are available on this device.",
                        icon: "creditcard"
                    )
                } else {
                    ForEach(appState.storeProducts) { product in
                        Button {
                            Task { await appState.purchasePremium(productID: product.productID) }
                        } label: {
                            HStack(spacing: RoadSpacing.regular) {
                                VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                                    Text(product.displayName)
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(RoadTheme.textPrimary)

                                    Text(product.priceDisplay)
                                        .font(RoadTypography.supporting)
                                        .foregroundStyle(RoadTheme.textSecondary)
                                }

                                Spacer()

                                Text(appState.subscriptionSnapshot.tier == .premium ? "Current plan" : "Choose plan")
                                    .font(RoadTypography.caption.weight(.semibold))
                                    .foregroundStyle(RoadTheme.primaryAction)
                            }
                            .padding(RoadSpacing.regular)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                                    .fill(RoadTheme.backgroundRaised)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                                    .strokeBorder(RoadTheme.border)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button("Restore purchases") {
                    Task { await appState.restorePremium() }
                }
                .buttonStyle(RoadSecondaryButtonStyle())
            }
        }
    }

    private func featureRow(title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: RoadSpacing.compact) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(RoadTheme.success)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RoadTheme.textPrimary)

                Text(detail)
                    .font(RoadTypography.supporting)
                    .foregroundStyle(RoadTheme.textSecondary)
            }
        }
    }
}
