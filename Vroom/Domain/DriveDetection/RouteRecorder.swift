import Foundation

struct RouteRecorder: Sendable {
    private let policy: DriveAnalysisConfiguration.SamplingPolicy
    private(set) var samples: [RoutePointSample] = []

    init(policy: DriveAnalysisConfiguration.SamplingPolicy) {
        self.policy = policy
    }

    mutating func append(_ sample: RoutePointSample) -> Bool {
        guard let last = samples.last else {
            samples.append(sample)
            return true
        }

        let distance = last.coordinate.distance(to: sample.coordinate)
        let headingDelta = abs(last.courseDegrees - sample.courseDegrees)
        let timeDelta = sample.timestamp.timeIntervalSince(last.timestamp)
        let shouldKeep = distance >= policy.minimumDistanceMeters
            || headingDelta >= policy.minimumHeadingDelta
            || timeDelta >= policy.maximumSampleGap

        if shouldKeep {
            samples.append(sample)
        }
        return shouldKeep
    }
}
