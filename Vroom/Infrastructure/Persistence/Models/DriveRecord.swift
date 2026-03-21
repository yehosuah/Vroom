import Foundation
import SwiftData

@Model
final class DriveRecord {
    @Attribute(.unique) var id: UUID
    var vehicleID: UUID?
    var startedAt: Date
    var endedAt: Date
    var distanceMeters: Double
    var duration: Double
    var avgSpeedKPH: Double
    var topSpeedKPH: Double
    var favorite: Bool
    var overallScore: Int
    var scoreSubscoresData: Data
    var scoreDeductionsData: Data
    var scoreProfileID: String
    var traceRef: String
    var summaryTitle: String
    var summaryHighlight: String
    var summaryEventCount: Int

    init(id: UUID, vehicleID: UUID?, startedAt: Date, endedAt: Date, distanceMeters: Double, duration: Double, avgSpeedKPH: Double, topSpeedKPH: Double, favorite: Bool, overallScore: Int, scoreSubscoresData: Data, scoreDeductionsData: Data, scoreProfileID: String, traceRef: String, summaryTitle: String, summaryHighlight: String, summaryEventCount: Int) {
        self.id = id
        self.vehicleID = vehicleID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.distanceMeters = distanceMeters
        self.duration = duration
        self.avgSpeedKPH = avgSpeedKPH
        self.topSpeedKPH = topSpeedKPH
        self.favorite = favorite
        self.overallScore = overallScore
        self.scoreSubscoresData = scoreSubscoresData
        self.scoreDeductionsData = scoreDeductionsData
        self.scoreProfileID = scoreProfileID
        self.traceRef = traceRef
        self.summaryTitle = summaryTitle
        self.summaryHighlight = summaryHighlight
        self.summaryEventCount = summaryEventCount
    }
}

extension DriveRecord {
    convenience init(drive: Drive) {
        let encoder = JSONEncoder()
        self.init(
            id: drive.id,
            vehicleID: drive.vehicleID,
            startedAt: drive.startedAt,
            endedAt: drive.endedAt,
            distanceMeters: drive.distanceMeters,
            duration: drive.duration,
            avgSpeedKPH: drive.avgSpeedKPH,
            topSpeedKPH: drive.topSpeedKPH,
            favorite: drive.favorite,
            overallScore: drive.scoreSummary.overall,
            scoreSubscoresData: (try? encoder.encode(drive.scoreSummary.subscores)) ?? Data(),
            scoreDeductionsData: (try? encoder.encode(drive.scoreSummary.deductions)) ?? Data(),
            scoreProfileID: drive.scoreSummary.profileID,
            traceRef: drive.traceRef,
            summaryTitle: drive.summary.title,
            summaryHighlight: drive.summary.highlight,
            summaryEventCount: drive.summary.eventCount
        )
    }

    var domainModel: Drive {
        let decoder = JSONDecoder()
        let subscores = (try? decoder.decode([String: Int].self, from: scoreSubscoresData)) ?? [:]
        let deductions = (try? decoder.decode([String: Int].self, from: scoreDeductionsData)) ?? [:]
        return Drive(
            id: id,
            vehicleID: vehicleID,
            startedAt: startedAt,
            endedAt: endedAt,
            distanceMeters: distanceMeters,
            duration: duration,
            avgSpeedKPH: avgSpeedKPH,
            topSpeedKPH: topSpeedKPH,
            favorite: favorite,
            scoreSummary: DriveScoreSummary(overall: overallScore, subscores: subscores, deductions: deductions, profileID: scoreProfileID),
            traceRef: traceRef,
            summary: DriveSummary(title: summaryTitle, highlight: summaryHighlight, eventCount: summaryEventCount)
        )
    }
}
