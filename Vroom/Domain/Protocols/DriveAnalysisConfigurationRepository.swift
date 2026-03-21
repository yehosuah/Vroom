import Foundation

protocol DriveAnalysisConfigurationRepository: Sendable {
    func loadConfiguration() async throws -> DriveAnalysisConfiguration
}
