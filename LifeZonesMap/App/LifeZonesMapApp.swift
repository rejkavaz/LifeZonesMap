import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.rejkavaz.LifeZonesMap", category: "Startup")

@main
struct LifeZonesMapApp: App {
    let container: ModelContainer
    @State private var router = DeepLinkRouter()

    init() {
        logger.notice("Launching Life Zones Map")
        // SwiftData store schema can drift between sideloads as we add new
        // @Model classes. Try once with the new schema — and if that fails
        // (typically because the on-disk store predates a newer model),
        // wipe the store at the deterministic URL we control and retry.
        do {
            container = try Self.makeContainer()
            logger.notice("ModelContainer opened successfully")
        } catch {
            logger.error("ModelContainer init failed: \(error.localizedDescription, privacy: .public). Wiping store and retrying.")
            Self.wipeStoreFiles()
            do {
                container = try Self.makeContainer()
                logger.notice("ModelContainer opened on second attempt after wipe")
            } catch {
                logger.fault("ModelContainer init failed after wipe: \(error.localizedDescription, privacy: .public). Falling back to in-memory store.")
                // Last resort: in-memory store so the app can at least render.
                // The user will lose any future writes when they close the app
                // but at least won't see an instant crash.
                do {
                    let inMemoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                    container = try ModelContainer(
                        for: WeeklyCheckIn.self, ZoneInsight.self, UserPreferences.self,
                        WeeklyReflection.self, PromptResponse.self, MoodDrop.self,
                        ZoneGoal.self, GoodThing.self,
                        configurations: inMemoryConfig
                    )
                } catch {
                    fatalError("Couldn't even create in-memory ModelContainer: \(error)")
                }
            }
        }

        // Register TipKit hints (each shows once per install)
        if #available(iOS 17.0, *) {
            AppTips.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            AppLockGate {
                ContentView()
                    .environment(router)
                    .onAppear { seedIfNeeded() }
            }
        }
        .modelContainer(container)
    }

    // MARK: - Helpers

    /// Explicit URL so we know exactly where SwiftData wrote the store and can wipe it.
    private static let storeURL: URL = {
        let supportURL: URL
        if #available(iOS 16, *) {
            supportURL = URL.applicationSupportDirectory
        } else {
            supportURL = (try? FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )) ?? URL(filePath: NSTemporaryDirectory())
        }
        return supportURL.appending(path: "LifeZones.store")
    }()

    private static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(url: storeURL)
        return try ModelContainer(
            for: WeeklyCheckIn.self,
            ZoneInsight.self,
            UserPreferences.self,
            WeeklyReflection.self,
            PromptResponse.self,
            MoodDrop.self,
            ZoneGoal.self,
            GoodThing.self,
            CustomPrompt.self,
            configurations: config
        )
    }

    /// Wipe the SwiftData store + journal files at our known URL.
    /// SQLite WAL mode writes three files: .store, .store-shm, .store-wal.
    private static func wipeStoreFiles() {
        let fm = FileManager.default
        let basePath = storeURL.path()
        for suffix in ["", "-shm", "-wal", "-journal"] {
            try? fm.removeItem(atPath: basePath + suffix)
        }
        // Belt and suspenders: also remove any *.store files in App Support
        // in case an older SwiftData version wrote them to the default path.
        let supportDir = storeURL.deletingLastPathComponent()
        if let contents = try? fm.contentsOfDirectory(at: supportDir, includingPropertiesForKeys: nil) {
            for u in contents where u.lastPathComponent.contains(".store") {
                try? fm.removeItem(at: u)
            }
        }
    }

    /// Run preview seed safely from onAppear — the App protocol's init
    /// timing has changed across iOS versions and called the seeder from
    /// init has surfaced subtle crashes. Doing it after the scene is
    /// attached is unambiguous.
    private func seedIfNeeded() {
        guard PreviewSeeder.isActive else { return }
        PreviewSeeder.seed(in: container.mainContext)
    }
}
