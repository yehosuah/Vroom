import Foundation

#if canImport(UIKit)
import UIKit
#endif

final class UIApplicationBackgroundExecutionService: BackgroundExecutionService {
    #if canImport(UIKit)
    private let store = BackgroundTaskStore()
    #endif

    func beginTrackingSession(name: String) async -> UUID {
        let id = UUID()
        #if canImport(UIKit)
        let task = await MainActor.run {
            UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
                Task {
                    await self?.endTrackingSession(id: id)
                }
            }
        }
        await store.set(task, for: id)
        #endif
        return id
    }

    func endTrackingSession(id: UUID) async {
        #if canImport(UIKit)
        let task = await store.removeTask(for: id)
        guard task != .invalid else { return }
        await MainActor.run {
            UIApplication.shared.endBackgroundTask(task)
        }
        #endif
    }
}

#if canImport(UIKit)
private actor BackgroundTaskStore {
    private var tasks: [UUID: UIBackgroundTaskIdentifier] = [:]

    func set(_ task: UIBackgroundTaskIdentifier, for id: UUID) {
        tasks[id] = task
    }

    func removeTask(for id: UUID) -> UIBackgroundTaskIdentifier {
        tasks.removeValue(forKey: id) ?? .invalid
    }
}
#endif
