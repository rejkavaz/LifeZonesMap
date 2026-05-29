import Foundation

// Writes the latest check-in to the shared App Group so the widget can read it.
enum WidgetDataProvider {
    static let suiteName = "group.com.yourteam.lifezonesmap"

    struct Snapshot: Codable {
        let weekStart: Date
        let scores: [String: Int]
        let overallAverage: Double
        /// Weekday (1=Sunday … 7=Saturday) the user wants check-ins. Lets
        /// the lock-screen widget flip into "Tap to check in" mode on the
        /// right day.
        var checkInWeekday: Int = 1
    }

    static func update(from checkIn: WeeklyCheckIn, checkInWeekday: Int = 1) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        let snapshot = Snapshot(
            weekStart: checkIn.weekStartDate,
            scores: checkIn.scores,
            overallAverage: checkIn.overallAverage,
            checkInWeekday: checkInWeekday
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: "latestSnapshot")
        }
    }

    static func updateCheckInWeekday(_ weekday: Int) {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: "latestSnapshot"),
              var snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        snapshot.checkInWeekday = weekday
        if let updated = try? JSONEncoder().encode(snapshot) {
            defaults.set(updated, forKey: "latestSnapshot")
        }
    }

    static func latestSnapshot() -> Snapshot? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: "latestSnapshot") else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }
}
