import Foundation

// Writes the latest check-in to the shared App Group so the widget can read it.
enum WidgetDataProvider {
    static let suiteName = "group.com.yourteam.lifezonesmap"

    struct Snapshot: Codable {
        let weekStart: Date
        let scores: [String: Int]
        let overallAverage: Double
    }

    static func update(from checkIn: WeeklyCheckIn) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        let snapshot = Snapshot(
            weekStart: checkIn.weekStartDate,
            scores: checkIn.scores,
            overallAverage: checkIn.overallAverage
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: "latestSnapshot")
        }
    }

    static func latestSnapshot() -> Snapshot? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: "latestSnapshot") else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }
}
