import Foundation

struct DriveAnalysisConfiguration: Codable, Hashable, Sendable {
    struct StartThresholds: Codable, Hashable, Sendable {
        var minimumAutomotiveConfidence: Double
        var minimumSpeedKPH: Double
        var minimumMovingSamples: Int
    }

    struct StopThresholds: Codable, Hashable, Sendable {
        var stationarySpeedKPH: Double
        var stationaryDuration: TimeInterval
        var minimumStoppedSamples: Int
    }

    struct SamplingPolicy: Codable, Hashable, Sendable {
        var minimumDistanceMeters: Double
        var minimumHeadingDelta: Double
        var maximumSampleGap: TimeInterval
    }

    struct EventThresholds: Codable, Hashable, Sendable {
        var hardBrakeDeltaKPH: Double
        var hardAccelerationDeltaKPH: Double
        var corneringG: Double
        var spikeG: Double
        var trapMinimumSpeedKPH: Double
        var cooldownInterval: TimeInterval
    }

    struct Smoothing: Codable, Hashable, Sendable {
        var rollingWindowSize: Int
    }

    struct SignalFiltering: Codable, Hashable, Sendable {
        var degradedHorizontalAccuracyMeters: Double
        var discardedHorizontalAccuracyMeters: Double
        var stopAfterSignalGap: TimeInterval
    }

    var startThresholds: StartThresholds
    var stopThresholds: StopThresholds
    var samplingPolicy: SamplingPolicy
    var eventThresholds: EventThresholds
    var smoothing: Smoothing
    var signalFiltering: SignalFiltering
    var scoreWeights: [String: Double]
    var profiles: [ScoringProfile]

    static let `default` = DriveAnalysisConfiguration(
        startThresholds: .init(minimumAutomotiveConfidence: 0.6, minimumSpeedKPH: 12, minimumMovingSamples: 3),
        stopThresholds: .init(stationarySpeedKPH: 3, stationaryDuration: 120, minimumStoppedSamples: 6),
        samplingPolicy: .init(minimumDistanceMeters: 12, minimumHeadingDelta: 6, maximumSampleGap: 8),
        eventThresholds: .init(hardBrakeDeltaKPH: 18, hardAccelerationDeltaKPH: 16, corneringG: 0.8, spikeG: 1.0, trapMinimumSpeedKPH: 80, cooldownInterval: 6),
        smoothing: .init(rollingWindowSize: 5),
        signalFiltering: .init(degradedHorizontalAccuracyMeters: 35, discardedHorizontalAccuracyMeters: 75, stopAfterSignalGap: 180),
        scoreWeights: [
            "hardBrake": 6,
            "hardAcceleration": 4,
            "cornering": 3,
            "gForceSpike": 8
        ],
        profiles: [.casual, .spirited]
    )
}
