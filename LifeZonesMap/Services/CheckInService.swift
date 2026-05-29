import Foundation
import SwiftData

@MainActor
final class CheckInService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Save

    func save(
        scores: [ZoneID: Int],
        tags: [ZoneID: String],
        notes: [ZoneID: String],
        photoData: Data? = nil,
        audioData: Data? = nil,
        audioDuration: Double = 0
    ) throws -> WeeklyCheckIn {
        let weekStart = Date().isoWeekMonday

        // Enforce one check-in per ISO week
        if let existing = try fetchCheckIn(for: weekStart) {
            existing.scores = Dictionary(uniqueKeysWithValues: scores.map { ($0.key.rawValue, $0.value) })
            existing.tags   = Dictionary(uniqueKeysWithValues: tags.compactMap { $0.value.isEmpty ? nil : ($0.key.rawValue, $0.value) })
            existing.notes  = Dictionary(uniqueKeysWithValues: notes.compactMap { $0.value.isEmpty ? nil : ($0.key.rawValue, $0.value) })
            // Only overwrite media if the caller is providing something —
            // a re-submit without media shouldn't blow away your photo.
            if let photoData { existing.photoData = photoData }
            if let audioData {
                existing.audioData = audioData
                existing.audioDuration = audioDuration
            }
            try modelContext.save()
            return existing
        }

        let checkIn = WeeklyCheckIn(
            weekStartDate: weekStart,
            scores: Dictionary(uniqueKeysWithValues: scores.map { ($0.key.rawValue, $0.value) }),
            tags:   Dictionary(uniqueKeysWithValues: tags.compactMap { $0.value.isEmpty ? nil : ($0.key.rawValue, $0.value) }),
            notes:  Dictionary(uniqueKeysWithValues: notes.compactMap { $0.value.isEmpty ? nil : ($0.key.rawValue, $0.value) }),
            photoData: photoData,
            audioData: audioData,
            audioDuration: audioDuration
        )
        modelContext.insert(checkIn)
        try modelContext.save()

        WidgetDataProvider.update(from: checkIn)
        return checkIn
    }

    // MARK: - Query

    func fetchCheckIn(for weekStart: Date) throws -> WeeklyCheckIn? {
        let descriptor = FetchDescriptor<WeeklyCheckIn>(
            predicate: #Predicate { $0.weekStartDate == weekStart }
        )
        return try modelContext.fetch(descriptor).first
    }

    func currentWeekCheckIn() throws -> WeeklyCheckIn? {
        try fetchCheckIn(for: Date().isoWeekMonday)
    }

    /// Returns the most recent check-in BEFORE the current ISO week, mapped
    /// to a [ZoneID: Int] dictionary. Used for the "vs last week" overlay
    /// on the Map. nil if there is no prior data.
    func previousWeekScores() throws -> [ZoneID: Int]? {
        let currentWeekStart = Date().isoWeekMonday
        let descriptor = FetchDescriptor<WeeklyCheckIn>(
            predicate: #Predicate { $0.weekStartDate < currentWeekStart },
            sortBy: [SortDescriptor(\.weekStartDate, order: .reverse)]
        )
        guard let prior = try modelContext.fetch(descriptor).first else { return nil }
        return Dictionary(uniqueKeysWithValues: ZoneID.allCases.map { ($0, prior.score(for: $0)) })
    }

    func fetchAll(limit: Int? = nil) throws -> [WeeklyCheckIn] {
        var descriptor = FetchDescriptor<WeeklyCheckIn>(
            sortBy: [SortDescriptor(\.weekStartDate, order: .reverse)]
        )
        if let limit { descriptor.fetchLimit = limit }
        return try modelContext.fetch(descriptor)
    }

    func fetchLast28Days() throws -> [WeeklyCheckIn] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -28, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<WeeklyCheckIn>(
            predicate: #Predicate { $0.weekStartDate >= cutoff },
            sortBy: [SortDescriptor(\.weekStartDate)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// The 28-day window immediately before the current one. Used for
    /// month-over-month comparison overlays.
    func fetchPrior28Days() throws -> [WeeklyCheckIn] {
        let now = Date()
        let cal = Calendar.current
        let currentStart = cal.date(byAdding: .day, value: -28, to: now) ?? now
        let priorStart   = cal.date(byAdding: .day, value: -56, to: now) ?? now
        let descriptor = FetchDescriptor<WeeklyCheckIn>(
            predicate: #Predicate {
                $0.weekStartDate >= priorStart && $0.weekStartDate < currentStart
            },
            sortBy: [SortDescriptor(\.weekStartDate)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Stats

    func deltaFromLastWeek(for zone: ZoneID, current: WeeklyCheckIn) throws -> Int? {
        let all = try fetchAll(limit: 10)
        guard let idx = all.firstIndex(where: { $0.id == current.id }),
              idx + 1 < all.count else { return nil }
        let prev = all[idx + 1]
        return current.score(for: zone) - prev.score(for: zone)
    }

    // MARK: - Delete

    func deleteAll() throws {
        let all = try fetchAll()
        all.forEach { modelContext.delete($0) }
        try modelContext.save()
    }
}
