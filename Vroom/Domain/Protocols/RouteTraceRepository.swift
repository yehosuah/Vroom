import Foundation

protocol RouteTraceRepository: Sendable {
    func openWriter(for driveID: UUID) async throws -> RouteTraceWriterHandle
    func append(sample: RoutePointSample, to handle: RouteTraceWriterHandle) async throws
    func finalize(handle: RouteTraceWriterHandle) async throws -> RouteTrace
    func loadTrace(for driveID: UUID) async throws -> [RoutePointSample]
}
