import Foundation

struct DriveScoringEngine: Sendable {
    private let configuration: DriveAnalysisConfiguration

    init(configuration: DriveAnalysisConfiguration) {
        self.configuration = configuration
    }

    func score(events: [DrivingEvent], profile: ScoringProfile) -> DriveScoreSummary {
        let weights = configuration.scoreWeights.merging(profile.weightOverrides, uniquingKeysWith: { _, override in override })
        var overall = 100
        var deductions: [String: Int] = [:]

        for event in events {
            let weight = Int(weights[event.type.rawValue] ?? 3)
            overall -= weight
            deductions[event.type.rawValue, default: 0] += weight
        }

        let subscores: [String: Int] = [
            "smoothness": max(0, overall - (deductions[DrivingEventType.hardBrake.rawValue] ?? 0)),
            "control": max(0, overall - (deductions[DrivingEventType.cornering.rawValue] ?? 0)),
            "discipline": max(0, overall - (deductions[DrivingEventType.gForceSpike.rawValue] ?? 0))
        ]

        return DriveScoreSummary(
            overall: max(0, overall),
            subscores: subscores,
            deductions: deductions,
            profileID: profile.id
        )
    }
}
