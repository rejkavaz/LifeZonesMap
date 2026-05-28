import SwiftUI
import SwiftData

/// Picks one library prompt to surface at the top of the Journal tab,
/// based on what the user's data has been doing lately. Logic:
///   1. Find the zone with the lowest 3-week average (the one most wanting
///      attention). If none qualifies (no data, or all balanced), fall back to:
///   2. The zone with the biggest week-over-week drop, if any.
///   3. Otherwise, a random Open-category prompt.
///
/// Selection is stable within a calendar week (same prompt all week).
struct PromptOfTheWeekCard: View {
    @Query(sort: \WeeklyCheckIn.weekStartDate, order: .reverse) private var history: [WeeklyCheckIn]
    @Query(sort: \PromptResponse.createdAt, order: .reverse) private var responses: [PromptResponse]

    private var prompt: Prompt {
        Self.pickPrompt(history: history)
    }

    private var alreadyAnswered: Bool {
        responses.contains { $0.promptID == prompt.id }
    }

    var body: some View {
        NavigationLink {
            PromptDetailView(prompt: prompt)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("PROMPT OF THE WEEK")
                        .uppercaseCaption(color: accent, size: 9.5, tracking: 1.8)
                    Spacer()
                    if alreadyAnswered {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(accent.opacity(0.7))
                    }
                }
                Text(prompt.text)
                    .font(.system(size: 17, weight: .medium))
                    .tracking(-0.15)
                    .lineSpacing(2.5)
                    .foregroundStyle(LZ.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Text(prompt.category.uppercased())
                        .uppercaseCaption(color: LZ.inkMute, size: 9.5, tracking: 1.6)
                    Rectangle().fill(LZ.ruleSoft).frame(height: 0.5)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LZ.inkMute)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LZ.cream)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(accent.opacity(0.3), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var accent: Color {
        prompt.zone.map { ZoneRegistry.definition(for: $0).color } ?? LZ.tealDeep
    }

    // MARK: - Selection logic

    /// Stable for a given (history, ISO week).
    static func pickPrompt(history: [WeeklyCheckIn]) -> Prompt {
        let weekSeed = Date().isoWeekMonday.hashValue
        let recent = history.prefix(3)
        let allPrompts = PromptLibrary.all

        // 1. Lowest 3-week average → surface a prompt from that zone
        if recent.count >= 2 {
            let zoneAvgs = ZoneID.allCases.map { zone -> (ZoneID, Double) in
                let scores = recent.map { Double($0.score(for: zone)) }
                let avg = scores.reduce(0, +) / Double(scores.count)
                return (zone, avg)
            }
            if let lowest = zoneAvgs.min(by: { $0.1 < $1.1 }), lowest.1 < 6.5 {
                let pool = allPrompts.filter { $0.zone == lowest.0 }
                if let pick = stablePick(pool, seed: weekSeed) { return pick }
            }
        }

        // 2. Biggest drop week-over-week
        if recent.count >= 2 {
            let latest = recent[0]
            let prior = recent[1]
            let deltas = ZoneID.allCases.map { ($0, latest.score(for: $0) - prior.score(for: $0)) }
            if let drop = deltas.min(by: { $0.1 < $1.1 }), drop.1 <= -2 {
                let pool = allPrompts.filter { $0.zone == drop.0 }
                if let pick = stablePick(pool, seed: weekSeed) { return pick }
            }
        }

        // 3. Fallback: random open or zone prompt
        let openOrAll = allPrompts.filter { $0.zone == nil }
        let pool = openOrAll.isEmpty ? allPrompts : openOrAll
        return stablePick(pool, seed: weekSeed) ?? allPrompts.first!
    }

    private static func stablePick(_ list: [Prompt], seed: Int) -> Prompt? {
        guard !list.isEmpty else { return nil }
        let idx = abs(seed) % list.count
        return list[idx]
    }
}
