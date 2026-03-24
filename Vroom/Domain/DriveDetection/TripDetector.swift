import Foundation

enum TripTransition: Sendable, Equatable {
    case none
    case started
    case stopped
}

struct TripDetector: Sendable {
    private let configuration: DriveAnalysisConfiguration
    private var movingSamples = 0
    private var stoppedSamples = 0
    private var stationaryStartedAt: Date?

    init(configuration: DriveAnalysisConfiguration) {
        self.configuration = configuration
    }

    mutating func ingest(sample: RoutePointSample, motion: MotionActivitySample?) -> TripTransition {
        let automotiveConfidence = motion?.confidence ?? 0
        if sample.speedKPH >= configuration.startThresholds.minimumSpeedKPH,
           automotiveConfidence >= configuration.startThresholds.minimumAutomotiveConfidence {
            movingSamples += 1
            stoppedSamples = 0
            stationaryStartedAt = nil
        } else if sample.speedKPH <= configuration.stopThresholds.stationarySpeedKPH {
            stationaryStartedAt = stationaryStartedAt ?? sample.timestamp
            stoppedSamples += 1
        } else {
            movingSamples = max(0, movingSamples - 1)
            stoppedSamples = 0
            stationaryStartedAt = nil
        }

        if movingSamples >= configuration.startThresholds.minimumMovingSamples {
            movingSamples = 0
            stationaryStartedAt = nil
            return .started
        }
        if stoppedSamples >= configuration.stopThresholds.minimumStoppedSamples,
           let stationaryStartedAt,
           sample.timestamp.timeIntervalSince(stationaryStartedAt) >= configuration.stopThresholds.stationaryDuration {
            stoppedSamples = 0
            self.stationaryStartedAt = nil
            return .stopped
        }
        return .none
    }

    mutating func reset() {
        movingSamples = 0
        stoppedSamples = 0
        stationaryStartedAt = nil
    }
}
