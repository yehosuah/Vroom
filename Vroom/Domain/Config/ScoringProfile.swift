import Foundation

struct ScoringProfile: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var thresholdOverrides: [String: Double]
    var weightOverrides: [String: Double]

    static let casual = ScoringProfile(
        id: "casual",
        name: "Casual",
        thresholdOverrides: [:],
        weightOverrides: [
            "hardBrake": 6,
            "hardAcceleration": 4,
            "cornering": 3,
            "gForceSpike": 8
        ]
    )

    static let spirited = ScoringProfile(
        id: "spirited",
        name: "Spirited",
        thresholdOverrides: [
            "hardBrake": 16,
            "hardAcceleration": 14,
            "cornering": 0.7,
            "gForceSpike": 0.9
        ],
        weightOverrides: [
            "hardBrake": 4,
            "hardAcceleration": 3,
            "cornering": 2,
            "gForceSpike": 6
        ]
    )
}
