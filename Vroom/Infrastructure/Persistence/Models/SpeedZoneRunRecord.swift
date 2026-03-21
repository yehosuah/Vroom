import Foundation
import SwiftData

@Model
final class SpeedZoneRunRecord {
    @Attribute(.unique) var id: UUID
    var zoneID: UUID
    var driveID: UUID
    var elapsed: Double
    var entrySpeedKPH: Double
    var exitSpeedKPH: Double
    var peakSpeedKPH: Double
    var completedAt: Date

    init(id: UUID, zoneID: UUID, driveID: UUID, elapsed: Double, entrySpeedKPH: Double, exitSpeedKPH: Double, peakSpeedKPH: Double, completedAt: Date) {
        self.id = id
        self.zoneID = zoneID
        self.driveID = driveID
        self.elapsed = elapsed
        self.entrySpeedKPH = entrySpeedKPH
        self.exitSpeedKPH = exitSpeedKPH
        self.peakSpeedKPH = peakSpeedKPH
        self.completedAt = completedAt
    }
}

extension SpeedZoneRunRecord {
    convenience init(run: SpeedZoneRun) {
        self.init(
            id: run.id,
            zoneID: run.zoneID,
            driveID: run.driveID,
            elapsed: run.elapsed,
            entrySpeedKPH: run.entrySpeedKPH,
            exitSpeedKPH: run.exitSpeedKPH,
            peakSpeedKPH: run.peakSpeedKPH,
            completedAt: run.completedAt
        )
    }

    var domainModel: SpeedZoneRun {
        SpeedZoneRun(
            id: id,
            zoneID: zoneID,
            driveID: driveID,
            elapsed: elapsed,
            entrySpeedKPH: entrySpeedKPH,
            exitSpeedKPH: exitSpeedKPH,
            peakSpeedKPH: peakSpeedKPH,
            completedAt: completedAt
        )
    }
}
