import Foundation

extension UnitSystem {
    var displayTitle: String {
        switch self {
        case .imperial:
            return "Imperial"
        case .metric:
            return "Metric"
        }
    }

    var iconName: String {
        switch self {
        case .imperial:
            return "speedometer"
        case .metric:
            return "ruler"
        }
    }
}

extension AppMapStyle {
    var displayTitle: String {
        switch self {
        case .standard:
            return "Standard"
        case .hybrid:
            return "Hybrid"
        case .imagery:
            return "Satellite"
        }
    }

    var shortTitle: String {
        switch self {
        case .standard:
            return "Map"
        case .hybrid:
            return "Hybrid"
        case .imagery:
            return "Sat"
        }
    }

    var iconName: String {
        switch self {
        case .standard:
            return "map"
        case .hybrid:
            return "square.3.layers.3d"
        case .imagery:
            return "globe.americas.fill"
        }
    }
}

extension BatteryMode {
    var displayTitle: String {
        switch self {
        case .balanced:
            return "Balanced"
        case .performance:
            return "Performance"
        case .lowPower:
            return "Battery Saver"
        }
    }

    var shortTitle: String {
        switch self {
        case .balanced:
            return "Balanced"
        case .performance:
            return "Performance"
        case .lowPower:
            return "Saver"
        }
    }

    var iconName: String {
        switch self {
        case .balanced:
            return "battery.75"
        case .performance:
            return "bolt.fill"
        case .lowPower:
            return "battery.25"
        }
    }
}

extension AvatarStyle {
    var displayTitle: String {
        switch self {
        case .atlas:
            return "Atlas"
        case .apex:
            return "Apex"
        case .classic:
            return "Classic"
        case .horizon:
            return "Horizon"
        }
    }

    var iconName: String {
        switch self {
        case .atlas:
            return "map.fill"
        case .apex:
            return "mountain.2.fill"
        case .classic:
            return "circle.hexagongrid.fill"
        case .horizon:
            return "sun.horizon.fill"
        }
    }
}

extension LocationAuthorizationStatus {
    var displayTitle: String {
        switch self {
        case .notDetermined:
            return "Not Set"
        case .whenInUse:
            return "While Using App"
        case .always:
            return "Always"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        }
    }

    var iconName: String {
        switch self {
        case .notDetermined:
            return "location.circle"
        case .whenInUse:
            return "location"
        case .always:
            return "location.fill"
        case .denied:
            return "location.slash"
        case .restricted:
            return "location.slash.fill"
        }
    }
}

extension MotionAuthorizationStatus {
    var displayTitle: String {
        switch self {
        case .notDetermined:
            return "Not Set"
        case .authorized:
            return "Allowed"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        }
    }

    var iconName: String {
        switch self {
        case .notDetermined:
            return "figure.walk.circle"
        case .authorized:
            return "figure.walk.motion"
        case .denied:
            return "figure.walk.circle.fill"
        case .restricted:
            return "hand.raised.circle"
        }
    }
}

extension NotificationAuthorizationStatus {
    var displayTitle: String {
        switch self {
        case .notDetermined:
            return "Not Set"
        case .authorized:
            return "Allowed"
        case .denied:
            return "Denied"
        case .provisional:
            return "Deliver Quietly"
        }
    }

    var iconName: String {
        switch self {
        case .notDetermined:
            return "bell.badge"
        case .authorized:
            return "bell.fill"
        case .denied:
            return "bell.slash.fill"
        case .provisional:
            return "bell.and.waves.left.and.right"
        }
    }
}

extension DrivingEventType {
    var displayTitle: String {
        switch self {
        case .hardBrake:
            return "Hard brake"
        case .hardAcceleration:
            return "Hard acceleration"
        case .cornering:
            return "Cornering"
        case .gForceSpike:
            return "G-force spike"
        case .speedTrap:
            return "Speed trap"
        case .speedZone:
            return "Speed zone"
        }
    }

    var iconName: String {
        switch self {
        case .hardBrake:
            return "arrow.down.to.line"
        case .hardAcceleration:
            return "arrow.up.to.line"
        case .cornering:
            return "arrow.triangle.branch"
        case .gForceSpike:
            return "waveform.path.ecg"
        case .speedTrap:
            return "bolt.fill"
        case .speedZone:
            return "scope"
        }
    }
}

extension DrivingEventSeverity {
    var displayTitle: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Moderate"
        case .high:
            return "High"
        }
    }
}

extension InsightPeriod {
    var displayTitle: String {
        switch self {
        case .week:
            return "Week"
        case .month:
            return "Month"
        }
    }
}

extension SpeedZoneStatus {
    var displayTitle: String {
        switch self {
        case .active:
            return "Active"
        case .archived:
            return "Archived"
        }
    }
}

extension ConvoyStatus {
    var displayTitle: String {
        switch self {
        case .lobby:
            return "Lobby"
        case .live:
            return "Live"
        case .ended:
            return "Closed"
        }
    }

    var iconName: String {
        switch self {
        case .lobby:
            return "person.3.sequence"
        case .live:
            return "dot.radiowaves.left.and.right"
        case .ended:
            return "checkmark.circle"
        }
    }
}

extension ParticipantPresence {
    var displayTitle: String {
        switch self {
        case .active:
            return "Active"
        case .stale:
            return "Away"
        case .disconnected:
            return "Offline"
        }
    }
}

extension SubscriptionTier {
    var displayTitle: String {
        switch self {
        case .free:
            return "Free"
        case .premium:
            return "Premium"
        }
    }

    var iconName: String {
        switch self {
        case .free:
            return "sparkles.rectangle.stack"
        case .premium:
            return "sparkles"
        }
    }
}

extension RenewalState {
    var displayTitle: String {
        switch self {
        case .none:
            return "Inactive"
        case .active:
            return "Active"
        case .billingRetry:
            return "Billing Retry"
        case .expired:
            return "Expired"
        }
    }
}

extension SignalQuality {
    var displayTitle: String {
        switch self {
        case .unknown:
            return "Acquiring"
        case .good:
            return "Ready"
        case .degraded:
            return "Reduced"
        case .poor:
            return "Weak"
        }
    }
}
