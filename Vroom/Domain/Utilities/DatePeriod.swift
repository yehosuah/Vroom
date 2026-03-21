import Foundation

extension InsightPeriod {
    func startDate(from now: Date, calendar: Calendar = .current) -> Date {
        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        }
    }
}
