import Foundation
import SwiftData

final class RouteTraceRepositoryImpl: @unchecked Sendable, RouteTraceRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func openWriter(for driveID: UUID) async throws -> RouteTraceWriterHandle {
        RouteTraceWriterHandle(id: UUID(), driveID: driveID)
    }

    func append(sample: RoutePointSample, to handle: RouteTraceWriterHandle) async throws {
        let context = ModelContext(container)
        let existing = try context.fetch(FetchDescriptor<RoutePointRecord>(sortBy: [SortDescriptor(\.sequence, order: .forward)]))
            .filter { $0.driveID == handle.driveID }
        context.insert(RoutePointRecord(driveID: handle.driveID, sample: sample, sequence: existing.count))
        try context.save()
    }

    func finalize(handle: RouteTraceWriterHandle) async throws -> RouteTrace {
        let trace = try await loadTrace(for: handle.driveID)
        return RouteTrace(
            driveID: handle.driveID,
            sampleCount: trace.count,
            bounds: trace.geoBounds,
            storageRef: handle.driveID.uuidString,
            compression: .none,
            quality: trace.count > 50 ? .excellent : (trace.count > 20 ? .good : .fair)
        )
    }

    func loadTrace(for driveID: UUID) async throws -> [RoutePointSample] {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<RoutePointRecord>(sortBy: [SortDescriptor(\.sequence, order: .forward)]))
            .filter { $0.driveID == driveID }
            .map(\.domainModel)
    }
}
