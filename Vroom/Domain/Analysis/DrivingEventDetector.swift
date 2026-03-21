import Foundation

struct DrivingEventDetector: Sendable {
    private let configuration: DriveAnalysisConfiguration
    private var lastSample: RoutePointSample?
    private var recentLateral: [Double] = []
    private var recentLongitudinal: [Double] = []
    private var lastEmission: [DrivingEventType: Date] = [:]

    init(configuration: DriveAnalysisConfiguration) {
        self.configuration = configuration
    }

    mutating func ingest(driveID: UUID, sample: RoutePointSample, motion: DeviceMotionSample?) -> [DrivingEvent] {
        defer { lastSample = sample }
        guard let previous = lastSample else { return [] }

        if let motion {
            recentLateral.append(abs(motion.lateralG))
            recentLongitudinal.append(motion.longitudinalG)
        }
        if recentLateral.count > configuration.smoothing.rollingWindowSize {
            recentLateral.removeFirst(recentLateral.count - configuration.smoothing.rollingWindowSize)
        }
        if recentLongitudinal.count > configuration.smoothing.rollingWindowSize {
            recentLongitudinal.removeFirst(recentLongitudinal.count - configuration.smoothing.rollingWindowSize)
        }

        let timeDelta = max(sample.timestamp.timeIntervalSince(previous.timestamp), 1)
        let speedDelta = sample.speedKPH - previous.speedKPH
        let smoothedLongitudinal = recentLongitudinal.isEmpty ? 0 : recentLongitudinal.reduce(0, +) / Double(recentLongitudinal.count)
        let smoothedLateral = recentLateral.isEmpty ? 0 : recentLateral.reduce(0, +) / Double(recentLateral.count)
        let inferredAccelerationG = abs((speedDelta / 3.6) / timeDelta) / 9.81

        var events: [DrivingEvent] = []
        if speedDelta <= -configuration.eventThresholds.hardBrakeDeltaKPH || smoothedLongitudinal <= -configuration.eventThresholds.spikeG,
           let event = makeEventIfAllowed(
            driveID: driveID,
            type: .hardBrake,
            value: max(abs(speedDelta), abs(smoothedLongitudinal)),
            sample: sample,
            metadata: ["deltaKPH": abs(speedDelta), "longitudinalG": abs(smoothedLongitudinal)]
           ) {
            events.append(event)
        }
        if speedDelta >= configuration.eventThresholds.hardAccelerationDeltaKPH || smoothedLongitudinal >= configuration.eventThresholds.spikeG,
           let event = makeEventIfAllowed(
            driveID: driveID,
            type: .hardAcceleration,
            value: max(speedDelta, abs(smoothedLongitudinal)),
            sample: sample,
            metadata: ["deltaKPH": speedDelta, "longitudinalG": abs(smoothedLongitudinal)]
           ) {
            events.append(event)
        }
        if smoothedLateral >= configuration.eventThresholds.corneringG,
           let event = makeEventIfAllowed(
            driveID: driveID,
            type: .cornering,
            value: smoothedLateral,
            sample: sample,
            metadata: ["lateralG": smoothedLateral]
           ) {
            events.append(event)
        }
        if inferredAccelerationG >= configuration.eventThresholds.spikeG,
           let event = makeEventIfAllowed(
            driveID: driveID,
            type: .gForceSpike,
            value: inferredAccelerationG,
            sample: sample,
            metadata: ["gForce": inferredAccelerationG]
           ) {
            events.append(event)
        }
        return events
    }

    private mutating func makeEventIfAllowed(
        driveID: UUID,
        type: DrivingEventType,
        value: Double,
        sample: RoutePointSample,
        metadata: [String: Double]
    ) -> DrivingEvent? {
        if let lastEmission = lastEmission[type],
           sample.timestamp.timeIntervalSince(lastEmission) < configuration.eventThresholds.cooldownInterval {
            return nil
        }
        self.lastEmission[type] = sample.timestamp

        let severity: DrivingEventSeverity
        switch value {
        case ..<1.2: severity = .low
        case ..<2.1: severity = .medium
        default: severity = .high
        }

        return DrivingEvent(
            id: UUID(),
            driveID: driveID,
            type: type,
            severity: severity,
            confidence: 0.82,
            timestamp: sample.timestamp,
            coordinate: sample.coordinate,
            metadata: metadata
        )
    }
}
