import Foundation

struct InsightSnapshot: Codable, Hashable, Sendable {
    var period: InsightPeriod
    var distanceTotal: Double
    var durationAverage: TimeInterval
    var topSpeedTrend: Double
    var eventFrequency: Double
    var scoreTrend: Double
    var patternSummary: String
}
