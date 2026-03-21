import Foundation
import SwiftData

enum SwiftDataContainerFactory {
    static func makeModelContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([
            UserProfileRecord.self,
            VehicleRecord.self,
            DriveRecord.self,
            DrivingEventRecord.self,
            SpeedTrapRecord.self,
            SpeedZoneRecord.self,
            SpeedZoneRunRecord.self,
            SubscriptionSnapshotRecord.self,
            AppPreferencesRecord.self,
            SyncChangeEnvelopeRecord.self,
            ConvoyCacheRecord.self,
            RoutePointRecord.self,
            ActiveDriveSessionRecord.self
        ])

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try! ModelContainer(for: schema, configurations: configuration)
    }
}
