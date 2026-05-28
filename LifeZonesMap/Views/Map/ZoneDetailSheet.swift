import SwiftUI
import SwiftData

struct ZoneDetailSheet: View {
    let zone: ZoneID
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WeeklyCheckIn.weekStartDate, order: .reverse) private var checkIns: [WeeklyCheckIn]

    @State private var quickEditScore: Int = 5
    @State private var quickEditDirty = false

    private var def: ZoneDefinition { ZoneRegistry.definition(for: zone) }

    private var currentWeek: WeeklyCheckIn? {
        let start = Date().isoWeekMonday
        return checkIns.first { Calendar.current.isDate($0.weekStartDate, inSameDayAs: start) }
    }

    private var historyForZone: [(Date, Int)] {
        checkIns.prefix(8).compactMap { ($0.weekStartDate, $0.score(for: zone)) }.reversed()
    }

    private var allScoresForZone: [Int] {
        checkIns.map { $0.score(for: zone) }
    }

    /// Frequency-sorted list of every mood tag the user has ever picked for this zone.
    private var tagFrequency: [(String, Int)] {
        var counts: [String: Int] = [:]
        for c in checkIns {
            if let tag = c.tag(for: zone), !tag.isEmpty {
                counts[tag, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }
    }

    private var bestWeek: (Date, Int)? {
        checkIns.map { ($0.weekStartDate, $0.score(for: zone)) }.max(by: { $0.1 < $1.1 })
    }
    private var worstWeek: (Date, Int)? {
        checkIns.map { ($0.weekStartDate, $0.score(for: zone)) }.min(by: { $0.1 < $1.1 })
    }
    private var averageScore: Double {
        guard !allScoresForZone.isEmpty else { return 0 }
        return Double(allScoresForZone.reduce(0, +)) / Double(allScoresForZone.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    headerCard
                    if currentWeek != nil { quickEditCard }
                    if historyForZone.count >= 2 { historyCard }
                    if !tagFrequency.isEmpty { tagFrequencyCard }
                    if checkIns.count >= 3 { extremesCard }
                    if let note = currentWeek?.note(for: zone), !note.isEmpty {
                        notesCard(note: note)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(LZ.paper.ignoresSafeArea())
            .navigationTitle(def.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { commitIfNeeded(); dismiss() }
                        .foregroundStyle(LZ.tealDeep)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            quickEditScore = currentWeek?.score(for: zone) ?? 5
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZoneGlyph(glyph: def.glyph, size: 24, stroke: 1.7)
                .foregroundStyle(def.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(def.name)
                    .font(.system(size: 22, weight: .medium))
                    .tracking(-0.44)
                    .foregroundStyle(LZ.ink)
                Text(def.blurb)
                    .font(LZType.serifItalic(13))
                    .foregroundStyle(LZ.inkSoft)
            }
            Spacer()
            if let cw = currentWeek {
                Text("\(cw.score(for: zone))")
                    .font(.system(size: 40, weight: .light).monospacedDigit())
                    .tracking(-1)
                    .foregroundStyle(def.color)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(def.color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Quick edit

    private var quickEditCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Adjust this week").uppercaseCaption()
                Spacer()
                Text("\(quickEditScore)")
                    .font(.system(size: 20, weight: .light).monospacedDigit())
                    .foregroundStyle(def.color)
            }
            LZSlider(
                color: def.color,
                score: Binding(
                    get: { quickEditScore },
                    set: { quickEditScore = $0; quickEditDirty = true }
                ),
                rated: true,
                hapticsEnabled: true
            )
            .frame(height: 22)
        }
        .padding(14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - History sparkline

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent weeks").uppercaseCaption()
                Spacer()
                Text("avg \(String(format: "%.1f", averageScore))")
                    .font(.system(size: 11, weight: .medium).monospacedDigit())
                    .foregroundStyle(LZ.inkMute)
            }
            ZoneHistoryView(scores: historyForZone, color: def.color)
                .frame(height: 90)
        }
        .padding(14)
        .background(LZ.paper)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Tag frequency

    private var tagFrequencyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mood tags you've used").uppercaseCaption()
            FlowLayout(spacing: 6) {
                ForEach(tagFrequency, id: \.0) { (tag, count) in
                    HStack(spacing: 5) {
                        Text(tag)
                            .font(.system(size: 12, weight: .medium))
                        Text("\(count)")
                            .font(.system(size: 10, weight: .semibold).monospacedDigit())
                            .foregroundStyle(def.color.opacity(0.75))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(def.color.opacity(0.10)))
                    .overlay(Capsule().strokeBorder(def.color.opacity(0.35), lineWidth: 0.5))
                    .foregroundStyle(def.color)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Best / worst weeks

    private var extremesCard: some View {
        HStack(spacing: 10) {
            if let best = bestWeek {
                extremeTile(label: "Best week", score: best.1, date: best.0, accent: LZ.zGrowth)
            }
            if let worst = worstWeek {
                extremeTile(label: "Lowest week", score: worst.1, date: worst.0, accent: LZ.zVitality)
            }
        }
    }

    private func extremeTile(label: String, score: Int, date: Date, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).uppercaseCaption(size: 9.5, tracking: 1.8)
            HStack(alignment: .firstTextBaseline) {
                Text("\(score)")
                    .font(.system(size: 22, weight: .light).monospacedDigit())
                    .foregroundStyle(accent)
                Text(formatted(date))
                    .font(LZType.serifItalic(12))
                    .foregroundStyle(LZ.inkSoft)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LZ.cream)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func formatted(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: d)
    }

    // MARK: - Notes

    private func notesCard(note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This week's note").uppercaseCaption()
            HStack(alignment: .top, spacing: 8) {
                Rectangle().fill(def.color.opacity(0.5)).frame(width: 2)
                Text(note)
                    .font(LZType.serifItalic(14.5))
                    .lineSpacing(2)
                    .foregroundStyle(LZ.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(LZ.paper)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Commit

    private func commitIfNeeded() {
        guard quickEditDirty, let cw = currentWeek else { return }
        cw.scores[zone.rawValue] = quickEditScore
        try? modelContext.save()
        WidgetDataProvider.update(from: cw)
    }
}
