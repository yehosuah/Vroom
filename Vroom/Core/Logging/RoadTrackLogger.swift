import Foundation
import OSLog

struct RoadTrackLogger: Sendable {
    private let logger: Logger

    init(category: String) {
        logger = Logger(subsystem: "yehosuahercules.Vroom", category: category)
    }

    func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
