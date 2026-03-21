import Foundation

protocol SyncEngine: Sendable {
    func processPendingChanges() async throws
}
