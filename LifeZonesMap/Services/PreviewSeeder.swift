import Foundation
import SwiftData

/// Seeds the data store with demo content when the app is launched with
/// `--ui-preview`. Used by CI to render real screenshots of every tab.
@MainActor
enum PreviewSeeder {

    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("--ui-preview")
    }

    static func initialTab() -> AppTab {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--tab=check") { return .check }
        if args.contains("--tab=pulse") { return .pulse }
        return .map
    }

    /// Wipe and reseed the store. Safe to call on every launch.
    static func seed(in context: ModelContext) {
        // 1. Clear existing rows so re-launches are deterministic.
        if let checkIns = try? context.fetch(FetchDescriptor<WeeklyCheckIn>()) {
            checkIns.forEach(context.delete)
        }
        if let prefs = try? context.fetch(FetchDescriptor<UserPreferences>()) {
            prefs.forEach(context.delete)
        }
        if let insights = try? context.fetch(FetchDescriptor<ZoneInsight>()) {
            insights.forEach(context.delete)
        }

        // 2. Prefs — skip onboarding so the app boots into the Map tab.
        let prefs = UserPreferences()
        prefs.onboardingComplete = true
        prefs.enableHaptics = false   // no haptics in headless CI
        context.insert(prefs)

        // 3. Six weeks of demo check-ins with a gentle "things are looking up"
        //    pattern — Deep Work climbs, Inner World dips slightly, others steady.
        //    Matches the sample data in pulse-screen.jsx so the line chart looks
        //    like the design.
        let weeklyScores: [[ZoneID: Int]] = [
            [.vitality: 5, .deepWork: 7, .connection: 6, .innerWorld: 7, .creation: 6, .foundation: 7, .growth: 5],
            [.vitality: 6, .deepWork: 7, .connection: 6, .innerWorld: 6, .creation: 7, .foundation: 7, .growth: 5],
            [.vitality: 6, .deepWork: 7, .connection: 7, .innerWorld: 6, .creation: 7, .foundation: 7, .growth: 6],
            [.vitality: 7, .deepWork: 8, .connection: 7, .innerWorld: 6, .creation: 7, .foundation: 8, .growth: 6],
            [.vitality: 7, .deepWork: 8, .connection: 7, .innerWorld: 5, .creation: 8, .foundation: 8, .growth: 6],
            [.vitality: 7, .deepWork: 8, .connection: 7, .innerWorld: 6, .creation: 8, .foundation: 8, .growth: 6]
        ]
        let cal = Calendar(identifier: .iso8601)
        let now = Date()

        for (idx, scores) in weeklyScores.enumerated() {
            let weeksAgo = weeklyScores.count - 1 - idx
            let weekDate = (cal.date(byAdding: .weekOfYear, value: -weeksAgo, to: now) ?? now).isoWeekMonday
            let tags: [String: String] = idx == weeklyScores.count - 1
                ? ["vitality": "Slept well", "deepWork": "Shipped", "innerWorld": "Curious"]
                : [:]
            let notes: [String: String] = idx == weeklyScores.count - 1
                ? ["vitality": "Walked twice this week. Sleep was uneven Tuesday–Thursday but came back together by the weekend. Need to leave the laptop downstairs."]
                : [:]
            let checkIn = WeeklyCheckIn(
                weekStartDate: weekDate,
                scores: Dictionary(uniqueKeysWithValues: scores.map { ($0.key.rawValue, $0.value) }),
                tags: tags,
                notes: notes
            )
            context.insert(checkIn)
        }

        try? context.save()
    }
}
