import Foundation

enum PreviewFixtures {
    static let profile = UserProfile(
        id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE") ?? UUID(),
        displayName: "Alex",
        avatarStyle: .atlas,
        createdAt: Date(timeIntervalSince1970: 1_710_000_000),
        defaultVehicleID: UUID(uuidString: "11111111-2222-3333-4444-555555555555"),
        onboardingState: .completed
    )

    static let vehicle = Vehicle(
        id: UUID(uuidString: "11111111-2222-3333-4444-555555555555") ?? UUID(),
        nickname: "Midnight",
        make: "Porsche",
        model: "718 Cayman",
        year: 2022,
        isPrimary: true,
        archivedAt: nil
    )

    static let traceSamples: [RoutePointSample] = [
        RoutePointSample(timestamp: Date(timeIntervalSince1970: 1_710_000_000), coordinate: .init(latitude: 34.0522, longitude: -118.2437), altitudeMeters: 91, verticalAccuracy: 8, horizontalAccuracy: 5, speedKPH: 42, courseDegrees: 35, headingAccuracy: 5),
        RoutePointSample(timestamp: Date(timeIntervalSince1970: 1_710_000_060), coordinate: .init(latitude: 34.0560, longitude: -118.2380), altitudeMeters: 96, verticalAccuracy: 8, horizontalAccuracy: 5, speedKPH: 58, courseDegrees: 42, headingAccuracy: 5),
        RoutePointSample(timestamp: Date(timeIntervalSince1970: 1_710_000_120), coordinate: .init(latitude: 34.0592, longitude: -118.2310), altitudeMeters: 104, verticalAccuracy: 8, horizontalAccuracy: 4, speedKPH: 63, courseDegrees: 48, headingAccuracy: 5),
        RoutePointSample(timestamp: Date(timeIntervalSince1970: 1_710_000_180), coordinate: .init(latitude: 34.0618, longitude: -118.2260), altitudeMeters: 108, verticalAccuracy: 8, horizontalAccuracy: 4, speedKPH: 52, courseDegrees: 61, headingAccuracy: 5)
    ]

    static let drive = Drive(
        id: UUID(uuidString: "66666666-7777-8888-9999-AAAAAAAAAAAA") ?? UUID(),
        vehicleID: vehicle.id,
        startedAt: Date(timeIntervalSince1970: 1_710_000_000),
        endedAt: Date(timeIntervalSince1970: 1_710_000_180),
        distanceMeters: 6_300,
        duration: 1_080,
        avgSpeedKPH: 49,
        topSpeedKPH: 84,
        favorite: true,
        scoreSummary: DriveScoreSummary(overall: 88, subscores: ["smoothness": 91, "pace": 84], deductions: ["hardBrake": 6], profileID: ScoringProfile.casual.id),
        traceRef: "preview-drive",
        summary: DriveSummary(title: "Sunset Loop", highlight: "Strong pace through canyon section", eventCount: 3)
    )

    static let event = DrivingEvent(
        id: UUID(),
        driveID: drive.id,
        type: .hardBrake,
        severity: .medium,
        confidence: 0.8,
        timestamp: drive.startedAt.addingTimeInterval(320),
        coordinate: traceSamples[1].coordinate,
        metadata: ["deltaKPH": 18]
    )

    static let trap = SpeedTrap(
        id: UUID(),
        driveID: drive.id,
        timestamp: drive.startedAt.addingTimeInterval(540),
        peakSpeedKPH: 84,
        coordinate: traceSamples[2].coordinate,
        isFavorite: false
    )

    static let zone = SpeedZone(
        id: UUID(),
        name: "Harbor Sprint",
        startMarker: traceSamples.first!.coordinate,
        endMarker: traceSamples.last!.coordinate,
        vehicleScope: vehicle.id,
        createdAt: Date(timeIntervalSince1970: 1_710_000_000),
        status: .active
    )

    static let zoneRun = SpeedZoneRun(
        id: UUID(),
        zoneID: zone.id,
        driveID: drive.id,
        elapsed: 27.2,
        entrySpeedKPH: 54,
        exitSpeedKPH: 62,
        peakSpeedKPH: 84,
        completedAt: drive.endedAt
    )

    static let insightSnapshot = InsightSnapshot(
        period: .week,
        distanceTotal: 132_400,
        durationAverage: 2_450,
        topSpeedTrend: 6,
        eventFrequency: 0.42,
        scoreTrend: 3,
        patternSummary: "Weekend drives are faster than weekday commute drives."
    )

    static let convoy = Convoy(
        id: UUID(),
        joinCode: "RALLY7",
        hostProfileID: profile.id,
        createdAt: Date(),
        status: .live,
        settings: .default
    )

    static let participants: [ConvoyParticipant] = [
        ConvoyParticipant(id: UUID(), profileID: profile.id, displayName: profile.displayName, vehicleID: vehicle.id, presence: .active, lastLocation: traceSamples.first?.coordinate, lastUpdateAt: Date()),
        ConvoyParticipant(id: UUID(), profileID: UUID(), displayName: "Maya", vehicleID: nil, presence: .active, lastLocation: traceSamples[1].coordinate, lastUpdateAt: Date()),
        ConvoyParticipant(id: UUID(), profileID: UUID(), displayName: "Chris", vehicleID: nil, presence: .stale, lastLocation: traceSamples[2].coordinate, lastUpdateAt: Date().addingTimeInterval(-48))
    ]
}
