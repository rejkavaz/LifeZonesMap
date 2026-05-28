import SwiftUI
import SwiftData

@main
struct LifeZonesMapApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: WeeklyCheckIn.self,
                ZoneInsight.self,
                UserPreferences.self,
                WeeklyReflection.self,
                PromptResponse.self,
                MoodDrop.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // When CI launches the app with `--ui-preview`, replace the store
        // with deterministic demo data so screenshots are reproducible.
        if PreviewSeeder.isActive {
            MainActor.assumeIsolated {
                PreviewSeeder.seed(in: container.mainContext)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
