import SwiftUI
import UIKit

struct ShareComposerView: View {
    let drive: Drive
    let payload: SharePayload

    private var metrics: [RoadMetricPresentation] {
        [
            RoadMetricPresentation(id: "share-distance", label: "Distance", value: RoadFormatting.distance(drive.distanceMeters), icon: "arrow.left.and.right", accent: .neutral),
            RoadMetricPresentation(id: "share-top", label: "Top speed", value: RoadFormatting.speed(drive.topSpeedKPH), icon: "hare.fill", accent: .alert),
            RoadMetricPresentation(id: "share-score", label: "Score", value: "\(drive.scoreSummary.overall)", icon: "rosette", accent: .success)
        ]
    }

    var body: some View {
        RoadScreenScaffold(bottomPadding: 40) {
            RoadPageHeader(
                title: "Share drive",
                subtitle: "Review the image and prepared summary before you share."
            )

            if let imageURL = payload.imageURL, let image = UIImage(contentsOfFile: imageURL.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: RoadRadius.large, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: RoadRadius.large, style: .continuous)
                            .strokeBorder(RoadTheme.border)
                    }
            }

            RoadPanel {
                VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                    Text(drive.summary.title)
                        .font(RoadTypography.sectionTitle)
                        .foregroundStyle(RoadTheme.textPrimary)

                    Text(drive.summary.highlight)
                        .font(RoadTypography.supporting)
                        .foregroundStyle(RoadTheme.textSecondary)

                    RoadMetricGrid(metrics: metrics)
                }
            }

            RoadPanel {
                VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                    RoadSectionHeader(
                        title: "Prepared summary",
                        subtitle: "Use this text as-is or edit it in the share sheet."
                    )

                    Text(payload.text)
                        .font(RoadTypography.supporting)
                        .foregroundStyle(RoadTheme.textSecondary)
                }
            }

            RoadActionGroup(actions: actionItems)
        }
        .navigationTitle("Share")
    }

    private var actionItems: [RoadActionItem] {
        var items: [RoadActionItem] = []

        if let imageURL = payload.imageURL {
            items.append(
                RoadActionItem(id: "share-card-\(drive.id)") {
                    ShareLink(item: imageURL) {
                        Label("Share image", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoadPrimaryButtonStyle())
                }
            )
        }

        items.append(
            RoadActionItem(id: "share-text-\(drive.id)") {
                ShareLink(item: payload.text) {
                    Label("Share summary", systemImage: "text.quote")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoadSecondaryButtonStyle())
            }
        )

        return items
    }
}
