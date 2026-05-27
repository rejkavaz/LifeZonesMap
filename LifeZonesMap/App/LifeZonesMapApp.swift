import SwiftUI
import SwiftData

@main
struct LifeZonesMapApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: WeeklyCheckIn.self, ZoneInsight.self, UserPreferences.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
