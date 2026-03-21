import CoreGraphics
import Foundation

#if canImport(UIKit)
import UIKit
#endif

struct DefaultMapRenderingService: MapRenderingService {
    private let summaryBuilder = DriveSummaryBuilder()

    func summary(for trace: [RoutePointSample], events: [DrivingEvent]) async -> DriveSummary {
        summaryBuilder.makeSummary(trace: trace, events: events)
    }

    func presentation(for trace: [RoutePointSample], events: [DrivingEvent]) async -> RoutePresentation {
        RoutePresentationBuilder.build(trace: trace, events: events)
    }

    func renderRouteThumbnail(for trace: [RoutePointSample], events: [DrivingEvent], size: CGSize) async -> Data? {
        guard size.width > 0, size.height > 0, !trace.isEmpty else { return nil }
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            let colors = [
                UIColor(red: 0.07, green: 0.08, blue: 0.11, alpha: 1).cgColor,
                UIColor(red: 0.12, green: 0.14, blue: 0.18, alpha: 1).cgColor
            ] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
            cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            cgContext.setShadow(offset: .zero, blur: 22, color: UIColor(red: 0.42, green: 0.73, blue: 1.0, alpha: 0.35).cgColor)
            cgContext.setStrokeColor(UIColor(red: 0.42, green: 0.73, blue: 1.0, alpha: 1).cgColor)
            cgContext.setLineWidth(7)
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)

            let bounds = trace.geoBounds
            func point(for coordinate: GeoCoordinate) -> CGPoint {
                let xRange = max(bounds.maxLongitude - bounds.minLongitude, 0.00001)
                let yRange = max(bounds.maxLatitude - bounds.minLatitude, 0.00001)
                let x = ((coordinate.longitude - bounds.minLongitude) / xRange) * (size.width - 160) + 80
                let y = size.height - (((coordinate.latitude - bounds.minLatitude) / yRange) * (size.height - 160) + 80)
                return CGPoint(x: x, y: y)
            }

            if let first = trace.first {
                cgContext.move(to: point(for: first.coordinate))
                for sample in trace.dropFirst() {
                    cgContext.addLine(to: point(for: sample.coordinate))
                }
                cgContext.strokePath()
            }

            cgContext.setShadow(offset: .zero, blur: 12, color: UIColor(red: 0.95, green: 0.39, blue: 0.34, alpha: 0.35).cgColor)
            for event in events {
                let point = point(for: event.coordinate)
                cgContext.setFillColor(UIColor(red: 0.95, green: 0.39, blue: 0.34, alpha: 1).cgColor)
                cgContext.fillEllipse(in: CGRect(x: point.x - 6, y: point.y - 6, width: 12, height: 12))
            }

            if let start = trace.first {
                let startPoint = point(for: start.coordinate)
                cgContext.setFillColor(UIColor(red: 0.27, green: 0.82, blue: 0.57, alpha: 1).cgColor)
                cgContext.fillEllipse(in: CGRect(x: startPoint.x - 8, y: startPoint.y - 8, width: 16, height: 16))
            }

            if let end = trace.last {
                let endPoint = point(for: end.coordinate)
                cgContext.setFillColor(UIColor(red: 0.98, green: 0.66, blue: 0.22, alpha: 1).cgColor)
                cgContext.fillEllipse(in: CGRect(x: endPoint.x - 8, y: endPoint.y - 8, width: 16, height: 16))
            }
        }
        return image.pngData()
        #else
        return nil
        #endif
    }
}
