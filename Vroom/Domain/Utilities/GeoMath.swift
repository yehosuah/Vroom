import Foundation

extension GeoCoordinate {
    func distance(to other: GeoCoordinate) -> Double {
        let earthRadius = 6_371_000.0
        let dLat = (other.latitude - latitude) * .pi / 180
        let dLon = (other.longitude - longitude) * .pi / 180
        let lat1 = latitude * .pi / 180
        let lat2 = other.latitude * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2)
            + sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c
    }

    func interpolated(to other: GeoCoordinate, fraction: Double) -> GeoCoordinate {
        let clampedFraction = min(max(fraction, 0), 1)
        return GeoCoordinate(
            latitude: latitude + ((other.latitude - latitude) * clampedFraction),
            longitude: longitude + ((other.longitude - longitude) * clampedFraction)
        )
    }
}

extension Array where Element == RoutePointSample {
    var totalDistanceMeters: Double {
        guard count > 1 else { return 0 }
        return zip(self, dropFirst()).reduce(0) { partial, pair in
            partial + pair.0.coordinate.distance(to: pair.1.coordinate)
        }
    }

    var geoBounds: GeoBounds {
        GeoBounds(coordinates: map(\.coordinate))
    }

    var topSpeedKPH: Double {
        map(\.speedKPH).max() ?? 0
    }

    var averageSpeedKPH: Double {
        guard !isEmpty else { return 0 }
        return map(\.speedKPH).reduce(0, +) / Double(count)
    }
}
