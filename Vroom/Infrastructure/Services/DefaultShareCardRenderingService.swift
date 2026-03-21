import CoreGraphics
import Foundation

struct DefaultShareCardRenderingService: ShareCardRenderingService {
    private let mapRenderingService: any MapRenderingService

    init(mapRenderingService: any MapRenderingService) {
        self.mapRenderingService = mapRenderingService
    }

    func renderPayload(for drive: Drive, trace: [RoutePointSample], events: [DrivingEvent]) async -> SharePayload {
        let summary = await mapRenderingService.summary(for: trace, events: events)
        let imageData = await mapRenderingService.renderRouteThumbnail(for: trace, events: events, size: CGSize(width: 1200, height: 630))
        let imageURL: URL?
        if let imageData {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("share-\(drive.id.uuidString).png")
            try? imageData.write(to: url, options: .atomic)
            imageURL = url
        } else {
            imageURL = nil
        }

        return SharePayload(
            text: "\(summary.title) • \(String(format: "%.1f km", drive.distanceMeters / 1000)) • Avg \(String(format: "%.0f", drive.avgSpeedKPH)) kph • Top \(String(format: "%.0f", drive.topSpeedKPH)) kph • \(events.count) events",
            imageURL: imageURL
        )
    }
}
