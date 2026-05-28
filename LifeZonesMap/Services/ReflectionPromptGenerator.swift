import Foundation

/// Generates a single, data-aware reflection prompt for the just-saved check-in.
/// The prompt should be specific (mentions a real zone or pattern from the user's
/// data), open-ended (no yes/no), and never judgmental.
enum ReflectionPromptGenerator {

    static func prompt(for checkIn: WeeklyCheckIn, history: [WeeklyCheckIn]) -> String {
        let scoresByZone = ZoneID.allCases.map { ($0, checkIn.score(for: $0)) }
        let sorted = scoresByZone.sorted { $0.1 > $1.1 }
        let highest = sorted.first
        let lowest = sorted.last

        // Look for the biggest week-over-week mover.
        let priorWeek = history
            .sorted { $0.weekStartDate > $1.weekStartDate }
            .first { $0.weekStartDate < checkIn.weekStartDate }

        if let prior = priorWeek {
            let deltas = ZoneID.allCases.map { zone -> (ZoneID, Int) in
                (zone, checkIn.score(for: zone) - prior.score(for: zone))
            }
            if let mover = deltas.max(by: { abs($0.1) < abs($1.1) }), abs(mover.1) >= 2 {
                let def = ZoneRegistry.definition(for: mover.0)
                if mover.1 > 0 {
                    return "\(def.name) rose by \(mover.1) this week. What changed?"
                } else {
                    return "\(def.name) dropped by \(abs(mover.1)). Anything worth naming?"
                }
            }
        }

        // No big mover — fall back to extremes from this week.
        if let high = highest, high.1 >= 8 {
            let def = ZoneRegistry.definition(for: high.0)
            return "\(def.name) sits at \(high.1). What's been working there?"
        }
        if let low = lowest, low.1 <= 4 {
            let def = ZoneRegistry.definition(for: low.0)
            return "\(def.name) is at \(low.1) this week. What would a 6 look like?"
        }

        // Steady-state seeds — a small rotating pool.
        let neutral = [
            "If next week was a 9, what one thing would have happened?",
            "What did this week ask of you that you weren't expecting?",
            "Where did you notice yourself paying attention?",
            "What's a small thing from this week you'd like to remember?"
        ]
        let idx = abs(checkIn.weekStartDate.hashValue) % neutral.count
        return neutral[idx]
    }
}
