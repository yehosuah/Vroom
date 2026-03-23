import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppStateStore

    @State private var selectedProductID: String?
    @State private var isPurchasing = false

    private var selectedProduct: StoreProductSnapshot? {
        appState.storeProducts.first(where: { $0.productID == selectedProductID }) ?? appState.storeProducts.first
    }

    private var statusSubtitle: String {
        if appState.subscriptionSnapshot.tier == .premium {
            return "Premium is already active on this device."
        }
        return "Upgrade when you want the current premium surfaces unlocked and future premium expansions ready as they ship."
    }

    var body: some View {
        RoadScreenScaffold(bottomPadding: 148) {
            RoadHeroPanel {
                VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                    HStack(alignment: .top, spacing: RoadSpacing.compact) {
                        VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                            Text("Vroom Premium")
                                .font(RoadTypography.sectionTitle)
                                .foregroundStyle(RoadTheme.textPrimary)

                            Text(statusSubtitle)
                                .font(RoadTypography.supporting)
                                .foregroundStyle(RoadTheme.textSecondary)
                        }

                        Spacer(minLength: 0)

                        RoadCapsuleLabel(
                            text: appState.subscriptionSnapshot.tier.displayTitle,
                            tint: appState.subscriptionSnapshot.tier == .premium ? RoadTheme.success : RoadTheme.premium,
                            icon: appState.subscriptionSnapshot.tier.iconName
                        )
                    }

                    VStack(alignment: .leading, spacing: RoadSpacing.compact) {
                        featureRow(
                            title: "Deeper insight surfaces",
                            detail: "Keep richer insight summaries ready as your drive history grows."
                        )
                        featureRow(
                            title: "Premium-ready share and route extras",
                            detail: "Unlock premium surfaces without needing to revisit setup when more premium capabilities land."
                        )
                    }
                }
            }

            productSection

            RoadStateCard(
                title: "Restore is always available",
                message: "If Premium is already tied to this Apple ID, you do not need to buy again. Use Restore Purchases instead.",
                icon: "arrow.clockwise",
                tone: .info
            )
        }
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            RoadBottomActionBar {
                VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                    Button(primaryCTA) {
                        guard let product = selectedProduct else { return }
                        Task {
                            isPurchasing = true
                            await appState.purchasePremium(productID: product.productID)
                            isPurchasing = false
                        }
                    }
                    .buttonStyle(RoadPrimaryButtonStyle())
                    .disabled(appState.subscriptionSnapshot.tier == .premium || selectedProduct == nil || isPurchasing)

                    Button("Restore Purchases") {
                        Task { await appState.restorePremium() }
                    }
                    .buttonStyle(RoadSecondaryButtonStyle())
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .task {
            await appState.refreshStoreProducts()
            if selectedProductID == nil {
                selectedProductID = appState.storeProducts.first?.productID
            }
        }
    }

    private var productSection: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            RoadSectionHeader(
                title: "Choose a plan",
                subtitle: "Pick the plan you want before continuing."
            )

            if appState.storeProducts.isEmpty {
                RoadEmptyState(
                    title: "Plans are unavailable",
                    message: "Try again when StoreKit products are available on this device.",
                    icon: "creditcard"
                )
            } else {
                VStack(alignment: .leading, spacing: RoadSpacing.compact) {
                    ForEach(appState.storeProducts) { product in
                        Button {
                            selectedProductID = product.productID
                        } label: {
                            planRow(product)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func planRow(_ product: StoreProductSnapshot) -> some View {
        let isSelected = product.productID == (selectedProductID ?? appState.storeProducts.first?.productID)

        return RoadPanel {
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

                RoadCapsuleLabel(
                    text: appState.subscriptionSnapshot.tier == .premium && isSelected ? "Current" : (isSelected ? "Selected" : "Plan"),
                    tint: isSelected ? RoadTheme.primaryAction : RoadTheme.textMuted
                )
            }
            .padding(.vertical, 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: RoadRadius.large, style: .continuous)
                .strokeBorder(isSelected ? RoadTheme.primaryAction.opacity(0.4) : RoadTheme.border, lineWidth: isSelected ? 2 : 1)
        }
    }

    private var primaryCTA: String {
        if appState.subscriptionSnapshot.tier == .premium {
            return "Premium Active"
        }

        if let selectedProduct {
            return "Continue with \(selectedProduct.displayName)"
        }

        return "Continue"
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
