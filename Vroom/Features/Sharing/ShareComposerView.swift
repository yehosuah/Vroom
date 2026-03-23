import SwiftUI
import UIKit

struct ShareComposerView: View {
    @EnvironmentObject private var appState: AppStateStore

    let drive: Drive
    let payload: SharePayload

    @State private var captionText: String
    @State private var shareItems: [Any] = []
    @State private var showingShareSheet = false

    init(drive: Drive, payload: SharePayload) {
        self.drive = drive
        self.payload = payload
        _captionText = State(initialValue: payload.text)
    }

    private var metrics: [RoadMetricPresentation] {
        [
            RoadMetricPresentation(id: "share-distance", label: "Distance", value: RoadFormatting.distance(drive.distanceMeters), icon: "arrow.left.and.right", accent: .neutral),
            RoadMetricPresentation(id: "share-top", label: "Top speed", value: RoadFormatting.speed(drive.topSpeedKPH), icon: "hare.fill", accent: .alert),
            RoadMetricPresentation(id: "share-score", label: "Score", value: "\(drive.scoreSummary.overall)", icon: "rosette", accent: .success)
        ]
    }

    private var previewImage: UIImage? {
        guard let imageURL = payload.imageURL else { return nil }
        return UIImage(contentsOfFile: imageURL.path)
    }

    var body: some View {
        RoadScreenScaffold(bottomPadding: 144) {
            RoadPageHeader(
                title: "Share",
                subtitle: "Preview the recap, adjust the caption, and send it when it feels right."
            )

            if let image = previewImage {
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
                    VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                        Text(drive.summary.title)
                            .font(RoadTypography.sectionTitle)
                            .foregroundStyle(RoadTheme.textPrimary)

                        Text(drive.summary.highlight)
                            .font(RoadTypography.supporting)
                            .foregroundStyle(RoadTheme.textSecondary)
                    }

                    RoadMetricGrid(metrics: metrics, minimumWidth: 120)
                }
            }

            RoadFormField(title: "Caption", helper: "Edit the prepared message before sharing, or keep it as-is.") {
                TextEditor(text: $captionText)
                    .frame(minHeight: 120)
                    .padding(RoadSpacing.small)
                    .scrollContentBackground(.hidden)
                    .background(
                        RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                            .fill(RoadTheme.backgroundRaised)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                            .strokeBorder(RoadTheme.border)
                    }
            }

            if appState.subscriptionSnapshot.tier == .free {
                RoadStateCard(
                    title: "Premium keeps share extras ready",
                    message: "Upgrade if you want premium-ready share themes and future share expansions without revisiting setup.",
                    icon: "sparkles",
                    tone: .info
                ) {
                    NavigationLink("See plans") {
                        PaywallView()
                    }
                    .buttonStyle(RoadSubtleButtonStyle(tint: RoadTheme.premium))
                    .padding(.top, RoadSpacing.small)
                }
            }
        }
        .navigationTitle("Share")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            RoadBottomActionBar {
                VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                    if let image = previewImage {
                        Button {
                            shareItems = [captionText, image]
                            showingShareSheet = true
                        } label: {
                            Label("Share card", systemImage: "photo")
                        }
                        .buttonStyle(RoadPrimaryButtonStyle())

                        Button {
                            shareItems = [captionText]
                            showingShareSheet = true
                        } label: {
                            Label("Share text only", systemImage: "text.quote")
                        }
                        .buttonStyle(RoadSubtleButtonStyle(tint: RoadTheme.info))
                    } else {
                        Button {
                            shareItems = [captionText]
                            showingShareSheet = true
                        } label: {
                            Label("Share text", systemImage: "text.quote")
                        }
                        .buttonStyle(RoadPrimaryButtonStyle())
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ActivityShareSheet(items: shareItems)
        }
    }
}

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
