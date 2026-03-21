import Foundation

enum RoadAccent: String, Hashable, Sendable {
    case neutral
    case electric
    case alert
    case success
    case premium
}

struct RoadMetricPresentation: Hashable, Identifiable, Sendable {
    let id: String
    let label: String
    let value: String
    let icon: String
    let accent: RoadAccent
}

struct DriveHeroPresentation: Hashable, Sendable {
    let eyebrow: String
    let title: String
    let subtitle: String
    let status: String
    let statusAccent: RoadAccent
    let metrics: [RoadMetricPresentation]
}

struct JournalDrivePresentation: Hashable, Sendable {
    let title: String
    let subtitle: String
    let timestamp: String
    let vehicleLabel: String
    let isFavorite: Bool
    let metrics: [RoadMetricPresentation]
}

struct ReplayCursorPresentation: Hashable, Sendable {
    let index: Int
    let progress: Double
    let timestamp: String
    let speed: String
    let distance: String
}

enum RoadPresentationBuilder {
    static func hero(
        session: DriveSession?,
        latestDrive: Drive?,
        preferredVehicle: Vehicle?
    ) -> DriveHeroPresentation {
        if let session {
            return DriveHeroPresentation(
                eyebrow: "Recording",
                title: "Drive in progress",
                subtitle: signalSubtitle(for: session.liveMetrics.signalQuality),
                status: session.liveMetrics.signalQuality.displayTitle,
                statusAccent: accent(for: session.liveMetrics.signalQuality),
                metrics: [
                    RoadMetricPresentation(id: "live-speed", label: "Current speed", value: RoadFormatting.speed(session.liveMetrics.currentSpeedKPH), icon: "gauge.with.needle", accent: .electric),
                    RoadMetricPresentation(id: "live-distance", label: "Distance", value: RoadFormatting.distance(session.liveMetrics.distanceMeters), icon: "arrow.left.and.right", accent: .neutral),
                    RoadMetricPresentation(id: "live-top", label: "Top speed", value: RoadFormatting.speed(session.liveMetrics.topSpeedKPH), icon: "hare.fill", accent: .alert),
                    RoadMetricPresentation(id: "live-time", label: "Drive time", value: RoadFormatting.duration(session.liveMetrics.duration), icon: "clock.fill", accent: .success)
                ]
            )
        }

        if let latestDrive {
            return DriveHeroPresentation(
                eyebrow: "Last drive",
                title: latestDrive.summary.title,
                subtitle: latestDrive.summary.highlight,
                status: preferredVehicle?.nickname ?? "No vehicle",
                statusAccent: preferredVehicle == nil ? .premium : .neutral,
                metrics: [
                    RoadMetricPresentation(id: "last-distance", label: "Distance", value: RoadFormatting.distance(latestDrive.distanceMeters), icon: "arrow.left.and.right", accent: .neutral),
                    RoadMetricPresentation(id: "last-duration", label: "Drive time", value: RoadFormatting.duration(latestDrive.duration), icon: "clock.fill", accent: .electric),
                    RoadMetricPresentation(id: "last-top", label: "Top speed", value: RoadFormatting.speed(latestDrive.topSpeedKPH), icon: "hare.fill", accent: .alert),
                    RoadMetricPresentation(id: "last-score", label: "Score", value: "\(latestDrive.scoreSummary.overall)", icon: "rosette", accent: .success)
                ]
            )
        }

        return DriveHeroPresentation(
            eyebrow: "Ready",
            title: "Ready to drive",
            subtitle: "Start a drive any time. Automatic detection stays available after permissions are enabled.",
            status: preferredVehicle?.nickname ?? "No vehicle",
            statusAccent: preferredVehicle == nil ? .premium : .neutral,
            metrics: [
                RoadMetricPresentation(id: "idle-mode", label: "Tracking", value: "Automatic", icon: "location.north.line", accent: .electric),
                RoadMetricPresentation(id: "idle-map", label: "Map", value: "Ready", icon: "map.fill", accent: .neutral),
                RoadMetricPresentation(id: "idle-replay", label: "Replay", value: "Available", icon: "play.circle.fill", accent: .success),
                RoadMetricPresentation(id: "idle-focus", label: "Events", value: "On", icon: "waveform.path.ecg", accent: .alert)
            ]
        )
    }

    static func journalRow(
        drive: Drive,
        vehicle: Vehicle?
    ) -> JournalDrivePresentation {
        JournalDrivePresentation(
            title: drive.summary.title,
            subtitle: drive.summary.highlight,
            timestamp: RoadFormatting.shortDate.string(from: drive.startedAt),
            vehicleLabel: vehicle?.nickname ?? "No vehicle",
            isFavorite: drive.favorite,
            metrics: [
                RoadMetricPresentation(id: "journal-distance-\(drive.id)", label: "Distance", value: RoadFormatting.distance(drive.distanceMeters), icon: "arrow.left.and.right", accent: .neutral),
                RoadMetricPresentation(id: "journal-top-\(drive.id)", label: "Peak Speed", value: RoadFormatting.speed(drive.topSpeedKPH), icon: "hare.fill", accent: .alert),
                RoadMetricPresentation(id: "journal-score-\(drive.id)", label: "Score", value: "\(drive.scoreSummary.overall)", icon: "rosette", accent: .success)
            ]
        )
    }

    static func detailMetrics(
        drive: Drive,
        vehicle: Vehicle?,
        eventCount: Int
    ) -> [RoadMetricPresentation] {
        [
            RoadMetricPresentation(id: "detail-vehicle-\(drive.id)", label: "Vehicle", value: vehicle?.nickname ?? "No vehicle", icon: "car.fill", accent: .neutral),
            RoadMetricPresentation(id: "detail-distance-\(drive.id)", label: "Distance", value: RoadFormatting.distance(drive.distanceMeters), icon: "arrow.left.and.right", accent: .neutral),
            RoadMetricPresentation(id: "detail-average-\(drive.id)", label: "Average speed", value: RoadFormatting.speed(drive.avgSpeedKPH), icon: "gauge.with.needle", accent: .electric),
            RoadMetricPresentation(id: "detail-top-\(drive.id)", label: "Top speed", value: RoadFormatting.speed(drive.topSpeedKPH), icon: "hare.fill", accent: .alert),
            RoadMetricPresentation(id: "detail-score-\(drive.id)", label: "Score", value: "\(drive.scoreSummary.overall)", icon: "rosette", accent: .success),
            RoadMetricPresentation(id: "detail-events-\(drive.id)", label: "Events", value: "\(eventCount)", icon: "waveform.path.ecg", accent: .premium)
        ]
    }

    static func replayCursor(trace: [RoutePointSample], index: Int) -> ReplayCursorPresentation {
        replayCursor(trace: trace, progress: Double(index))
    }

    static func replayCursor(trace: [RoutePointSample], progress: Double) -> ReplayCursorPresentation {
        guard let snapshot = replaySnapshot(trace: trace, progress: progress) else {
            return ReplayCursorPresentation(index: 0, progress: 0, timestamp: "--", speed: RoadFormatting.speed(0), distance: RoadFormatting.distance(0))
        }

        return ReplayCursorPresentation(
            index: snapshot.displayIndex,
            progress: snapshot.normalizedProgress,
            timestamp: RoadFormatting.shortDate.string(from: snapshot.timestamp),
            speed: RoadFormatting.speed(snapshot.speedKPH),
            distance: RoadFormatting.distance(snapshot.distanceMeters)
        )
    }

    static func humanDriveSummary(
        trace: [RoutePointSample],
        events: [DrivingEvent]
    ) -> DriveSummary {
        guard let first = trace.first?.timestamp else {
            return DriveSummary(title: "Drive", highlight: "Drive saved and ready to review.", eventCount: events.count)
        }

        let distance = trace.adjacentPairs().reduce(0.0) { partial, pair in
            partial + pair.0.coordinate.distance(to: pair.1.coordinate)
        }
        let title = "\(dayPart(for: first)) drive"

        let highlight: String
        if let dominant = dominantEvent(in: events) {
            highlight = "\(events.count) event\(events.count == 1 ? "" : "s"), mostly \(dominant)."
        } else if distance > 0 {
            highlight = "\(RoadFormatting.distance(distance)) recorded."
        } else {
            highlight = "Drive saved and ready to review."
        }

        return DriveSummary(title: title, highlight: highlight, eventCount: events.count)
    }

    private static func accent(for quality: SignalQuality) -> RoadAccent {
        switch quality {
        case .unknown, .good:
            return .success
        case .degraded:
            return .premium
        case .poor:
            return .alert
        }
    }

    private static func signalSubtitle(for quality: SignalQuality) -> String {
        switch quality {
        case .unknown, .good:
            return "Route recording is active and updating normally."
        case .degraded:
            return "Recording continues, but location accuracy is reduced."
        case .poor:
            return "Signal is weak. Route detail should improve when reception recovers."
        }
    }

    private static func dominantEvent(in events: [DrivingEvent]) -> String? {
        guard !events.isEmpty else { return nil }
        return Dictionary(grouping: events, by: \.type)
            .max(by: { $0.value.count < $1.value.count })?
            .key
            .displayTitle
            .lowercased()
    }

    private static func dayPart(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12:
            return "Morning"
        case 12..<17:
            return "Afternoon"
        case 17..<22:
            return "Evening"
        default:
            return "Night"
        }
    }
}

enum RoutePresentationBuilder {
    static func build(
        trace: [RoutePointSample],
        events: [DrivingEvent],
        replayIndex: Int? = nil
    ) -> RoutePresentation {
        build(
            trace: trace,
            events: events,
            replayProgress: replayIndex.map(Double.init)
        )
    }

    static func build(
        trace: [RoutePointSample],
        events: [DrivingEvent],
        replayProgress: Double?
    ) -> RoutePresentation {
        let path = trace.map(\.coordinate)
        var markers: [RouteMarkerPresentation] = []

        if let start = trace.first?.coordinate {
            markers.append(
                RouteMarkerPresentation(
                    id: UUID(),
                    title: "Start",
                    subtitle: nil,
                    coordinate: start,
                    kind: .start
                )
            )
        }

        markers.append(
            contentsOf: events.map { event in
                RouteMarkerPresentation(
                    id: event.id,
                    title: event.type.displayTitle,
                    subtitle: event.severity.displayTitle,
                    coordinate: event.coordinate,
                    kind: .event(event.type)
                )
            }
        )

        if let end = trace.last?.coordinate {
            markers.append(
                RouteMarkerPresentation(
                    id: UUID(),
                    title: "Finish",
                    subtitle: nil,
                    coordinate: end,
                    kind: .finish
                )
            )
        }

        let highlightedCoordinate: GeoCoordinate?
        if let replayProgress, let snapshot = replaySnapshot(trace: trace, progress: replayProgress) {
            highlightedCoordinate = snapshot.coordinate
            markers.append(
                RouteMarkerPresentation(
                    id: UUID(),
                    title: "Replay",
                    subtitle: nil,
                    coordinate: snapshot.coordinate,
                    kind: .replay
                )
            )
        } else {
            highlightedCoordinate = nil
        }

        return RoutePresentation(
            bounds: path.isEmpty ? .zero : GeoBounds(coordinates: path),
            path: path,
            markers: markers,
            highlightedCoordinate: highlightedCoordinate
        )
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    func adjacentPairs() -> Zip2Sequence<Self, DropFirstSequence<Self>> {
        zip(self, dropFirst())
    }
}

private struct ReplaySnapshot {
    let displayIndex: Int
    let normalizedProgress: Double
    let timestamp: Date
    let speedKPH: Double
    let distanceMeters: Double
    let coordinate: GeoCoordinate
}

private func replaySnapshot(trace: [RoutePointSample], progress: Double) -> ReplaySnapshot? {
    guard let first = trace.first else { return nil }
    guard trace.count > 1 else {
        return ReplaySnapshot(
            displayIndex: 0,
            normalizedProgress: 0,
            timestamp: first.timestamp,
            speedKPH: first.speedKPH,
            distanceMeters: 0,
            coordinate: first.coordinate
        )
    }

    let maxProgress = Double(trace.count - 1)
    let clampedProgress = min(max(progress, 0), maxProgress)
    let lowerIndex = min(Int(floor(clampedProgress)), trace.count - 1)
    let upperIndex = min(lowerIndex + 1, trace.count - 1)
    let fraction = clampedProgress - Double(lowerIndex)

    let lower = trace[lowerIndex]
    let upper = trace[upperIndex]
    let distanceBeforeSegment = trace.prefix(lowerIndex + 1).adjacentPairs().reduce(0.0) { partial, pair in
        partial + pair.0.coordinate.distance(to: pair.1.coordinate)
    }
    let segmentDistance = lower.coordinate.distance(to: upper.coordinate)

    return ReplaySnapshot(
        displayIndex: min(Int(clampedProgress.rounded()), trace.count - 1),
        normalizedProgress: clampedProgress / maxProgress,
        timestamp: lower.timestamp.addingTimeInterval(upper.timestamp.timeIntervalSince(lower.timestamp) * fraction),
        speedKPH: lower.speedKPH + ((upper.speedKPH - lower.speedKPH) * fraction),
        distanceMeters: distanceBeforeSegment + (segmentDistance * fraction),
        coordinate: lower.coordinate.interpolated(to: upper.coordinate, fraction: fraction)
    )
}
