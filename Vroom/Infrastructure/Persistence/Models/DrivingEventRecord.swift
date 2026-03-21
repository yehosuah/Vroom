import Foundation
import SwiftData

@Model
final class DrivingEventRecord {
    @Attribute(.unique) var id: UUID
    var driveID: UUID
    var typeRaw: String
    var severityRaw: String
    var confidence: Double
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var metadataData: Data

    init(id: UUID, driveID: UUID, typeRaw: String, severityRaw: String, confidence: Double, timestamp: Date, latitude: Double, longitude: Double, metadataData: Data) {
        self.id = id
        self.driveID = driveID
        self.typeRaw = typeRaw
        self.severityRaw = severityRaw
        self.confidence = confidence
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.metadataData = metadataData
    }
}

extension DrivingEventRecord {
    convenience init(event: DrivingEvent) {
        let encoder = JSONEncoder()
        self.init(
            id: event.id,
            driveID: event.driveID,
            typeRaw: event.type.rawValue,
            severityRaw: event.severity.rawValue,
            confidence: event.confidence,
            timestamp: event.timestamp,
            latitude: event.coordinate.latitude,
            longitude: event.coordinate.longitude,
            metadataData: (try? encoder.encode(event.metadata)) ?? Data()
        )
    }

    var domainModel: DrivingEvent {
        let decoder = JSONDecoder()
        return DrivingEvent(
            id: id,
            driveID: driveID,
            type: DrivingEventType(rawValue: typeRaw) ?? .hardBrake,
            severity: DrivingEventSeverity(rawValue: severityRaw) ?? .low,
            confidence: confidence,
            timestamp: timestamp,
            coordinate: GeoCoordinate(latitude: latitude, longitude: longitude),
            metadata: (try? decoder.decode([String: Double].self, from: metadataData)) ?? [:]
        )
    }
}
