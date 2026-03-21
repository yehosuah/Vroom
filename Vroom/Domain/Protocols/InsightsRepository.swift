import Foundation

protocol InsightsRepository: Sendable {
    func snapshot(period: InsightPeriod, vehicleID: UUID?) async throws -> InsightSnapshot
    func trend(metric: InsightMetricKind, period: InsightPeriod, vehicleID: UUID?) async throws -> [InsightTrendPoint]
    func patternSummary(period: InsightPeriod, vehicleID: UUID?) async throws -> String
}
