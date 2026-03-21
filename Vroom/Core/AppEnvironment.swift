import Foundation

struct AppEnvironment: Sendable {
    var clock: any AppClock
    var uuidGenerator: any UUIDGenerating

    static let live = AppEnvironment(
        clock: SystemClock(),
        uuidGenerator: UUIDGenerator()
    )
}
