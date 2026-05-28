import UserNotifications
import SwiftData
import Foundation

@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private let identifier = "weekly-checkin"

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            return settings.authorizationStatus == .authorized
        }
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    // MARK: - Schedule

    /// Schedules the recurring weekly reminder, picking copy that's lightly
    /// informed by the user's most recent check-in (if SwiftData context is
    /// available).
    func scheduleWeeklyReminder(
        dayOfWeek: Int,
        hour: Int,
        modelContext: ModelContext? = nil
    ) async {
        cancelReminder()

        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Life Zones"
        content.body = pickMessage(modelContext: modelContext)
        content.sound = .default
        content.threadIdentifier = "weekly-checkin"

        var components = DateComponents()
        components.weekday = dayOfWeek + 1   // UNCalendar uses 1=Sun..7=Sat
        components.hour = hour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelIfCheckedIn() {
        cancelReminder()
    }

    // MARK: - Adaptive copy

    /// Generic, never-guilt-trip messages used when there's no recent data.
    private static let baseMessages = [
        "Time to check in with yourself.",
        "Your map is waiting.",
        "A quiet 2 minutes — just for you.",
        "How's your week been, really?",
        "Seven zones. How are they doing?",
        "Your life, mapped. Ready to update it?",
        "No judgment. Just curiosity.",
        "A moment of honest reflection.",
        "Check in. It only takes a minute.",
        "How are all your zones holding up?",
        "Your weekly pulse — whenever you're ready.",
        "Pause. Reflect. Map."
    ]

    /// Messages used when the user has been steady — celebrate gently.
    private static let steadyMessages = [
        "A good rhythm. Want to mark the week?",
        "Six minutes of you. That's all.",
        "Another week, another map.",
        "How does this week want to be remembered?"
    ]

    /// Messages used when the user had a rough week last time.
    private static let recoveryMessages = [
        "No streak to keep. Just check in if you want to.",
        "How are you, this week?",
        "Quiet weeks deserve attention too.",
        "Even a one-zone update counts."
    ]

    /// Messages that reference a specific zone that's been trending.
    /// Filled in with the zone name at schedule time.
    private static let zoneCallbacks = [
        "%@ has been quiet lately — how is it?",
        "%@ took a step up last week. Still climbing?",
        "Last week %@ caught your attention. Still relevant?",
        "How is your %@ this week?"
    ]

    private func pickMessage(modelContext: ModelContext?) -> String {
        guard let ctx = modelContext else {
            return Self.baseMessages.randomElement() ?? Self.baseMessages[0]
        }

        let service = CheckInService(modelContext: ctx)
        let recent = (try? service.fetchAll(limit: 2)) ?? []

        guard let last = recent.first else {
            return Self.baseMessages.randomElement() ?? Self.baseMessages[0]
        }

        let avg = last.overallAverage

        // Occasionally — 30% — reference a specific zone that moved a lot
        // between the most recent two check-ins.
        if recent.count >= 2, Double.random(in: 0...1) < 0.3 {
            let prev = recent[1]
            let mover = ZoneID.allCases
                .map { ($0, abs(last.score(for: $0) - prev.score(for: $0))) }
                .max(by: { $0.1 < $1.1 })
            if let (zone, delta) = mover, delta >= 2 {
                let name = ZoneRegistry.definition(for: zone).name
                let pool = Self.zoneCallbacks
                let template = pool.randomElement() ?? pool[0]
                return String(format: template, name)
            }
        }

        // Tone — average drives which bucket
        let pool: [String]
        switch avg {
        case ..<5:   pool = Self.recoveryMessages
        case 7...:   pool = Self.steadyMessages
        default:     pool = Self.baseMessages
        }
        return pool.randomElement() ?? Self.baseMessages[0]
    }
}
