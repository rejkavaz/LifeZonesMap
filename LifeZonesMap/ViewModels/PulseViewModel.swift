import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class PulseViewModel {
    var checkIns: [WeeklyCheckIn] = []
    /// Prior 28-day window, for the comparison overlay on the trend chart.
    var priorCheckIns: [WeeklyCheckIn] = []
    var insights: [ZoneInsight]   = []
    /// All-time check-in count — used by MilestoneRibbon. Loaded separately
    /// because the rolling-28-day window doesn't include older history.
    var totalCheckInCount = 0
    var isLoading = false

    private let engine = PatternEngine()

    func load(modelContext: ModelContext) {
        isLoading = true
        let service = CheckInService(modelContext: modelContext)
        checkIns = (try? service.fetchLast28Days()) ?? []
        priorCheckIns = (try? service.fetchPrior28Days()) ?? []
        totalCheckInCount = (try? service.fetchAll().count) ?? 0
        insights = engine.analyze(checkIns)
        isLoading = false
    }

    // MARK: - Stats

    var overallAverage: Double {
        guard !checkIns.isEmpty else { return 0 }
        let all = checkIns.flatMap { $0.scores.values }
        return all.isEmpty ? 0 : Double(all.reduce(0,+)) / Double(all.count)
    }

    var mostImprovedZone: (ZoneID, Int)? {
        guard checkIns.count >= 2 else { return nil }
        let sorted = checkIns.sorted { $0.weekStartDate < $1.weekStartDate }
        let first = sorted.first!, last = sorted.last!
        return ZoneID.allCases
            .map { ($0, last.score(for: $0) - first.score(for: $0)) }
            .max(by: { $0.1 < $1.1 })
    }

    var mostConsistentZone: (ZoneID, Double)? {
        guard checkIns.count >= 2 else { return nil }
        return ZoneID.allCases
            .map { zone -> (ZoneID, Double) in
                let scores = checkIns.map { Double($0.score(for: zone)) }
                let mean = scores.reduce(0,+) / Double(scores.count)
                let variance = scores.map { pow($0 - mean, 2) }.reduce(0,+) / Double(scores.count)
                return (zone, sqrt(variance))
            }
            .min(by: { $0.1 < $1.1 })
    }

    var periodLabel: String {
        guard let latest = checkIns.last else { return "" }
        let df = DateFormatter(); df.dateFormat = "MMMM yyyy"
        return df.string(from: latest.weekStartDate)
    }

    func correlationStrength(between a: ZoneID, and b: ZoneID) -> Double {
        engine.correlationStrength(between: a, and: b, in: checkIns)
    }

    func dismiss(insight: ZoneInsight) {
        insight.dismissed = true
        insights.removeAll { $0.id == insight.id }
    }
}
