import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class MapViewModel {
    var scores: [ZoneID: Int] = Dictionary(uniqueKeysWithValues: ZoneID.allCases.map { ($0, 5) })
    /// Previous-week scores (most recent check-in before this ISO week).
    /// nil when there's no prior data — MapView hides the overlay toggle.
    var previousScores: [ZoneID: Int]?
    var selectedZone: ZoneID?
    var showCheckInPrompt = false
    var isLoading = false

    private var checkInService: CheckInService?

    func setup(modelContext: ModelContext) {
        checkInService = CheckInService(modelContext: modelContext)
        loadCurrentWeek()
    }

    func loadCurrentWeek() {
        guard let service = checkInService else { return }
        if let checkIn = try? service.currentWeekCheckIn() {
            for zone in ZoneID.allCases {
                scores[zone] = checkIn.score(for: zone)
            }
        }
        previousScores = try? service.previousWeekScores()
    }

    func selectZone(_ zone: ZoneID) {
        selectedZone = zone
    }

    var overallAverage: Double {
        let vals = scores.values
        guard !vals.isEmpty else { return 0 }
        return Double(vals.reduce(0,+)) / Double(vals.count)
    }

    // Demo scores for onboarding animation
    static func demoScores() -> [ZoneID: Int] {
        [.vitality: 7, .deepWork: 8, .connection: 6, .innerWorld: 5, .creation: 9, .foundation: 6, .growth: 7]
    }
}
