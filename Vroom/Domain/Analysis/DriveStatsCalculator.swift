import Foundation

struct DriveStats: Sendable {
    let distanceMeters: Double
    let duration: TimeInterval
    let averageSpeedKPH: Double
    let topSpeedKPH: Double
}

struct DriveStatsCalculator: Sendable {
    func calculate(samples: [RoutePointSample], startedAt: Date, endedAt: Date) -> DriveStats {
        let accepted = samples.filter { $0.horizontalAccuracy >= 0 }
        let duration = max(endedAt.timeIntervalSince(startedAt), 0)
        let distance = accepted.totalDistanceMeters
        let topSpeed = accepted.topSpeedKPH
        let averageSpeed = duration > 0 ? (distance / 1000) / (duration / 3600) : 0
        return DriveStats(
            distanceMeters: distance,
            duration: duration,
            averageSpeedKPH: averageSpeed,
            topSpeedKPH: topSpeed
        )
    }
}
