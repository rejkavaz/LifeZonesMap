import Testing
import Foundation
@testable import LifeZonesMap

@Suite("PatternEngine")
struct PatternEngineTests {

    let engine = PatternEngine()

    // MARK: - Helpers

    private func makeCheckIn(weekOffset: Int, scores: [ZoneID: Int]) -> WeeklyCheckIn {
        let date = Calendar.current.date(byAdding: .weekOfYear, value: weekOffset, to: Date())!
        let checkIn = WeeklyCheckIn(
            weekStartDate: date.isoWeekMonday,
            scores: Dictionary(uniqueKeysWithValues: scores.map { ($0.key.rawValue, $0.value) })
        )
        return checkIn
    }

    // MARK: - Recovery

    @Test("Recovery insight fires when 5+ zones are below 5")
    func recoveryInsightFires() {
        let checkIns = [
            makeCheckIn(weekOffset: 0, scores: [
                .vitality: 3, .deepWork: 3, .connection: 4, .innerWorld: 2,
                .creation: 3, .foundation: 4, .growth: 5
            ])
        ]
        let insights = engine.analyze(checkIns)
        #expect(insights.contains { $0.type == .warning && $0.body.contains("recalibration") })
    }

    @Test("Recovery insight does NOT fire when fewer than 5 zones are below 5")
    func recoveryInsightDoesNotFire() {
        let checkIns = [
            makeCheckIn(weekOffset: 0, scores: [
                .vitality: 7, .deepWork: 8, .connection: 6, .innerWorld: 6,
                .creation: 7, .foundation: 4, .growth: 3
            ])
        ]
        let insights = engine.analyze(checkIns)
        #expect(!insights.contains { $0.body.contains("recalibration") })
    }

    // MARK: - Trend

    @Test("Declining trend detected after 4 weeks of descent")
    func decliningTrendDetected() {
        let checkIns = (0..<4).map { i in
            makeCheckIn(weekOffset: i, scores: [
                .vitality: 8 - i * 2, .deepWork: 7, .connection: 6,
                .innerWorld: 6, .creation: 7, .foundation: 7, .growth: 6
            ])
        }
        let insights = engine.analyze(checkIns)
        #expect(insights.contains { $0.type == .warning && $0.zoneIDs.contains(ZoneID.vitality.rawValue) })
    }

    @Test("Rising trend detected after 4 weeks of growth")
    func risingTrendDetected() {
        let checkIns = (0..<4).map { i in
            makeCheckIn(weekOffset: i, scores: [
                .vitality: 4 + i * 2, .deepWork: 5, .connection: 5,
                .innerWorld: 5, .creation: 5, .foundation: 5, .growth: 5
            ])
        }
        let insights = engine.analyze(checkIns)
        #expect(insights.contains { $0.type == .positive && $0.zoneIDs.contains(ZoneID.vitality.rawValue) })
    }

    // MARK: - Deduplication

    @Test("Duplicate zone-pair insights are removed")
    func noDuplicates() {
        let checkIns = (0..<6).map { i in
            makeCheckIn(weekOffset: i, scores: [
                .vitality: i % 2 == 0 ? 9 : 3,
                .deepWork: i % 2 == 0 ? 9 : 3,
                .connection: 5, .innerWorld: 5, .creation: 5, .foundation: 5, .growth: 5
            ])
        }
        let insights = engine.analyze(checkIns)
        let pairs = insights.map { $0.zoneIDs.sorted().joined() }
        #expect(Set(pairs).count == pairs.count)
    }

    // MARK: - Correlation strength

    @Test("Correlation strength is between 0 and 1")
    func correlationStrengthRange() {
        let checkIns = (0..<6).map { i in
            makeCheckIn(weekOffset: i, scores: Dictionary(
                uniqueKeysWithValues: ZoneID.allCases.map { ($0, Int.random(in: 1...10)) }
            ))
        }
        for a in ZoneID.allCases {
            for b in ZoneID.allCases where a != b {
                let r = engine.correlationStrength(between: a, and: b, in: checkIns)
                #expect(r >= 0 && r <= 1)
            }
        }
    }

    // MARK: - Empty / insufficient data

    @Test("Fewer than 2 check-ins produces no insights")
    func tooFewCheckIns() {
        let single = [makeCheckIn(weekOffset: 0, scores: Dictionary(
            uniqueKeysWithValues: ZoneID.allCases.map { ($0, 5) }
        ))]
        #expect(engine.analyze(single).isEmpty)
    }
}
