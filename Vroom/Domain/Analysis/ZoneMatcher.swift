import Foundation

struct ZoneMatcher: Sendable {
    private let matchRadiusMeters: Double

    init(matchRadiusMeters: Double = 120) {
        self.matchRadiusMeters = matchRadiusMeters
    }

    func match(driveID: UUID, vehicleID: UUID?, samples: [RoutePointSample], zones: [SpeedZone]) -> [SpeedZoneRun] {
        zones.compactMap { zone in
            guard zone.vehicleScope == nil || zone.vehicleScope == vehicleID else { return nil }
            guard let startIndex = samples.firstIndex(where: { $0.coordinate.distance(to: zone.startMarker) <= matchRadiusMeters }) else { return nil }
            guard let endIndex = samples[startIndex...].firstIndex(where: { $0.coordinate.distance(to: zone.endMarker) <= matchRadiusMeters }) else { return nil }
            guard endIndex > startIndex else { return nil }
            let segment = Array(samples[startIndex...endIndex])
            guard let first = segment.first, let last = segment.last else { return nil }
            return SpeedZoneRun(
                id: UUID(),
                zoneID: zone.id,
                driveID: driveID,
                elapsed: last.timestamp.timeIntervalSince(first.timestamp),
                entrySpeedKPH: first.speedKPH,
                exitSpeedKPH: last.speedKPH,
                peakSpeedKPH: segment.topSpeedKPH,
                completedAt: last.timestamp
            )
        }
    }
}
