import Foundation

// PatternEngine runs purely on CPU — no concurrency needed for small datasets.
// Made a class so ViewModels can hold a reference across the session.
final class PatternEngine {

    // MARK: - Public API

    func analyze(_ checkIns: [WeeklyCheckIn]) -> [ZoneInsight] {
        guard !checkIns.isEmpty else { return [] }
        let sorted = checkIns.sorted { $0.weekStartDate < $1.weekStartDate }

        var insights: [ZoneInsight] = []

        insights += correlationInsights(sorted)
        insights += trendInsights(sorted)
        insights += drainInsights(sorted)
        insights += weekdayPatternInsights(sorted)
        if let latest = sorted.last { insights += recoveryInsights(latest) }

        return deduplicated(insights)
    }

    // MARK: - Correlation

    private func correlationInsights(_ sorted: [WeeklyCheckIn]) -> [ZoneInsight] {
        guard sorted.count >= 4 else { return [] }
        var results: [ZoneInsight] = []
        let ids = ZoneID.allCases

        for i in 0..<ids.count {
            for j in (i+1)..<ids.count {
                let a = ids[i], b = ids[j]
                let seriesA = sorted.map { Double($0.score(for: a)) }
                let seriesB = sorted.map { Double($0.score(for: b)) }
                let r = pearson(seriesA, seriesB)

                guard abs(r) > 0.65 else { continue }
                let weekRange = sorted.first!.weekStartDate...sorted.last!.weekStartDate
                let high = r > 0 ? a : b
                let low  = r > 0 ? b : a

                let body: String
                let avgA = Int(seriesA.suffix(4).reduce(0,+) / 4)

                if r > 0 {
                    body = "Every time your \(high.displayName) rises above \(avgA), your \(low.displayName) tends to follow within a week."
                } else {
                    body = "\(a.displayName) and \(b.displayName) consistently move in opposite directions — when one peaks, the other dips."
                }

                results.append(ZoneInsight(
                    type: .correlation,
                    zoneIDs: [a.rawValue, b.rawValue],
                    body: body,
                    weekRange: weekRange
                ))
            }
        }
        return results
    }

    // MARK: - Trend

    private func trendInsights(_ sorted: [WeeklyCheckIn]) -> [ZoneInsight] {
        let window = Array(sorted.suffix(4))
        guard window.count >= 3 else { return [] }
        var results: [ZoneInsight] = []
        let weekRange = window.first!.weekStartDate...window.last!.weekStartDate

        for id in ZoneID.allCases {
            let series = window.map { Double($0.score(for: id)) }
            let slope = linearSlope(series)

            if slope < -0.8 {
                let n = window.count
                results.append(ZoneInsight(
                    type: .warning,
                    zoneIDs: [id.rawValue],
                    body: "\(id.displayName) has been declining for \(n) weeks. It's now at its lowest this period.",
                    weekRange: weekRange
                ))
            } else if slope > 0.8 {
                results.append(ZoneInsight(
                    type: .positive,
                    zoneIDs: [id.rawValue],
                    body: "\(id.displayName) is on a \(window.count)-week upward run. Something is working — notice what's changed.",
                    weekRange: weekRange
                ))
            }
        }
        return results
    }

    // MARK: - Drain

    private func drainInsights(_ sorted: [WeeklyCheckIn]) -> [ZoneInsight] {
        guard sorted.count >= 3 else { return [] }
        var results: [ZoneInsight] = []
        let ids = ZoneID.allCases
        let weekRange = sorted.first!.weekStartDate...sorted.last!.weekStartDate

        for i in 0..<ids.count {
            for j in 0..<ids.count where i != j {
                let peak = ids[i], drain = ids[j]
                var occurrences = 0

                for k in 1..<sorted.count {
                    let prev = sorted[k-1], curr = sorted[k]
                    if curr.score(for: peak) >= 8 &&
                       curr.score(for: drain) <= prev.score(for: drain) - 2 {
                        occurrences += 1
                    }
                }

                guard occurrences >= 2 else { continue }
                results.append(ZoneInsight(
                    type: .correlation,
                    zoneIDs: [peak.rawValue, drain.rawValue],
                    body: "\(peak.displayName) peaking may be drawing energy from \(drain.displayName) — they've moved opposite for \(occurrences) weeks.",
                    weekRange: weekRange
                ))
            }
        }
        return results
    }

    // MARK: - Weekday pattern

    /// If the user checks in on different weekdays across history, see if any
    /// weekday's overall average is meaningfully above/below the others.
    /// Fires when one weekday is ≥1.0 lower or higher than the global mean
    /// AND has been used at least 3 times.
    private func weekdayPatternInsights(_ sorted: [WeeklyCheckIn]) -> [ZoneInsight] {
        guard sorted.count >= 6 else { return [] }

        var byWeekday: [Int: [Double]] = [:]
        let cal = Calendar.current
        for c in sorted {
            let day = cal.component(.weekday, from: c.createdAt) // 1=Sun..7=Sat
            byWeekday[day, default: []].append(c.overallAverage)
        }

        let globalAvg = sorted.map(\.overallAverage).reduce(0, +) / Double(sorted.count)

        var results: [ZoneInsight] = []
        let weekRange = sorted.first!.weekStartDate...sorted.last!.weekStartDate

        for (weekday, values) in byWeekday {
            guard values.count >= 3 else { continue }
            let avg = values.reduce(0, +) / Double(values.count)
            let delta = avg - globalAvg
            guard abs(delta) >= 1.0 else { continue }

            let weekdayName = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"][weekday - 1]
            let body: String
            if delta < 0 {
                body = "Your \(weekdayName) check-ins run lower than other weekdays — average \(String(format: "%.1f", avg)) vs \(String(format: "%.1f", globalAvg)) overall."
            } else {
                body = "\(weekdayName) tends to be your best check-in day — running \(String(format: "%.1f", avg)) on average."
            }
            results.append(ZoneInsight(
                type: .trend,
                zoneIDs: [],
                body: body,
                weekRange: weekRange
            ))
            // Only surface one weekday pattern at a time
            break
        }
        return results
    }

    // MARK: - Recovery

    private func recoveryInsights(_ latest: WeeklyCheckIn) -> [ZoneInsight] {
        let belowFive = ZoneID.allCases.filter { latest.score(for: $0) < 5 }
        guard belowFive.count >= 5 else { return [] }
        let weekRange = latest.weekStartDate...latest.weekStartDate
        return [ZoneInsight(
            type: .warning,
            zoneIDs: belowFive.map(\.rawValue),
            body: "Most zones are below 5 this week. Consider this a recalibration week, not a failure.",
            weekRange: weekRange
        )]
    }

    // MARK: - Math

    private func pearson(_ x: [Double], _ y: [Double]) -> Double {
        let n = Double(x.count)
        guard n > 1 else { return 0 }
        let mx = x.reduce(0,+) / n
        let my = y.reduce(0,+) / n
        let num = zip(x, y).reduce(0.0) { $0 + ($1.0 - mx) * ($1.1 - my) }
        let dx  = x.reduce(0.0) { $0 + pow($1 - mx, 2) }
        let dy  = y.reduce(0.0) { $0 + pow($1 - my, 2) }
        let den = sqrt(dx * dy)
        return den == 0 ? 0 : num / den
    }

    private func linearSlope(_ y: [Double]) -> Double {
        let n = Double(y.count)
        guard n > 1 else { return 0 }
        let x = (0..<y.count).map { Double($0) }
        let mx = x.reduce(0,+) / n
        let my = y.reduce(0,+) / n
        let num = zip(x, y).reduce(0.0) { $0 + ($1.0 - mx) * ($1.1 - my) }
        let den = x.reduce(0.0) { $0 + pow($1 - mx, 2) }
        return den == 0 ? 0 : num / den
    }

    // MARK: - Deduplication

    private func deduplicated(_ insights: [ZoneInsight]) -> [ZoneInsight] {
        var seen = Set<String>()
        let sorted = insights.sorted {
            typeOrder($0.type) < typeOrder($1.type)
        }
        return sorted.filter { insight in
            let key = "\(insight.typeRaw)_\(insight.zoneIDs.sorted().joined())"
            return seen.insert(key).inserted
        }
    }

    private func typeOrder(_ type: InsightType) -> Int {
        switch type {
        case .warning:     return 0
        case .positive:    return 1
        case .correlation: return 2
        case .trend:       return 3
        }
    }

    // MARK: - Correlation strength (0–1) for zone connection web

    func correlationStrength(between a: ZoneID, and b: ZoneID, in checkIns: [WeeklyCheckIn]) -> Double {
        guard checkIns.count >= 4 else { return 0 }
        let seriesA = checkIns.map { Double($0.score(for: a)) }
        let seriesB = checkIns.map { Double($0.score(for: b)) }
        return abs(pearson(seriesA, seriesB))
    }
}
