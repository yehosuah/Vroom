import Foundation

struct DriveAnalysisConfigurationRepositoryImpl: DriveAnalysisConfigurationRepository {
    func loadConfiguration() async throws -> DriveAnalysisConfiguration {
        .default
    }
}
