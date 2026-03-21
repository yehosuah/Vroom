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

    private var overviewMetrics: [RoadMetricPresentation] {
        [
            RoadMetricPresentation(id: "insights-distance", label: "Distance", value: RoadFormatting.distance(snapshot.distanceTotal), icon: "arrow.left.and.right", accent: .neutral),
            RoadMetricPresentation(id: "insights-average", label: "Average drive", value: RoadFormatting.duration(snapshot.durationAverage), icon: "clock", accent: .electric),
            RoadMetricPresentation(id: "insights-events", label: "Event rate", value: RoadFormatting.decimal(snapshot.eventFrequency, places: 2), icon: "waveform.path.ecg", accent: .alert),
            RoadMetricPresentation(id: "insights-trend", label: "Score trend", value: RoadFormatting.scoreTrend(snapshot.scoreTrend), icon: "chart.line.uptrend.xyaxis", accent: .success)
        ]
    }

    var body: some View {
        RoadScreenScaffold {
            RoadPageHeader(
                title: "Insights",
                subtitle: "Review recent driving trends, top speeds, and repeatable segments."
            )

            overviewSection
            drivingEventsSection
            topSpeedsSection
            segmentsSection
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await appState.refreshData()
        }
    }

    private var overviewSection: some View {
        RoadPanel {
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                RoadSectionHeader(
                    title: selectedPeriod == .week ? "Last 7 days" : "Last 30 days",
                    subtitle: snapshot.patternSummary
                )

                HStack(spacing: RoadSpacing.small) {
                    periodButton(.week, title: "Last 7 days")
                    periodButton(.month, title: "Last 30 days")
                }

                Chart(weeklyTrend) { point in
                    AreaMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Score", point.value)
                    )
                    .foregroundStyle(RoadTheme.info.opacity(0.24))

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

                RoadMetricGrid(metrics: overviewMetrics)
            }
        }
    }

    private var drivingEventsSection: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            RoadSectionHeader(
                title: "Driving events",
                subtitle: "Review which event types showed up most often in the selected time range."
            )

            if eventCounts.isEmpty {
                RoadEmptyState(
                    title: "No events recorded",
                    message: "Complete more drives to see recurring events here.",
                    icon: "waveform.path.ecg"
                )
            } else {
                ForEach(eventCounts, id: \.0) { eventType, count in
                    RoadPanel {
                        HStack(spacing: RoadSpacing.regular) {
                            Image(systemName: eventType.iconName)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(accent(for: eventType))
                                .frame(width: RoadHeight.compact, height: RoadHeight.compact)
                                .background(
                                    RoundedRectangle(cornerRadius: RoadRadius.small, style: .continuous)
                                        .fill(accent(for: eventType).opacity(0.14))
                                )

                            VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                                Text(eventType.displayTitle)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(RoadTheme.textPrimary)

                                Text("\(count) recorded")
                                    .font(RoadTypography.caption)
                                    .foregroundStyle(RoadTheme.textSecondary)
                            }

                            Spacer(minLength: 0)

                            RoadCapsuleLabel(text: impactText(for: count), tint: accent(for: eventType))
                        }
                    }
                }
            }
        }
    }

    private var topSpeedsSection: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            RoadSectionHeader(
                title: "Top speeds",
                subtitle: "See the highest recorded speed moments from the selected time range."
            )

            if filteredTraps.isEmpty {
                RoadEmptyState(
                    title: "No top speeds saved",
                    message: "Top speed moments will appear here after Vroom records them.",
                    icon: "hare"
                )
            } else {
                ForEach(filteredTraps.prefix(3)) { trap in
                    RoadPanel {
                        HStack {
                            VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                                Text(RoadFormatting.speed(trap.peakSpeedKPH))
                                    .font(RoadTypography.sectionTitle)
                                    .foregroundStyle(RoadTheme.textPrimary)

                                Text(RoadFormatting.shortDate.string(from: trap.timestamp))
                                    .font(RoadTypography.caption)
                                    .foregroundStyle(RoadTheme.textSecondary)
                            }

                            Spacer()

                            RoadCapsuleLabel(
                                text: trap.isFavorite ? "Saved" : "Recorded",
                                tint: trap.isFavorite ? RoadTheme.success : RoadTheme.warning
                            )
                        }
                    }
                }
            }
        }
    }

    private var segmentsSection: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.compact) {
            RoadSectionHeader(
                title: "Segments",
                subtitle: "Compare saved segments and check your current best run."
            )

            if appState.zones.isEmpty {
                RoadEmptyState(
                    title: "No segments yet",
                    message: "Saved segments will appear here after you create them.",
                    icon: "scope"
                )
            } else {
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
                                            .font(RoadTypography.caption)
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
                                        .font(RoadTypography.caption)
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

    private func periodButton(_ period: InsightPeriod, title: String) -> some View {
        Button {
            selectedPeriod = period
        } label: {
            RoadSelectableChip(title: title, isSelected: selectedPeriod == period)
        }
        .buttonStyle(.plain)
    }

    private func zoneMetrics(for zone: SpeedZone, best: SpeedZoneRun?) -> [RoadMetricPresentation] {
        guard let best else {
            return [
                RoadMetricPresentation(id: "zone-status-\(zone.id)", label: "Status", value: "Waiting for a run", icon: "scope", accent: .neutral)
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
