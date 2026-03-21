import CoreGraphics
import Foundation

struct BasicShareCardRenderingService: ShareCardRenderingService {
    func renderPayload(for drive: Drive, trace: [RoutePointSample], events: [DrivingEvent]) async -> SharePayload {
        await DefaultShareCardRenderingService(mapRenderingService: DefaultMapRenderingService())
            .renderPayload(for: drive, trace: trace, events: events)
    }
}
