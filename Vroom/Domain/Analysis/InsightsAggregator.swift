import Foundation

struct InsightsAggregator: Sendable {
    func snapshot(period: InsightPeriod, now: Date, drives: [Drive], events: [DrivingEvent]) -> InsightSnapshot {
        let filteredDrives = drives.filter { $0.startedAt >= period.startDate(from: now) }
        let filteredEvents = events.filter { event in
            filteredDrives.contains(where: { $0.id == event.driveID })
        }
        guard !filteredDrives.isEmpty else {
            return InsightSnapshot(period: period, distanceTotal: 0, durationAverage: 0, topSpeedTrend: 0, eventFrequency: 0, scoreTrend: 0, patternSummary: "Complete a drive to unlock this view.")
        }
        let averageScore = filteredDrives.map { Double($0.scoreSummary.overall) }.reduce(0, +) / Double(filteredDrives.count)
        return InsightSnapshot(
            period: period,
            distanceTotal: filteredDrives.reduce(0) { $0 + $1.distanceMeters },
            durationAverage: filteredDrives.reduce(0) { $0 + $1.duration } / Double(filteredDrives.count),
            topSpeedTrend: filteredDrives.map(\.topSpeedKPH).max() ?? 0,
            eventFrequency: Double(filteredEvents.count) / Double(filteredDrives.count),
            scoreTrend: averageScore,
            patternSummary: filteredDrives.count > 2 ? "Your strongest drives are clustering later in the period." : "Add more drives for stronger comparisons."
        )
    }

    func trend(metric: InsightMetricKind, drives: [Drive]) -> [InsightTrendPoint] {
        drives.sorted { $0.startedAt < $1.startedAt }.map { drive in
            let value: Double
            switch metric {
            case .distance:
                value = drive.distanceMeters
            case .averageSpeed:
                value = drive.avgSpeedKPH
            case .topSpeed:
                value = drive.topSpeedKPH
            case .score:
                value = Double(drive.scoreSummary.overall)
            case .eventCount:
                value = Double(drive.summary.eventCount)
            }
            return InsightTrendPoint(date: drive.startedAt, value: value)
        }
    }
}
