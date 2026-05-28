import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.rejkavaz.LifeZonesMap", category: "Startup")

@main
struct LifeZonesMapApp: App {
    let container: ModelContainer

    init() {
        // SwiftData store schema can drift between sideloads as we add new
        // @Model classes. Rather than crash, try once with the new schema —
        // and if that fails (typically because the on-disk store predates a
        // newer model), wipe the local store and retry. This costs the user
        // their data on schema-breaking updates, which is acceptable while
        // the app is in early personal-use territory but should be replaced
        // with a real SchemaMigrationPlan before any real launch.
        do {
            container = try Self.makeContainer()
        } catch {
            logger.error("ModelContainer init failed: \(error.localizedDescription, privacy: .public). Wiping store and retrying.")
            Self.wipeStoreFiles()
            do {
                container = try Self.makeContainer()
            } catch {
                fatalError("ModelContainer init failed even after wiping store: \(error)")
            }
        }

        // CI-only seed mode — see PreviewSeeder
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

    // MARK: - Helpers

    private static func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: WeeklyCheckIn.self,
            ZoneInsight.self,
            UserPreferences.self,
            WeeklyReflection.self,
            PromptResponse.self,
            MoodDrop.self,
            ZoneGoal.self,
            GoodThing.self
        )
    }

    /// Best-effort wipe of the SwiftData store. We can't always know the
    /// exact path SwiftData picked, so try the well-known defaults.
    private static func wipeStoreFiles() {
        let fm = FileManager.default
        let appSupport = try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )

        let names = ["default.store", "default.store-shm", "default.store-wal"]
        for name in names {
            if let url = appSupport?.appendingPathComponent(name) {
                try? fm.removeItem(at: url)
            }
        }

        // Some SwiftData versions nest under a bundle-id folder; nuke any
        // *.store left over in App Support.
        if let appSupport,
           let contents = try? fm.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil) {
            for url in contents where url.lastPathComponent.contains(".store") {
                try? fm.removeItem(at: url)
            }
        }
    }
}
