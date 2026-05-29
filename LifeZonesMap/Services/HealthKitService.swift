import Foundation
import HealthKit
import OSLog

private let hkLog = Logger(subsystem: "com.rejkavaz.LifeZonesMap", category: "HealthKit")

/// Read-only HealthKit access used to suggest a Vitality score on the Check-In
/// screen. Never writes. All four signals are optional — the suggestion just
/// uses what's available.
///
/// Signals (last 7 days):
///   • Sleep duration         — target 7.5h ± tolerance
///   • Sleep consistency      — low variance across nights
///   • Active minutes / steps — target ≥ 7,000 steps/day
///   • Mindful minutes        — target ≥ 10 min/day
@MainActor
final class HealthKitService {
    static let shared = HealthKitService()
    private let store = HKHealthStore()

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var readTypes: Set<HKObjectType> {
        var set: Set<HKObjectType> = []
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            set.insert(sleep)
        }
        if let mindful = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            set.insert(mindful)
        }
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
            set.insert(steps)
        }
        if let rhr = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            set.insert(rhr)
        }
        return set
    }

    func requestPermission() async -> Bool {
        guard Self.isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            return true
        } catch {
            hkLog.error("HK auth failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    // MARK: - Composite Vitality score

    struct VitalitySuggestion {
        let score: Int             // 1...10
        let confidence: Double     // 0...1, depends on how many signals we got
        let breakdown: [String]    // human-readable components
    }

    func suggestVitalityScore() async -> VitalitySuggestion? {
        guard Self.isAvailable else { return nil }
        async let sleep   = avgSleepHoursLast7Days()
        async let consis  = sleepConsistencyLast7Days()
        async let steps   = avgStepsLast7Days()
        async let mindful = avgMindfulMinutesLast7Days()

        let s = await sleep
        let c = await consis
        let st = await steps
        let m = await mindful

        // Component scores 0–1 each
        var components: [Double] = []
        var breakdown: [String] = []

        if let s {
            let score = sleepScore(hours: s)
            components.append(score)
            breakdown.append("Sleep \(String(format: "%.1f", s))h")
        }
        if let c {
            // c is std-dev in hours; less is better. 0h std = 1.0 score; 2h+ std = 0.
            let score = max(0, min(1, 1 - c / 2.0))
            components.append(score)
            breakdown.append("Consistency σ\(String(format: "%.1f", c))h")
        }
        if let st {
            let score = min(1, Double(st) / 7000)
            components.append(score)
            breakdown.append("\(Int(st))/day steps")
        }
        if let m, m > 0 {
            let score = min(1, m / 10)
            components.append(score)
            breakdown.append("\(Int(m))min mindful")
        }

        guard !components.isEmpty else { return nil }
        let mean = components.reduce(0, +) / Double(components.count)
        let score10 = max(1, min(10, Int((mean * 9) + 1)))
        let confidence = Double(components.count) / 4.0  // 4 possible signals
        return VitalitySuggestion(
            score: score10,
            confidence: confidence,
            breakdown: breakdown
        )
    }

    // MARK: - Scoring helpers

    /// 7-9h sleep gets 1.0, falls off symmetrically toward 5h and 11h.
    private func sleepScore(hours: Double) -> Double {
        let target: Double = 8.0
        let dist = abs(hours - target)
        return max(0, min(1, 1 - dist / 4))
    }

    // MARK: - Queries

    private func dateRange(daysBack: Int) -> (start: Date, end: Date) {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -daysBack, to: end) ?? end
        return (start, end)
    }

    private func avgSleepHoursLast7Days() async -> Double? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let (start, end) = dateRange(daysBack: 7)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { (cont: CheckedContinuation<Double?, Never>) in
            let query = HKSampleQuery(
                sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    cont.resume(returning: nil); return
                }
                let asleep = samples.filter { s in
                    if #available(iOS 16, *) {
                        return s.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                            || s.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue
                            || s.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                            || s.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                    }
                    return false
                }
                let totalSeconds = asleep.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                let nights = 7.0
                let hours = (totalSeconds / 3600) / nights
                cont.resume(returning: hours > 0 ? hours : nil)
            }
            store.execute(query)
        }
    }

    private func sleepConsistencyLast7Days() async -> Double? {
        // Standard deviation of nightly sleep hours. nil if < 3 nights.
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let (start, end) = dateRange(daysBack: 7)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { (cont: CheckedContinuation<Double?, Never>) in
            let query = HKSampleQuery(
                sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    cont.resume(returning: nil); return
                }
                // Group asleep samples by night
                var perNight: [Date: TimeInterval] = [:]
                let cal = Calendar.current
                for s in samples {
                    if #available(iOS 16, *) {
                        let isAsleep = s.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                            || s.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue
                            || s.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                            || s.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                        guard isAsleep else { continue }
                    }
                    let night = cal.startOfDay(for: s.startDate)
                    perNight[night, default: 0] += s.endDate.timeIntervalSince(s.startDate)
                }
                let hoursList = perNight.values.map { $0 / 3600 }
                guard hoursList.count >= 3 else { cont.resume(returning: nil); return }
                let mean = hoursList.reduce(0, +) / Double(hoursList.count)
                let variance = hoursList.map { pow($0 - mean, 2) }.reduce(0, +) / Double(hoursList.count)
                cont.resume(returning: sqrt(variance))
            }
            store.execute(query)
        }
    }

    private func avgStepsLast7Days() async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .stepCount) else { return nil }
        let (start, end) = dateRange(daysBack: 7)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { (cont: CheckedContinuation<Double?, Never>) in
            let query = HKStatisticsQuery(
                quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum
            ) { _, stats, _ in
                guard let sum = stats?.sumQuantity()?.doubleValue(for: .count()) else {
                    cont.resume(returning: nil); return
                }
                cont.resume(returning: sum / 7)
            }
            store.execute(query)
        }
    }

    private func avgMindfulMinutesLast7Days() async -> Double? {
        guard let type = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return nil }
        let (start, end) = dateRange(daysBack: 7)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { (cont: CheckedContinuation<Double?, Never>) in
            let query = HKSampleQuery(
                sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    cont.resume(returning: nil); return
                }
                let totalSeconds = samples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                let avgPerDay = (totalSeconds / 60) / 7
                cont.resume(returning: avgPerDay > 0 ? avgPerDay : nil)
            }
            store.execute(query)
        }
    }
}
