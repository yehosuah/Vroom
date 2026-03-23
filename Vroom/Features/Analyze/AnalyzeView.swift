import Charts
import SwiftUI

struct AnalyzeView: View {
    @EnvironmentObject private var appState: AppStateStore
    @State private var selectedPeriod: InsightPeriod = .week

    private var snapshot: InsightSnapshot {
        selectedPeriod == .week ? appState.weeklySnapshot : appState.monthlySnapshot
    }

    private var filteredDrives: [Drive] {
        let cutoff: Date
        switch selectedPeriod {
        case .week:
            cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        case .month:
            cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        }

        return appState.drives.filter { $0.startedAt >= cutoff }
    }

    private var filteredDriveIDs: Set<UUID> {
        Set(filteredDrives.map(\.id))
    }

    private var allEvents: [DrivingEvent] {
        filteredDrives.flatMap { appState.events(for: $0.id) }
    }

    private var eventCounts: [(DrivingEventType, Int)] {
        Dictionary(grouping: allEvents, by: \.type)
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }

    private var filteredTraps: [SpeedTrap] {
        appState.traps.filter { filteredDriveIDs.contains($0.driveID) }
    }

    private var highlightMetrics: [RoadMetricPresentation] {
        [
            RoadMetricPresentation(id: "insights-distance", label: "Distance", value: RoadFormatting.distance(snapshot.distanceTotal), icon: "arrow.left.and.right", accent: .neutral),
            RoadMetricPresentation(id: "insights-average", label: "Average drive", value: RoadFormatting.duration(snapshot.durationAverage), icon: "clock", accent: .electric),
            RoadMetricPresentation(id: "insights-trend", label: "Score trend", value: RoadFormatting.scoreTrend(snapshot.scoreTrend), icon: "chart.line.uptrend.xyaxis", accent: .success)
        ]
    }

    var body: some View {
        RoadScreenScaffold {
            RoadPageHeader(
                title: "Insights",
                subtitle: "Start with the short answer for this period, then drill into the patterns that deserve attention."
            )

            summarySection
            drivingEventsSection
            peakSpeedsSection
            segmentsSection

            if appState.subscriptionSnapshot.tier == .free {
                premiumUpsellSection
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await appState.refreshData()
        }
        .task {
            await appState.refreshData()
        }
    }

    private var summarySection: some View {
        RoadHeroPanel {
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                Picker("Period", selection: $selectedPeriod) {
                    Text("Week").tag(InsightPeriod.week)
                    Text("Month").tag(InsightPeriod.month)
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                    Text(selectedPeriod == .week ? "Last 7 days" : "Last 30 days")
                        .font(RoadTypography.sectionTitle)
                        .foregroundStyle(RoadTheme.textPrimary)

                    Text(snapshot.patternSummary)
                        .font(RoadTypography.supporting)
                        .foregroundStyle(RoadTheme.textSecondary)
                }

                RoadMetricGrid(metrics: highlightMetrics, minimumWidth: 120)

                Chart(weeklyTrend) { point in
                    AreaMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Score", point.value)
                    )
                    .foregroundStyle(RoadTheme.info.opacity(0.14))

                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Score", point.value)
                    )
                    .foregroundStyle(RoadTheme.info)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                }
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(RoadFormatting.dayMonth.string(from: date))
                                    .foregroundStyle(RoadTheme.textMuted)
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
    }

    private var premiumUpsellSection: some View {
        RoadStateCard(
            title: "Premium keeps deeper insights ready",
            message: "Upgrade when you want richer trend surfaces and future premium insight expansions. The current summary stays usable without it.",
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

    private var drivingEventsSection: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            RoadSectionHeader(
                title: "Driving events",
                subtitle: "What showed up most often in the selected period."
            )

            if eventCounts.isEmpty {
                RoadEmptyState(
                    title: "No events recorded",
                    message: "Complete more drives to see recurring event patterns here.",
                    icon: "waveform.path.ecg"
                )
            } else {
                RoadGroupedRows {
                    ForEach(Array(eventCounts.prefix(4).enumerated()), id: \.element.0) { index, item in
                        let (eventType, count) = item

                        RoadInfoRow(
                            icon: eventType.iconName,
                            iconTint: accent(for: eventType),
                            title: eventType.displayTitle,
                            subtitle: "\(count) recorded in the selected period"
                        ) {
                            RoadCapsuleLabel(text: impactText(for: count), tint: accent(for: eventType))
                        }
                        .padding(.vertical, RoadSpacing.xSmall)

                        if index < min(eventCounts.count, 4) - 1 {
                            RoadRowDivider()
                        }
                    }
                }
            }
        }
    }

    private var peakSpeedsSection: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            RoadSectionHeader(
                title: "Peak speed moments",
                subtitle: "The highest recorded speed moments in the selected period."
            )

            if filteredTraps.isEmpty {
                RoadEmptyState(
                    title: "No peak speed moments yet",
                    message: "Peak speed moments will appear here after Vroom records them.",
                    icon: "hare"
                )
            } else {
                RoadGroupedRows {
                    ForEach(Array(filteredTraps.prefix(3).enumerated()), id: \.element.id) { index, trap in
                        RoadInfoRow(
                            icon: trap.isFavorite ? "star.fill" : "hare.fill",
                            iconTint: trap.isFavorite ? RoadTheme.success : RoadTheme.warning,
                            title: RoadFormatting.speed(trap.peakSpeedKPH),
                            subtitle: RoadFormatting.shortDate.string(from: trap.timestamp)
                        ) {
                            RoadCapsuleLabel(text: trap.isFavorite ? "Saved" : "Recorded", tint: trap.isFavorite ? RoadTheme.success : RoadTheme.warning)
                        }
                        .padding(.vertical, RoadSpacing.xSmall)

                        if index < min(filteredTraps.count, 3) - 1 {
                            RoadRowDivider()
                        }
                    }
                }
            }
        }
    }

    private var segmentsSection: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            RoadSectionHeader(
                title: "Saved segments",
                subtitle: "Compare the best recorded run on each saved segment."
            )

            if appState.zones.isEmpty {
                RoadEmptyState(
                    title: "No saved segments yet",
                    message: "Saved segments will appear here after you create them.",
                    icon: "scope"
                )
            } else {
                VStack(alignment: .leading, spacing: RoadSpacing.compact) {
                    ForEach(appState.zones) { zone in
                        let best = appState.personalBest(for: zone.id)

                        RoadPanel {
                            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                                ViewThatFits(in: .horizontal) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                                            Text(zone.name)
                                                .font(.headline.weight(.semibold))
                                                .foregroundStyle(RoadTheme.textPrimary)

                                            Text(zone.status.displayTitle)
                                                .font(RoadTypography.meta)
                                                .foregroundStyle(RoadTheme.textSecondary)
                                        }

                                        Spacer()

                                        if let best {
                                            RoadCapsuleLabel(text: "\(RoadFormatting.decimal(best.elapsed, places: 1))s best", tint: RoadTheme.success)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: RoadSpacing.compact) {
                                        Text(zone.name)
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(RoadTheme.textPrimary)

                                        Text(zone.status.displayTitle)
                                            .font(RoadTypography.meta)
                                            .foregroundStyle(RoadTheme.textSecondary)

                                        if let best {
                                            RoadCapsuleLabel(text: "\(RoadFormatting.decimal(best.elapsed, places: 1))s best", tint: RoadTheme.success)
                                        }
                                    }
                                }

                                RoadMetricGrid(metrics: zoneMetrics(for: zone, best: best), minimumWidth: 120)
                            }
                        }
                    }
                }
            }
        }
    }

    private var weeklyTrend: [InsightTrendPoint] {
        let base = snapshot.scoreTrend
        let pointCount = selectedPeriod == .week ? 7 : 8
        let now = Date()

        return (0..<pointCount).map { index in
            let divisor = selectedPeriod == .week ? 6 : 7
            let distanceFromCenter = Double(index - (divisor / 2))

            return InsightTrendPoint(
                date: Calendar.current.date(byAdding: .day, value: index - divisor, to: now) ?? now,
                value: max(65, 82 + base + distanceFromCenter * 1.4)
            )
        }
    }

    private func zoneMetrics(for zone: SpeedZone, best: SpeedZoneRun?) -> [RoadMetricPresentation] {
        guard let best else {
            return [
                RoadMetricPresentation(id: "zone-status-\(zone.id)", label: "Status", value: "Waiting", icon: "scope", accent: .neutral)
            ]
        }

        return [
            RoadMetricPresentation(id: "zone-entry-\(zone.id)", label: "Entry", value: RoadFormatting.speed(best.entrySpeedKPH), icon: "arrow.down.right", accent: .electric),
            RoadMetricPresentation(id: "zone-exit-\(zone.id)", label: "Exit", value: RoadFormatting.speed(best.exitSpeedKPH), icon: "arrow.up.right", accent: .success),
            RoadMetricPresentation(id: "zone-peak-\(zone.id)", label: "Peak", value: RoadFormatting.speed(best.peakSpeedKPH), icon: "hare.fill", accent: .alert)
        ]
    }

    private func impactText(for count: Int) -> String {
        switch count {
        case 0...2:
            return "Low"
        case 3...5:
            return "Moderate"
        default:
            return "High"
        }
    }

    private func accent(for type: DrivingEventType) -> Color {
        switch type {
        case .hardBrake, .gForceSpike:
            return RoadTheme.destructive
        case .hardAcceleration, .speedTrap:
            return RoadTheme.warning
        case .cornering, .speedZone:
            return RoadTheme.info
        }
    }
}
