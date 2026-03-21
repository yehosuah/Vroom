import Foundation

struct TrapExtractor: Sendable {
    private let configuration: DriveAnalysisConfiguration

    init(configuration: DriveAnalysisConfiguration) {
        self.configuration = configuration
    }

    func extract(driveID: UUID, samples: [RoutePointSample]) -> [SpeedTrap] {
        guard samples.count > 2 else { return [] }
        var traps: [SpeedTrap] = []
        for index in 1..<(samples.count - 1) {
            let previous = samples[index - 1]
            let current = samples[index]
            let next = samples[index + 1]
            guard current.speedKPH >= configuration.eventThresholds.trapMinimumSpeedKPH else { continue }
            if current.speedKPH >= previous.speedKPH, current.speedKPH >= next.speedKPH {
                traps.append(
                    SpeedTrap(
                        id: UUID(),
                        driveID: driveID,
                        timestamp: current.timestamp,
                        peakSpeedKPH: current.speedKPH,
                        coordinate: current.coordinate,
                        isFavorite: false
                    )
                )
            }
        }
        return traps
    }
}
