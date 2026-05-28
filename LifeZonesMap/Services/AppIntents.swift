import AppIntents
import SwiftData
import Foundation

// MARK: - The zone entity (Siri needs an enum it can parse from speech)

enum ZoneEntity: String, AppEnum, CaseIterable {
    case vitality, deepWork, connection, innerWorld, creation, foundation, growth

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Zone"

    static let caseDisplayRepresentations: [ZoneEntity: DisplayRepresentation] = [
        .vitality:   "Vitality",
        .deepWork:   "Deep Work",
        .connection: "Connection",
        .innerWorld: "Inner World",
        .creation:   "Creation",
        .foundation: "Foundation",
        .growth:     "Growth"
    ]

    var zoneID: ZoneID {
        switch self {
        case .vitality:   return .vitality
        case .deepWork:   return .deepWork
        case .connection: return .connection
        case .innerWorld: return .innerWorld
        case .creation:   return .creation
        case .foundation: return .foundation
        case .growth:     return .growth
        }
    }
}

// MARK: - The intent

@available(iOS 17, *)
struct LogZoneScoreIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Zone Score"

    static let description: IntentDescription = IntentDescription(
        "Update this week's score for a single Life Zone.",
        categoryName: "Wellness"
    )

    @Parameter(title: "Zone")
    var zone: ZoneEntity

    @Parameter(
        title: "Score",
        description: "From 1 (rough) to 10 (excellent)",
        inclusiveRange: (1, 10)
    )
    var score: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$zone) at \(\.$score)")
    }

    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(
            for: WeeklyCheckIn.self, ZoneInsight.self, UserPreferences.self, WeeklyReflection.self
        )
        let context = container.mainContext
        let service = CheckInService(modelContext: context)

        let weekStart = Date().isoWeekMonday
        let existing = try? service.fetchCheckIn(for: weekStart)
        let zoneKey = zone.zoneID.rawValue

        let definition = ZoneRegistry.definition(for: zone.zoneID)
        let previous = existing?.score(for: zone.zoneID)
        let clamped = max(1, min(10, score))

        if let checkIn = existing {
            checkIn.scores[zoneKey] = clamped
            try? context.save()
            WidgetDataProvider.update(from: checkIn)
        } else {
            // Start a sparse check-in with just this one zone + defaults for the rest.
            var seed: [ZoneID: Int] = Dictionary(uniqueKeysWithValues: ZoneID.allCases.map { ($0, 5) })
            seed[zone.zoneID] = clamped
            _ = try service.save(scores: seed, tags: [:], notes: [:])
        }

        let dialog: String
        if let prev = previous, prev != clamped {
            dialog = "Updated \(definition.name) from \(prev) to \(clamped)."
        } else {
            dialog = "Logged \(definition.name) at \(clamped)."
        }
        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }
}

// MARK: - Shortcut suggestions on first launch

@available(iOS 17, *)
struct LifeZonesShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogZoneScoreIntent(),
            phrases: [
                "Log \(.applicationName)",
                "Update \(.applicationName)",
                "Check in with \(.applicationName)"
            ],
            shortTitle: "Log Zone",
            systemImageName: "circle.hexagongrid"
        )
    }
}
