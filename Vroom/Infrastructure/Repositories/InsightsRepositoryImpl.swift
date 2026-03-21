import Foundation
import SwiftData

final class InsightsRepositoryImpl: @unchecked Sendable, InsightsRepository {
    private let container: ModelContainer
    private let clock: any AppClock

    init(container: ModelContainer, clock: any AppClock) {
        self.container = container
        self.clock = clock
    }

    func snapshot(period: InsightPeriod, vehicleID: UUID?) async throws -> InsightSnapshot {
        let context = ModelContext(container)
        let cutoff = period.startDate(from: clock.now)
        let drives = try context.fetch(FetchDescriptor<DriveRecord>(sortBy: [SortDescriptor(\.startedAt)])).map(\.domainModel).filter {
            $0.startedAt >= cutoff && (vehicleID == nil || $0.vehicleID == vehicleID)
        }
        let events = try context.fetch(FetchDescriptor<DrivingEventRecord>()).map(\.domainModel).filter { event in
            drives.contains(where: { $0.id == event.driveID })
        }
        guard !drives.isEmpty else {
            return InsightSnapshot(period: period, distanceTotal: 0, durationAverage: 0, topSpeedTrend: 0, eventFrequency: 0, scoreTrend: 0, patternSummary: "Complete a drive to unlock this trend view.")
        }
        let priorCutoff = period.startDate(from: cutoff)
        let priorDrives = try context.fetch(FetchDescriptor<DriveRecord>()).map(\.domainModel).filter {
            $0.startedAt >= priorCutoff && $0.startedAt < cutoff && (vehicleID == nil || $0.vehicleID == vehicleID)
        }
        let currentTopSpeed = drives.map(\.topSpeedKPH).max() ?? 0
        let previousTopSpeed = priorDrives.map(\.topSpeedKPH).max() ?? 0
        let currentScore = drives.map { Double($0.scoreSummary.overall) }.reduce(0, +) / Double(drives.count)
        let previousScore = priorDrives.isEmpty ? currentScore : priorDrives.map { Double($0.scoreSummary.overall) }.reduce(0, +) / Double(priorDrives.count)
        return InsightSnapshot(
            period: period,
            distanceTotal: drives.reduce(0) { $0 + $1.distanceMeters },
            durationAverage: drives.reduce(0) { $0 + $1.duration } / Double(drives.count),
            topSpeedTrend: currentTopSpeed - previousTopSpeed,
            eventFrequency: Double(events.count) / Double(drives.count),
            scoreTrend: currentScore - previousScore,
            patternSummary: drives.count >= 3 ? "Drive frequency is building and high-speed moments are stable." : "Capture a few more drives for stronger trend signals."
        )
    }

    func trend(metric: InsightMetricKind, period: InsightPeriod, vehicleID: UUID?) async throws -> [InsightTrendPoint] {
        let context = ModelContext(container)
        let cutoff = period.startDate(from: clock.now)
        let drives = try context.fetch(FetchDescriptor<DriveRecord>(sortBy: [SortDescriptor(\.startedAt)])).map(\.domainModel).filter {
            $0.startedAt >= cutoff && (vehicleID == nil || $0.vehicleID == vehicleID)
        }
        return drives.map { drive in
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

    func patternSummary(period: InsightPeriod, vehicleID: UUID?) async throws -> String {
        try await snapshot(period: period, vehicleID: vehicleID).patternSummary
    }
}
