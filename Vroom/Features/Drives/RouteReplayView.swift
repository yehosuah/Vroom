import Combine
import SwiftUI

struct RouteReplayView: View {
    let drive: Drive
    @EnvironmentObject private var appState: AppStateStore
    @State private var trace: [RoutePointSample] = []
    @State private var index = 0.0
    @State private var isPlaying = false

    private let autoplayTimer = Timer.publish(every: 0.75, on: .main, in: .common).autoconnect()

    private var currentDrive: Drive {
        appState.drives.first(where: { $0.id == drive.id }) ?? drive
    }

    private var currentSampleIndex: Int {
        min(max(Int(index.rounded()), 0), max(trace.count - 1, 0))
    }

    private var cursor: ReplayCursorPresentation {
        RoadPresentationBuilder.replayCursor(trace: trace, index: currentSampleIndex)
    }

    private var canPlay: Bool {
        trace.count > 1
    }

    private var sliderUpperBound: Double {
        Double(max(trace.count - 1, 0))
    }

    private var metrics: [RoadMetricPresentation] {
        [
            RoadMetricPresentation(id: "replay-speed", label: "Speed", value: cursor.speed, icon: "gauge.with.needle", accent: .electric),
            RoadMetricPresentation(id: "replay-distance", label: "Distance", value: cursor.distance, icon: "arrow.left.and.right", accent: .neutral),
            RoadMetricPresentation(id: "replay-progress", label: "Progress", value: "\(Int(cursor.progress * 100))%", icon: "timeline.selection", accent: .premium)
        ]
    }

    private var progressText: String {
        guard !trace.isEmpty else { return "No route data" }
        return "\(cursor.index + 1) of \(trace.count)"
    }

    var body: some View {
        ZStack {
            RouteMapView(
                trace: trace,
                events: appState.events(for: drive.id),
                mode: .replay(progress: index),
                style: appState.preferences.mapStyle
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [RoadTheme.mapScrimTop, .clear, RoadTheme.mapScrimBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .overlay(alignment: .top) {
            RoadPageHeader(
                title: "Replay",
                subtitle: currentDrive.summary.title,
                badgeText: trace.isEmpty ? nil : cursor.speed,
                badgeAccent: .electric
            )
            .padding(.horizontal, RoadSpacing.regular)
            .padding(.top, RoadSpacing.hero)
        }
        .safeAreaInset(edge: .bottom) {
            RoadHeroPanel {
                VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                    VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                        Text(trace.isEmpty ? "Route unavailable" : cursor.timestamp)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RoadTheme.textPrimary)

                        Text(progressText)
                            .font(RoadTypography.caption)
                            .foregroundStyle(RoadTheme.textSecondary)
                    }

                    RoadMetricGrid(metrics: metrics, minimumWidth: 120)

                    Slider(value: $index, in: 0...sliderUpperBound, step: 1)
                        .tint(RoadTheme.primaryAction)
                        .disabled(trace.isEmpty)
                        .onChange(of: index) { _, _ in
                            if currentSampleIndex >= trace.count - 1 {
                                isPlaying = false
                            }
                        }

                    RoadActionGroup(actions: [
                        RoadActionItem(id: "replay-start-over-\(currentDrive.id)") {
                            Button("Start over") {
                                index = 0
                                isPlaying = false
                            }
                            .buttonStyle(RoadSecondaryButtonStyle())
                            .disabled(trace.isEmpty)
                            .accessibilityIdentifier("Replay.StartOver")
                        },
                        RoadActionItem(id: "replay-toggle-\(currentDrive.id)") {
                            Button(isPlaying ? "Pause replay" : "Play replay") {
                                guard canPlay else { return }
                                if currentSampleIndex >= trace.count - 1 {
                                    index = 0
                                }
                                isPlaying.toggle()
                            }
                            .buttonStyle(RoadPrimaryButtonStyle())
                            .disabled(!canPlay)
                            .accessibilityIdentifier("Replay.Toggle")
                        }
                    ])
                }
            }
            .padding(.horizontal, RoadSpacing.regular)
            .padding(.top, RoadSpacing.compact)
            .padding(.bottom, RoadSpacing.compact)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task(id: drive.id) {
            trace = await appState.loadTrace(for: drive.id)
            configureReplayState()
        }
        .onReceive(autoplayTimer) { _ in
            guard isPlaying else { return }
            advanceReplay()
        }
        .onChange(of: appState.preferences.replayAutoplay) { _, newValue in
            if !newValue {
                isPlaying = false
            } else if canPlay && currentSampleIndex < trace.count - 1 {
                isPlaying = true
            }
        }
        .accessibilityIdentifier("Replay.Screen")
    }

    private func configureReplayState() {
        guard !trace.isEmpty else {
            index = 0
            isPlaying = false
            return
        }

        index = 0
        isPlaying = appState.preferences.replayAutoplay && canPlay
    }

    private func advanceReplay() {
        guard canPlay else {
            isPlaying = false
            return
        }

        if currentSampleIndex >= trace.count - 1 {
            isPlaying = false
            return
        }

        index = Double(currentSampleIndex + 1)
    }
}
