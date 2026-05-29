import Foundation
import SwiftData
import OSLog

private let backupLog = Logger(subsystem: "com.rejkavaz.LifeZonesMap", category: "Backup")

// MARK: - Archive format
//
// JSON, versioned. Every entity gets a stable UUID so re-import dedupes
// naturally. Media (photos, voice notes) is embedded as base64 inside the
// same file — single-file backup is the only sane experience for users
// moving phones.

struct LifeZonesBackup: Codable {
    let version: Int                 // bump when schema changes
    let exportedAt: Date
    let appVersion: String

    let checkIns:        [CheckInDTO]
    let reflections:     [ReflectionDTO]
    let promptResponses: [PromptResponseDTO]
    let moodDrops:       [MoodDropDTO]
    let goals:           [GoalDTO]
    let goodThings:      [GoodThingDTO]
    let customPrompts:   [CustomPromptDTO]
    let preferences:     PreferencesDTO?
}

// MARK: - DTOs (mirror @Model classes, no SwiftData coupling)

struct CheckInDTO: Codable {
    let id: UUID
    let weekStartDate: Date
    let createdAt: Date
    let scores: [String: Int]
    let tags: [String: String]
    let notes: [String: String]
    let photoData: Data?
    let audioData: Data?
    let audioDuration: Double
}

struct ReflectionDTO: Codable {
    let id: UUID
    let weekStartDate: Date
    let createdAt: Date
    let prompt: String
    let response: String
}

struct PromptResponseDTO: Codable {
    let id: UUID
    let promptID: String
    let response: String
    let createdAt: Date
}

struct MoodDropDTO: Codable {
    let id: UUID
    let date: Date
    let mood: String
    let detail: String
}

struct GoalDTO: Codable {
    let id: UUID
    let zoneIDRaw: String
    let lowerBound: Int
    let upperBound: Int
    let note: String
    let createdAt: Date
}

struct GoodThingDTO: Codable {
    let id: UUID
    let weekStartDate: Date
    let text: String
    let why: String
    let createdAt: Date
}

struct CustomPromptDTO: Codable {
    let id: UUID
    let text: String
    let zoneIDRaw: String?
    let createdAt: Date
}

struct PreferencesDTO: Codable {
    let id: UUID
    let checkInDayOfWeek: Int
    let checkInHour: Int
    let enableHaptics: Bool
    let enableInsights: Bool
    let insightAPIEnabled: Bool
    let anthropicAPIKey: String
    let customZoneNames: [String: String]
    let onboardingComplete: Bool
    let notificationsEnabled: Bool
    let hasSeenMapTip: Bool
    let appLockEnabled: Bool
    let healthKitVitalityEnabled: Bool
}

// MARK: - Service

@MainActor
final class BackupService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    static let currentVersion = 1

    enum ImportMode {
        /// Wipe everything currently in the store, then load from the file.
        case replace
        /// Insert everything from the file unless an entity with the same id
        /// already exists. Preserves user's most recent additions.
        case merge
    }

    enum BackupError: LocalizedError {
        case invalidJSON
        case unsupportedVersion(Int)

        var errorDescription: String? {
            switch self {
            case .invalidJSON: return "Couldn't read that file as a Life Zones backup."
            case .unsupportedVersion(let v): return "Backup version \(v) isn't supported by this build."
            }
        }
    }

    // MARK: - Export

    func exportArchive() throws -> Data {
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

        let checkIns        = (try? modelContext.fetch(FetchDescriptor<WeeklyCheckIn>())) ?? []
        let reflections     = (try? modelContext.fetch(FetchDescriptor<WeeklyReflection>())) ?? []
        let promptResponses = (try? modelContext.fetch(FetchDescriptor<PromptResponse>())) ?? []
        let moodDrops       = (try? modelContext.fetch(FetchDescriptor<MoodDrop>())) ?? []
        let goals           = (try? modelContext.fetch(FetchDescriptor<ZoneGoal>())) ?? []
        let goodThings      = (try? modelContext.fetch(FetchDescriptor<GoodThing>())) ?? []
        let customPrompts   = (try? modelContext.fetch(FetchDescriptor<CustomPrompt>())) ?? []
        let preferences     = try? modelContext.fetch(FetchDescriptor<UserPreferences>()).first

        let archive = LifeZonesBackup(
            version: Self.currentVersion,
            exportedAt: Date(),
            appVersion: bundleVersion,
            checkIns:        checkIns.map(toDTO),
            reflections:     reflections.map(toDTO),
            promptResponses: promptResponses.map(toDTO),
            moodDrops:       moodDrops.map(toDTO),
            goals:           goals.map(toDTO),
            goodThings:      goodThings.map(toDTO),
            customPrompts:   customPrompts.map(toDTO),
            preferences:     preferences.map(toDTO)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.dataEncodingStrategy = .base64
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(archive)
    }

    // MARK: - Import

    @discardableResult
    func importArchive(_ data: Data, mode: ImportMode) throws -> ImportSummary {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.dataDecodingStrategy = .base64

        let archive: LifeZonesBackup
        do {
            archive = try decoder.decode(LifeZonesBackup.self, from: data)
        } catch {
            backupLog.error("Decode failed: \(error.localizedDescription, privacy: .public)")
            throw BackupError.invalidJSON
        }

        if archive.version > Self.currentVersion {
            throw BackupError.unsupportedVersion(archive.version)
        }

        if mode == .replace {
            wipeAll()
        }

        // Build sets of existing IDs once so merge mode can skip duplicates
        // without N queries.
        let existing = existingIDs()

        var summary = ImportSummary()

        for dto in archive.checkIns where shouldInsert(dto.id, in: existing.checkIns, mode: mode) {
            modelContext.insert(WeeklyCheckIn(from: dto))
            summary.checkIns += 1
        }
        for dto in archive.reflections where shouldInsert(dto.id, in: existing.reflections, mode: mode) {
            modelContext.insert(WeeklyReflection(from: dto))
            summary.reflections += 1
        }
        for dto in archive.promptResponses where shouldInsert(dto.id, in: existing.promptResponses, mode: mode) {
            modelContext.insert(PromptResponse(from: dto))
            summary.promptResponses += 1
        }
        for dto in archive.moodDrops where shouldInsert(dto.id, in: existing.moodDrops, mode: mode) {
            modelContext.insert(MoodDrop(from: dto))
            summary.moodDrops += 1
        }
        for dto in archive.goals where shouldInsert(dto.id, in: existing.goals, mode: mode) {
            modelContext.insert(ZoneGoal(from: dto))
            summary.goals += 1
        }
        for dto in archive.goodThings where shouldInsert(dto.id, in: existing.goodThings, mode: mode) {
            modelContext.insert(GoodThing(from: dto))
            summary.goodThings += 1
        }
        for dto in archive.customPrompts where shouldInsert(dto.id, in: existing.customPrompts, mode: mode) {
            modelContext.insert(CustomPrompt(from: dto))
            summary.customPrompts += 1
        }

        // Preferences: replace mode overwrites the existing row; merge mode
        // leaves user's current settings alone unless there isn't one.
        if let prefsDTO = archive.preferences {
            let currentPrefs = try? modelContext.fetch(FetchDescriptor<UserPreferences>()).first
            if mode == .replace || currentPrefs == nil {
                currentPrefs.map(modelContext.delete)
                modelContext.insert(UserPreferences(from: prefsDTO))
                summary.preferencesImported = true
            }
        }

        try modelContext.save()
        backupLog.notice("Import complete: \(String(describing: summary), privacy: .public)")
        return summary
    }

    struct ImportSummary: CustomStringConvertible {
        var checkIns: Int = 0
        var reflections: Int = 0
        var promptResponses: Int = 0
        var moodDrops: Int = 0
        var goals: Int = 0
        var goodThings: Int = 0
        var customPrompts: Int = 0
        var preferencesImported: Bool = false

        var total: Int {
            checkIns + reflections + promptResponses + moodDrops
                + goals + goodThings + customPrompts
        }

        var description: String {
            "\(checkIns) check-ins, \(reflections) reflections, "
            + "\(promptResponses) prompt answers, \(moodDrops) mood drops, "
            + "\(goals) goals, \(goodThings) good things, "
            + "\(customPrompts) custom prompts"
            + (preferencesImported ? " + preferences" : "")
        }
    }

    // MARK: - Helpers

    private struct ExistingIDs {
        var checkIns: Set<UUID> = []
        var reflections: Set<UUID> = []
        var promptResponses: Set<UUID> = []
        var moodDrops: Set<UUID> = []
        var goals: Set<UUID> = []
        var goodThings: Set<UUID> = []
        var customPrompts: Set<UUID> = []
    }

    private func existingIDs() -> ExistingIDs {
        var e = ExistingIDs()
        e.checkIns        = Set(((try? modelContext.fetch(FetchDescriptor<WeeklyCheckIn>())) ?? []).map(\.id))
        e.reflections     = Set(((try? modelContext.fetch(FetchDescriptor<WeeklyReflection>())) ?? []).map(\.id))
        e.promptResponses = Set(((try? modelContext.fetch(FetchDescriptor<PromptResponse>())) ?? []).map(\.id))
        e.moodDrops       = Set(((try? modelContext.fetch(FetchDescriptor<MoodDrop>())) ?? []).map(\.id))
        e.goals           = Set(((try? modelContext.fetch(FetchDescriptor<ZoneGoal>())) ?? []).map(\.id))
        e.goodThings      = Set(((try? modelContext.fetch(FetchDescriptor<GoodThing>())) ?? []).map(\.id))
        e.customPrompts   = Set(((try? modelContext.fetch(FetchDescriptor<CustomPrompt>())) ?? []).map(\.id))
        return e
    }

    private func shouldInsert(_ id: UUID, in existing: Set<UUID>, mode: ImportMode) -> Bool {
        mode == .replace || !existing.contains(id)
    }

    private func wipeAll() {
        // Concrete calls rather than iterating over `[any PersistentModel.Type]`
        // because Swift's generic dispatch can't go through an existential type.
        wipe(WeeklyCheckIn.self)
        wipe(WeeklyReflection.self)
        wipe(PromptResponse.self)
        wipe(MoodDrop.self)
        wipe(ZoneGoal.self)
        wipe(GoodThing.self)
        wipe(CustomPrompt.self)
        wipe(UserPreferences.self)
    }

    private func wipe<T: PersistentModel>(_ type: T.Type) {
        if let items = try? modelContext.fetch(FetchDescriptor<T>()) {
            for item in items { modelContext.delete(item) }
        }
    }

    // MARK: - Entity → DTO

    private func toDTO(_ c: WeeklyCheckIn) -> CheckInDTO {
        CheckInDTO(
            id: c.id, weekStartDate: c.weekStartDate, createdAt: c.createdAt,
            scores: c.scores, tags: c.tags, notes: c.notes,
            photoData: c.photoData, audioData: c.audioData,
            audioDuration: c.audioDuration
        )
    }
    private func toDTO(_ r: WeeklyReflection) -> ReflectionDTO {
        ReflectionDTO(
            id: r.id, weekStartDate: r.weekStartDate,
            createdAt: r.createdAt, prompt: r.prompt, response: r.response
        )
    }
    private func toDTO(_ p: PromptResponse) -> PromptResponseDTO {
        PromptResponseDTO(id: p.id, promptID: p.promptID, response: p.response, createdAt: p.createdAt)
    }
    private func toDTO(_ m: MoodDrop) -> MoodDropDTO {
        MoodDropDTO(id: m.id, date: m.date, mood: m.mood, detail: m.detail)
    }
    private func toDTO(_ g: ZoneGoal) -> GoalDTO {
        GoalDTO(
            id: g.id, zoneIDRaw: g.zoneIDRaw,
            lowerBound: g.lowerBound, upperBound: g.upperBound,
            note: g.note, createdAt: g.createdAt
        )
    }
    private func toDTO(_ g: GoodThing) -> GoodThingDTO {
        GoodThingDTO(
            id: g.id, weekStartDate: g.weekStartDate,
            text: g.text, why: g.why, createdAt: g.createdAt
        )
    }
    private func toDTO(_ c: CustomPrompt) -> CustomPromptDTO {
        CustomPromptDTO(id: c.id, text: c.text, zoneIDRaw: c.zoneIDRaw, createdAt: c.createdAt)
    }
    private func toDTO(_ p: UserPreferences) -> PreferencesDTO {
        PreferencesDTO(
            id: p.id, checkInDayOfWeek: p.checkInDayOfWeek, checkInHour: p.checkInHour,
            enableHaptics: p.enableHaptics, enableInsights: p.enableInsights,
            insightAPIEnabled: p.insightAPIEnabled, anthropicAPIKey: p.anthropicAPIKey,
            customZoneNames: p.customZoneNames, onboardingComplete: p.onboardingComplete,
            notificationsEnabled: p.notificationsEnabled, hasSeenMapTip: p.hasSeenMapTip,
            appLockEnabled: p.appLockEnabled, healthKitVitalityEnabled: p.healthKitVitalityEnabled
        )
    }
}

// MARK: - DTO → Entity rehydration

private extension WeeklyCheckIn {
    convenience init(from dto: CheckInDTO) {
        self.init(
            weekStartDate: dto.weekStartDate,
            scores: dto.scores, tags: dto.tags, notes: dto.notes,
            photoData: dto.photoData, audioData: dto.audioData,
            audioDuration: dto.audioDuration
        )
        self.id = dto.id
        self.createdAt = dto.createdAt
    }
}

private extension WeeklyReflection {
    convenience init(from dto: ReflectionDTO) {
        self.init(weekStartDate: dto.weekStartDate, prompt: dto.prompt, response: dto.response)
        self.id = dto.id
        self.createdAt = dto.createdAt
    }
}

private extension PromptResponse {
    convenience init(from dto: PromptResponseDTO) {
        self.init(promptID: dto.promptID, response: dto.response)
        self.id = dto.id
        self.createdAt = dto.createdAt
    }
}

private extension MoodDrop {
    convenience init(from dto: MoodDropDTO) {
        self.init(mood: dto.mood, detail: dto.detail)
        self.id = dto.id
        self.date = dto.date
    }
}

private extension ZoneGoal {
    convenience init(from dto: GoalDTO) {
        let zone = ZoneID(rawValue: dto.zoneIDRaw) ?? .vitality
        self.init(zone: zone, lower: dto.lowerBound, upper: dto.upperBound, note: dto.note)
        self.id = dto.id
        self.createdAt = dto.createdAt
    }
}

private extension GoodThing {
    convenience init(from dto: GoodThingDTO) {
        self.init(weekStartDate: dto.weekStartDate, text: dto.text, why: dto.why)
        self.id = dto.id
        self.createdAt = dto.createdAt
    }
}

private extension CustomPrompt {
    convenience init(from dto: CustomPromptDTO) {
        let zone = dto.zoneIDRaw.flatMap { ZoneID(rawValue: $0) }
        self.init(text: dto.text, zone: zone)
        self.id = dto.id
        self.createdAt = dto.createdAt
    }
}

private extension UserPreferences {
    convenience init(from dto: PreferencesDTO) {
        self.init()
        self.id = dto.id
        self.checkInDayOfWeek = dto.checkInDayOfWeek
        self.checkInHour = dto.checkInHour
        self.enableHaptics = dto.enableHaptics
        self.enableInsights = dto.enableInsights
        self.insightAPIEnabled = dto.insightAPIEnabled
        self.anthropicAPIKey = dto.anthropicAPIKey
        self.customZoneNames = dto.customZoneNames
        self.onboardingComplete = dto.onboardingComplete
        self.notificationsEnabled = dto.notificationsEnabled
        self.hasSeenMapTip = dto.hasSeenMapTip
        self.appLockEnabled = dto.appLockEnabled
        self.healthKitVitalityEnabled = dto.healthKitVitalityEnabled
    }
}
