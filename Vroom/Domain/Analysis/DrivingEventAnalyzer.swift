import Foundation

struct DrivingEventAnalyzer: Sendable {
    private let configuration: DriveAnalysisConfiguration

    init(configuration: DriveAnalysisConfiguration) {
        self.configuration = configuration
    }

    func analyze(driveID: UUID, samples: [RoutePointSample]) -> [DrivingEvent] {
        guard samples.count > 1 else { return [] }
        var events: [DrivingEvent] = []

        for (previous, current) in zip(samples, samples.dropFirst()) {
            let speedDelta = current.speedKPH - previous.speedKPH
            let courseDelta = abs(current.courseDegrees - previous.courseDegrees)
            let timeDelta = max(current.timestamp.timeIntervalSince(previous.timestamp), 1)
            let corneringG = (courseDelta / 45) * (current.speedKPH / 100)

            if speedDelta <= -configuration.eventThresholds.hardBrakeDeltaKPH {
                events.append(makeEvent(driveID: driveID, type: .hardBrake, severityValue: abs(speedDelta), timestamp: current.timestamp, coordinate: current.coordinate, metadata: ["deltaKPH": abs(speedDelta)]))
            }
            if speedDelta >= configuration.eventThresholds.hardAccelerationDeltaKPH {
                events.append(makeEvent(driveID: driveID, type: .hardAcceleration, severityValue: speedDelta, timestamp: current.timestamp, coordinate: current.coordinate, metadata: ["deltaKPH": speedDelta]))
            }
            if corneringG >= configuration.eventThresholds.corneringG {
                events.append(makeEvent(driveID: driveID, type: .cornering, severityValue: corneringG, timestamp: current.timestamp, coordinate: current.coordinate, metadata: ["corneringG": corneringG]))
            }
            let accelerationG = abs(speedDelta / max(timeDelta, 1) / 9.81)
            if accelerationG >= configuration.eventThresholds.spikeG {
                events.append(makeEvent(driveID: driveID, type: .gForceSpike, severityValue: accelerationG, timestamp: current.timestamp, coordinate: current.coordinate, metadata: ["gForce": accelerationG]))
            }
        }

        return events
    }

    private func makeEvent(driveID: UUID, type: DrivingEventType, severityValue: Double, timestamp: Date, coordinate: GeoCoordinate, metadata: [String: Double]) -> DrivingEvent {
        let severity: DrivingEventSeverity
        switch severityValue {
        case ..<10:
            severity = .low
        case ..<20:
            severity = .medium
        default:
            severity = .high
        }
        return DrivingEvent(
            id: UUID(),
            driveID: driveID,
            type: type,
            severity: severity,
            confidence: 0.78,
            timestamp: timestamp,
            coordinate: coordinate,
            metadata: metadata
        )
    }
}
