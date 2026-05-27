import UserNotifications
import Foundation

@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private let identifier = "weekly-checkin"

    private let messagePools: [String] = [
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

    private init() {}

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            return settings.authorizationStatus == .authorized
        }
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func scheduleWeeklyReminder(dayOfWeek: Int, hour: Int) async {
        cancelReminder()

        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Life Zones"
        content.body = messagePools.randomElement() ?? messagePools[0]
        content.sound = .default

        var components = DateComponents()
        // UNCalendarNotificationTrigger uses 1=Sun…7=Sat, but our model uses 0=Sun…6=Sat
        components.weekday = dayOfWeek + 1
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
}
