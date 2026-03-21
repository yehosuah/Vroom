import Foundation

protocol ShareCardRenderingService: Sendable {
    func renderPayload(for drive: Drive, trace: [RoutePointSample], events: [DrivingEvent]) async -> SharePayload
}
