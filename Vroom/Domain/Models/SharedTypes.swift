import Foundation

struct GeoCoordinate: Codable, Hashable, Sendable {
    var latitude: Double
    var longitude: Double
}

struct GeoBounds: Codable, Hashable, Sendable {
    var minLatitude: Double
    var maxLatitude: Double
    var minLongitude: Double
    var maxLongitude: Double

    static let zero = GeoBounds(minLatitude: 0, maxLatitude: 0, minLongitude: 0, maxLongitude: 0)

    init(minLatitude: Double, maxLatitude: Double, minLongitude: Double, maxLongitude: Double) {
        self.minLatitude = minLatitude
        self.maxLatitude = maxLatitude
        self.minLongitude = minLongitude
        self.maxLongitude = maxLongitude
    }

    init(coordinates: [GeoCoordinate]) {
        guard let first = coordinates.first else {
            self = .zero
            return
        }

        var minLatitude = first.latitude
        var maxLatitude = first.latitude
        var minLongitude = first.longitude
        var maxLongitude = first.longitude

        for coordinate in coordinates.dropFirst() {
            minLatitude = min(minLatitude, coordinate.latitude)
            maxLatitude = max(maxLatitude, coordinate.latitude)
            minLongitude = min(minLongitude, coordinate.longitude)
            maxLongitude = max(maxLongitude, coordinate.longitude)
        }

        self.init(
            minLatitude: minLatitude,
            maxLatitude: maxLatitude,
            minLongitude: minLongitude,
            maxLongitude: maxLongitude
        )
    }
}

enum UnitSystem: String, Codable, CaseIterable, Sendable, Identifiable {
    case imperial
    case metric

    var id: String { rawValue }
}

enum AppMapStyle: String, Codable, CaseIterable, Sendable, Identifiable {
    case standard
    case hybrid
    case imagery

    var id: String { rawValue }
}

enum BatteryMode: String, Codable, CaseIterable, Sendable, Identifiable {
    case balanced
    case performance
    case lowPower

    var id: String { rawValue }
}

enum AvatarStyle: String, Codable, CaseIterable, Sendable, Identifiable {
    case atlas
    case apex
    case classic
    case horizon

    var id: String { rawValue }
}

enum OnboardingState: String, Codable, Sendable {
    case notStarted
    case inProgress
    case completed
}

enum LocationAuthorizationStatus: String, Codable, Sendable {
    case notDetermined
    case whenInUse
    case always
    case denied
    case restricted
}

enum MotionAuthorizationStatus: String, Codable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

enum NotificationAuthorizationStatus: String, Codable, Sendable {
    case notDetermined
    case authorized
    case denied
    case provisional
}

enum DriveSessionState: String, Codable, Sendable {
    case idle
    case armed
    case active
    case finalizing
    case completed
}

enum DriveRecordingMode: String, Codable, Sendable {
    case manual
    case automatic
}

enum RouteTraceCompression: String, Codable, Sendable {
    case none
}

enum RouteTraceQuality: String, Codable, Sendable {
    case low
    case fair
    case good
    case excellent
}

enum DrivingEventType: String, Codable, Sendable, CaseIterable {
    case hardBrake
    case hardAcceleration
    case cornering
    case gForceSpike
    case speedTrap
    case speedZone
}

enum DrivingEventSeverity: String, Codable, Sendable {
    case low
    case medium
    case high
}

enum InsightPeriod: String, Codable, CaseIterable, Sendable, Identifiable {
    case week
    case month

    var id: String { rawValue }
}

enum InsightMetricKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case distance
    case averageSpeed
    case topSpeed
    case score
    case eventCount

    var id: String { rawValue }
}

enum SpeedZoneStatus: String, Codable, Sendable {
    case active
    case archived
}

enum ConvoyStatus: String, Codable, Sendable {
    case lobby
    case live
    case ended
}

enum ParticipantPresence: String, Codable, Sendable {
    case active
    case stale
    case disconnected
}

enum SubscriptionTier: String, Codable, Sendable {
    case free
    case premium
}

enum RenewalState: String, Codable, Sendable {
    case none
    case active
    case billingRetry
    case expired
}

enum PremiumFeature: String, Codable, CaseIterable, Sendable, Identifiable {
    case deepTrends
    case premiumShareThemes
    case advancedAnalytics
    case convoyVoice
    case extendedConvoys
    case cloudSync

    var id: String { rawValue }
}

enum FeatureGateReason: String, Codable, Sendable {
    case unlocked
    case softLaunch
    case premiumRequired
    case unavailable
}

enum FeatureGateSource: String, Codable, Sendable {
    case launchPolicy
    case subscription
    case featureFlag
}

enum SyncEntityType: String, Codable, Sendable {
    case profile
    case vehicle
    case drive
    case speedTrap
    case speedZone
    case preference
}

enum SyncChangeType: String, Codable, Sendable {
    case upsert
    case delete
}

enum SyncStatus: String, Codable, Sendable {
    case pending
    case synced
    case failed
}

struct DriveLiveMetrics: Codable, Hashable, Sendable {
    var currentSpeedKPH: Double
    var distanceMeters: Double
    var duration: TimeInterval
    var topSpeedKPH: Double
    var sampleCount: Int
    var signalQuality: SignalQuality

    static let zero = DriveLiveMetrics(
        currentSpeedKPH: 0,
        distanceMeters: 0,
        duration: 0,
        topSpeedKPH: 0,
        sampleCount: 0,
        signalQuality: .unknown
    )
}

enum SignalQuality: String, Codable, Hashable, Sendable {
    case unknown
    case good
    case degraded
    case poor
}

struct DriveSummary: Codable, Hashable, Sendable {
    var title: String
    var highlight: String
    var eventCount: Int
}

struct DriveScoreSummary: Codable, Hashable, Sendable {
    var overall: Int
    var subscores: [String: Int]
    var deductions: [String: Int]
    var profileID: String

    static let unrated = DriveScoreSummary(overall: 100, subscores: [:], deductions: [:], profileID: ScoringProfile.casual.id)
}

struct InsightTrendPoint: Codable, Hashable, Sendable, Identifiable {
    var id: UUID
    var date: Date
    var value: Double

    init(id: UUID = UUID(), date: Date, value: Double) {
        self.id = id
        self.date = date
        self.value = value
    }
}

struct VehicleStats: Codable, Hashable, Sendable {
    var driveCount: Int
    var distanceMeters: Double
    var averageScore: Double
    var topSpeedKPH: Double

    static let empty = VehicleStats(driveCount: 0, distanceMeters: 0, averageScore: 0, topSpeedKPH: 0)
}

struct StoreProductSnapshot: Codable, Hashable, Sendable, Identifiable {
    var id: String { productID }
    var productID: String
    var displayName: String
    var priceDisplay: String
    var tier: SubscriptionTier
}

struct PrivacyOptions: Codable, Hashable, Sendable {
    var analyticsEnabled: Bool
    var preciseExports: Bool
    var retainDeletedData: Bool

    static let `default` = PrivacyOptions(analyticsEnabled: true, preciseExports: true, retainDeletedData: false)
}

struct ConvoySettings: Codable, Hashable, Sendable {
    var participantLimit: Int
    var voiceEnabled: Bool

    static let `default` = ConvoySettings(participantLimit: 6, voiceEnabled: false)
}

struct LocationSample: Codable, Hashable, Sendable {
    var timestamp: Date
    var coordinate: GeoCoordinate
    var horizontalAccuracyMeters: Double
    var verticalAccuracyMeters: Double
    var altitudeMeters: Double
    var speedKPH: Double
    var courseDegrees: Double
    var headingAccuracyDegrees: Double
}

struct MotionActivitySample: Codable, Hashable, Sendable {
    var timestamp: Date
    var isAutomotive: Bool
    var confidence: Double
}

struct DeviceMotionSample: Codable, Hashable, Sendable {
    var timestamp: Date
    var lateralG: Double
    var longitudinalG: Double
}

struct SharePayload: Sendable {
    var text: String
    var imageURL: URL?
}

struct RouteTraceWriterHandle: Hashable, Sendable {
    var id: UUID
    var driveID: UUID
}
