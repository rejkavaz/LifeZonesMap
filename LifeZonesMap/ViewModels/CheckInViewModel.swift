import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class CheckInViewModel {
    var scores: [ZoneID: Int]   = Dictionary(uniqueKeysWithValues: ZoneID.allCases.map { ($0, 5) })
    var tags:   [ZoneID: String] = [:]
    var notes:  [ZoneID: String] = [:]
    var isSubmitting = false
    var submittedCheckIn: WeeklyCheckIn?
    var error: String?
    var alreadyCheckedIn = false
    var existingCheckIn: WeeklyCheckIn?

    private var service: CheckInService?
    private var patternEngine = PatternEngine()

    func setup(modelContext: ModelContext) {
        service = CheckInService(modelContext: modelContext)
        checkCurrentWeek(modelContext: modelContext)
    }

    func checkCurrentWeek(modelContext: ModelContext) {
        let svc = service ?? CheckInService(modelContext: modelContext)
        if let existing = try? svc.currentWeekCheckIn() {
            alreadyCheckedIn = true
            existingCheckIn = existing
            for zone in ZoneID.allCases {
                scores[zone] = existing.score(for: zone)
            }
        }
    }

    var allZonesRated: Bool {
        ZoneID.allCases.allSatisfy { scores[$0] != nil }
    }

    func setScore(_ score: Int, for zone: ZoneID) {
        scores[zone] = max(1, min(10, score))
    }

    func toggleTag(_ tag: String, for zone: ZoneID) {
        if tags[zone] == tag { tags[zone] = nil } else { tags[zone] = tag }
    }

    func submit(modelContext: ModelContext) async {
        guard allZonesRated, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        let svc = service ?? CheckInService(modelContext: modelContext)
        do {
            let checkIn = try svc.save(scores: scores, tags: tags, notes: notes)
            submittedCheckIn = checkIn
            alreadyCheckedIn = true
            existingCheckIn  = checkIn

            // Run pattern analysis in background
            let allCheckIns = (try? svc.fetchAll()) ?? []
            let _ = patternEngine.analyze(allCheckIns)

            await NotificationScheduler.shared.cancelIfCheckedIn()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deltas(for checkIn: WeeklyCheckIn, modelContext: ModelContext) -> [ZoneID: Int] {
        let svc = service ?? CheckInService(modelContext: modelContext)
        var result: [ZoneID: Int] = [:]
        for zone in ZoneID.allCases {
            result[zone] = try? svc.deltaFromLastWeek(for: zone, current: checkIn)
        }
        return result
    }
}
