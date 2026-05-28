import SwiftUI
import SwiftData

/// Quick mid-week mark: tap "Mark today" on the map and record a one-zone
/// score with a sentence — without going through the full 7-zone ritual.
/// These get folded into the current week's check-in if one exists, or
/// kick off a sparse new one (other zones default to last week's values).
struct QuickMarkSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \WeeklyCheckIn.weekStartDate, order: .reverse) private var history: [WeeklyCheckIn]

    @State private var selectedZone: ZoneID = .vitality
    @State private var score: Int = 7
    @State private var note: String = ""

    private var currentWeek: WeeklyCheckIn? {
        let start = Date().isoWeekMonday
        return history.first { Calendar.current.isDate($0.weekStartDate, inSameDayAs: start) }
    }

    private var existingScore: Int? {
        currentWeek?.score(for: selectedZone)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    zonePicker
                    scoreSection
                    noteSection
                    contextNote
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background(LZ.paper.ignoresSafeArea())
            .navigationTitle("Mark today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LZ.inkSoft)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Mark", action: save)
                        .fontWeight(.semibold)
                        .foregroundStyle(LZ.tealDeep)
                }
            }
        }
        .onAppear {
            // Default to "Vitality" or the user's most-frequently-marked zone
            if let s = existingScore { score = s }
        }
        .onChange(of: selectedZone) {
            if let s = existingScore { score = s } else { score = 7 }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(todayLabel()).uppercaseCaption()
            Text("Something to mark?")
                .font(.system(size: 24, weight: .medium))
                .tracking(-0.5)
                .foregroundStyle(LZ.ink)
            Text("A one-zone update between weekly check-ins. Five seconds.")
                .font(LZType.serifItalic(13))
                .foregroundStyle(LZ.inkSoft)
        }
    }

    private var zonePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ZoneID.allCases) { zone in
                    let def = ZoneRegistry.definition(for: zone)
                    Button {
                        selectedZone = zone
                    } label: {
                        HStack(spacing: 6) {
                            ZoneGlyph(glyph: def.glyph, size: 13, stroke: 1.7)
                                .foregroundStyle(def.color)
                            Text(def.name)
                                .font(.system(size: 12, weight: selectedZone == zone ? .semibold : .medium))
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(selectedZone == zone ? def.color.opacity(0.15) : Color.clear))
                        .overlay(Capsule().strokeBorder(selectedZone == zone ? def.color : LZ.rule, lineWidth: 0.5))
                        .foregroundStyle(selectedZone == zone ? def.color : LZ.inkSoft)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var scoreSection: some View {
        let def = ZoneRegistry.definition(for: selectedZone)
        return VStack(spacing: 12) {
            HStack {
                Text(def.name).uppercaseCaption(color: def.color, size: 10, tracking: 1.8)
                Spacer()
                Text("\(score)")
                    .font(.system(size: 28, weight: .light).monospacedDigit())
                    .foregroundStyle(def.color)
            }
            LZSlider(color: def.color,
                     score: $score,
                     rated: true,
                     hapticsEnabled: true)
                .frame(height: 22)
            if let prev = existingScore, prev != score {
                let arrow = score > prev ? "arrow.up" : "arrow.down"
                let delta = abs(score - prev)
                HStack(spacing: 4) {
                    Image(systemName: arrow)
                        .font(.system(size: 10, weight: .bold))
                    Text("\(score > prev ? "+\(delta)" : "-\(delta)") from earlier this week (\(prev))")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(score > prev ? LZ.zGrowth : LZ.zVitality)
            }
        }
        .padding(14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("What happened?").uppercaseCaption()
            TextField("One line is plenty…", text: $note, axis: .vertical)
                .font(LZType.serifItalic(14))
                .lineLimit(2...4)
                .padding(12)
                .background(LZ.cream)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var contextNote: some View {
        let def = ZoneRegistry.definition(for: selectedZone)
        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 11))
                .foregroundStyle(LZ.inkMute)
                .padding(.top, 1)
            if currentWeek != nil {
                Text("Updates this week's \(def.name) score. Your other zones stay the same.")
                    .font(LZType.serifItalic(12))
                    .foregroundStyle(LZ.inkSoft)
            } else {
                Text("Starts this week's check-in with just \(def.name) — your other zones will default to last week, ready to update on Sunday.")
                    .font(LZType.serifItalic(12))
                    .foregroundStyle(LZ.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }

    // MARK: - Save

    private func save() {
        let service = CheckInService(modelContext: modelContext)
        let weekStart = Date().isoWeekMonday
        let zoneKey = selectedZone.rawValue

        if let existing = try? service.fetchCheckIn(for: weekStart) {
            existing.scores[zoneKey] = score
            if !note.isEmpty {
                existing.notes[zoneKey] = note
            }
            try? modelContext.save()
            WidgetDataProvider.update(from: existing)
        } else {
            // Build a sparse seed — for unrated zones, fall back to last week's
            // value if we have one, else default 5.
            let prior = history.first
            var seed: [ZoneID: Int] = [:]
            for z in ZoneID.allCases {
                seed[z] = z == selectedZone ? score : (prior?.score(for: z) ?? 5)
            }
            var notes: [ZoneID: String] = [:]
            if !note.isEmpty { notes[selectedZone] = note }
            _ = try? service.save(scores: seed, tags: [:], notes: notes)
        }
        dismiss()
    }

    private func todayLabel() -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date()).uppercased()
    }
}
