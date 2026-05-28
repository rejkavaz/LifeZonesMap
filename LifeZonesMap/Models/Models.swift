import Foundation
import SwiftData
import SwiftUI

// MARK: - Zone ID

enum ZoneID: String, CaseIterable, Codable, Identifiable {
    case vitality
    case deepWork
    case connection
    case innerWorld
    case creation
    case foundation
    case growth

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vitality:   return "Vitality"
        case .deepWork:   return "Deep Work"
        case .connection: return "Connection"
        case .innerWorld: return "Inner World"
        case .creation:   return "Creation"
        case .foundation: return "Foundation"
        case .growth:     return "Growth"
        }
    }
}

// MARK: - Insight Type

enum InsightType: String, Codable {
    case correlation
    case trend
    case warning
    case positive
}

enum InsightSource: String, Codable {
    case local
    case api
}

// MARK: - SwiftData Models

@Model
final class WeeklyCheckIn {
    var id: UUID
    var weekStartDate: Date
    var scores: [String: Int]
    var tags: [String: String]
    var notes: [String: String]
    var createdAt: Date

    init(
        weekStartDate: Date,
        scores: [String: Int] = [:],
        tags: [String: String] = [:],
        notes: [String: String] = [:]
    ) {
        self.id = UUID()
        self.weekStartDate = weekStartDate
        self.scores = scores
        self.tags = tags
        self.notes = notes
        self.createdAt = Date()
    }

    var overallAverage: Double {
        guard !scores.isEmpty else { return 0 }
        return Double(scores.values.reduce(0, +)) / Double(scores.count)
    }

    func score(for zone: ZoneID) -> Int {
        scores[zone.rawValue] ?? 5
    }

    func tag(for zone: ZoneID) -> String? {
        tags[zone.rawValue]
    }

    func note(for zone: ZoneID) -> String? {
        notes[zone.rawValue]
    }
}

@Model
final class ZoneInsight {
    var id: UUID
    var generatedAt: Date
    var typeRaw: String
    var sourceRaw: String
    var zoneIDs: [String]
    var body: String
    var weekRangeStart: Date
    var weekRangeEnd: Date
    var dismissed: Bool

    var type: InsightType {
        InsightType(rawValue: typeRaw) ?? .correlation
    }

    var source: InsightSource {
        InsightSource(rawValue: sourceRaw) ?? .local
    }

    init(
        type: InsightType,
        source: InsightSource = .local,
        zoneIDs: [String],
        body: String,
        weekRange: ClosedRange<Date>
    ) {
        self.id = UUID()
        self.generatedAt = Date()
        self.typeRaw = type.rawValue
        self.sourceRaw = source.rawValue
        self.zoneIDs = zoneIDs
        self.body = body
        self.weekRangeStart = weekRange.lowerBound
        self.weekRangeEnd = weekRange.upperBound
        self.dismissed = false
    }
}

/// A gentle, optional per-zone target band. "I'd like Vitality to live
/// between 6 and 8." Shown as a faint strip behind the trend chart line.
/// Never enforced, never nagged about. One row per zone (max).
@Model
final class ZoneGoal {
    var id: UUID
    var zoneIDRaw: String
    var lowerBound: Int       // 1...10
    var upperBound: Int       // 1...10, > lowerBound
    var note: String          // optional personal note
    var createdAt: Date

    var zone: ZoneID? { ZoneID(rawValue: zoneIDRaw) }

    init(zone: ZoneID, lower: Int, upper: Int, note: String = "") {
        self.id = UUID()
        self.zoneIDRaw = zone.rawValue
        self.lowerBound = max(1, min(10, lower))
        self.upperBound = max(self.lowerBound + 1, min(10, upper))
        self.note = note
        self.createdAt = Date()
    }
}

/// User's response to a single prompt from PromptLibrary. Not tied to a
/// check-in — answer any prompt, any time, as many times as you want.
@Model
final class PromptResponse {
    var id: UUID
    var promptID: String       // links to PromptLibrary.prompt(id:)
    var response: String
    var createdAt: Date

    init(promptID: String, response: String) {
        self.id = UUID()
        self.promptID = promptID
        self.response = response
        self.createdAt = Date()
    }
}

/// A lightweight one-word (+ optional sentence) mood drop between check-ins.
/// Captures fleeting state without the weight of a full check-in.
@Model
final class MoodDrop {
    var id: UUID
    var date: Date
    var mood: String           // one word, lowercased
    var detail: String         // optional sentence

    init(mood: String, detail: String = "") {
        self.id = UUID()
        self.date = Date()
        self.mood = mood.lowercased()
        self.detail = detail
    }
}

@Model
final class WeeklyReflection {
    var id: UUID
    var weekStartDate: Date
    var prompt: String
    var response: String
    var createdAt: Date

    init(weekStartDate: Date, prompt: String, response: String = "") {
        self.id = UUID()
        self.weekStartDate = weekStartDate
        self.prompt = prompt
        self.response = response
        self.createdAt = Date()
    }
}

@Model
final class UserPreferences {
    var id: UUID
    var checkInDayOfWeek: Int
    var checkInHour: Int
    var enableHaptics: Bool
    var enableInsights: Bool
    var insightAPIEnabled: Bool
    var anthropicAPIKey: String
    var customZoneNames: [String: String]
    var onboardingComplete: Bool
    var notificationsEnabled: Bool
    var hasSeenMapTip: Bool

    init() {
        self.id = UUID()
        self.checkInDayOfWeek = 0
        self.checkInHour = 19
        self.enableHaptics = true
        self.enableInsights = true
        self.insightAPIEnabled = false
        self.anthropicAPIKey = ""
        self.customZoneNames = [:]
        self.onboardingComplete = false
        self.notificationsEnabled = true
        self.hasSeenMapTip = false
    }
}

// MARK: - Date + ISO Week helpers

extension Date {
    /// Normalizes a date to the Monday 00:00:00 of its ISO week.
    var isoWeekMonday: Date {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone.current
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: components) ?? self
    }

    var isoWeekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Week of \(formatter.string(from: self))"
    }
}
