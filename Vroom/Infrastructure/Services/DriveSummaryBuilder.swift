import Foundation

struct DriveSummaryBuilder: Sendable {
    func makeSummary(trace: [RoutePointSample], events: [DrivingEvent]) -> DriveSummary {
        RoadPresentationBuilder.humanDriveSummary(trace: trace, events: events)
    }
}
