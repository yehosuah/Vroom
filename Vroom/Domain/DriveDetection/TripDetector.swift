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

    init(configuration: DriveAnalysisConfiguration) {
        self.configuration = configuration
    }

    mutating func ingest(sample: RoutePointSample, motion: MotionActivitySample?) -> TripTransition {
        let automotiveConfidence = motion?.confidence ?? 0
        if sample.speedKPH >= configuration.startThresholds.minimumSpeedKPH,
           automotiveConfidence >= configuration.startThresholds.minimumAutomotiveConfidence {
            movingSamples += 1
            stoppedSamples = 0
        } else if sample.speedKPH <= configuration.stopThresholds.stationarySpeedKPH {
            stoppedSamples += 1
        } else {
            movingSamples = max(0, movingSamples - 1)
            stoppedSamples = 0
        }

        if movingSamples >= configuration.startThresholds.minimumMovingSamples {
            movingSamples = 0
            return .started
        }
        if stoppedSamples >= configuration.stopThresholds.minimumStoppedSamples {
            stoppedSamples = 0
            return .stopped
        }
        return .none
    }

    mutating func reset() {
        movingSamples = 0
        stoppedSamples = 0
    }
}
