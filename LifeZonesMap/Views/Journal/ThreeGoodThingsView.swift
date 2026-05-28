import SwiftUI
import SwiftData

/// The "Three Good Things" exercise (Seligman, Steen, Park & Peterson, 2005).
/// At the end of each day or week, write down three things that went well —
/// and importantly, *why* they went well. Replicated studies show sustained
/// wellbeing gains months after the intervention ends.
struct ThreeGoodThingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \GoodThing.weekStartDate, order: .reverse) private var allThings: [GoodThing]

    @State private var drafts: [Draft] = [Draft(), Draft(), Draft()]
    @FocusState private var focusedIndex: Int?

    private var thisWeekStart: Date { Date().isoWeekMonday }

    private var thisWeeksThings: [GoodThing] {
        allThings.filter {
            Calendar.current.isDate($0.weekStartDate, inSameDayAs: thisWeekStart)
        }
    }

    private var pastWeeks: [(Date, [GoodThing])] {
        let grouped = Dictionary(grouping: allThings.filter {
            !Calendar.current.isDate($0.weekStartDate, inSameDayAs: thisWeekStart)
        }) { Calendar.current.startOfDay(for: $0.weekStartDate) }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if thisWeeksThings.isEmpty {
                    draftsSection
                    saveButton
                } else {
                    savedThisWeekSection
                }
                if !pastWeeks.isEmpty {
                    historySection
                }
                researchNote
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(LZ.paper.ignoresSafeArea())
        .navigationTitle("Three good things")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Weekly exercise · Seligman").uppercaseCaption()
            Text("Three things that went well this week.")
                .font(.system(size: 22, weight: .medium))
                .tracking(-0.45)
                .lineSpacing(2)
                .foregroundStyle(LZ.ink)
            Text("Specific. And why.")
                .font(LZType.serifItalic(13.5))
                .foregroundStyle(LZ.inkSoft)
        }
        .padding(.horizontal, 6)
    }

    // MARK: - Drafts

    private var draftsSection: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { i in
                draftCard(index: i)
            }
        }
    }

    private func draftCard(index: Int) -> some View {
        let accent: Color = [LZ.zGrowth, LZ.zCreate, LZ.zDeepWork][index]
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("#\(index + 1)").uppercaseCaption(color: accent, size: 11, tracking: 1.8)
                Spacer()
            }
            TextField("What went well?", text: $drafts[index].text, axis: .vertical)
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1...3)
                .focused($focusedIndex, equals: index * 2)
            TextField("Why do you think it happened?", text: $drafts[index].why, axis: .vertical)
                .font(LZType.serifItalic(13.5))
                .foregroundStyle(LZ.inkSoft)
                .lineLimit(1...3)
                .focused($focusedIndex, equals: index * 2 + 1)
        }
        .padding(14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(accent.opacity(0.4), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var saveButton: some View {
        let count = drafts.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        return Button(action: save) {
            Text(count == 0 ? "Add at least one" : "Save \(count) of 3")
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(count > 0 ? LZ.tealDeep : LZ.rule)
                .foregroundStyle(LZ.cream)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(count == 0)
    }

    private func save() {
        for draft in drafts {
            let text = draft.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            let why = draft.why.trimmingCharacters(in: .whitespacesAndNewlines)
            modelContext.insert(GoodThing(weekStartDate: thisWeekStart, text: text, why: why))
        }
        try? modelContext.save()
        drafts = [Draft(), Draft(), Draft()]
    }

    // MARK: - Saved this week

    private var savedThisWeekSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This week, saved").uppercaseCaption()
            ForEach(thisWeeksThings) { thing in
                goodThingRow(thing: thing, accent: LZ.zGrowth, allowDelete: true)
            }
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { SectionTitle(text: "Earlier weeks") }
                .padding(.horizontal, 6)
            ForEach(pastWeeks, id: \.0) { (date, things) in
                VStack(alignment: .leading, spacing: 8) {
                    Text(weekLabel(date))
                        .uppercaseCaption(color: LZ.inkMute, size: 9.5, tracking: 1.6)
                    ForEach(things) { thing in
                        goodThingRow(thing: thing, accent: LZ.tealDeep, allowDelete: false)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private func goodThingRow(thing: GoodThing, accent: Color, allowDelete: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(accent)
                .frame(width: 6, height: 6)
                .padding(.top, 7)
            VStack(alignment: .leading, spacing: 3) {
                Text(thing.text)
                    .font(.system(size: 14, weight: .medium))
                    .lineSpacing(1.5)
                    .foregroundStyle(LZ.ink)
                if !thing.why.isEmpty {
                    Text(thing.why)
                        .font(LZType.serifItalic(13))
                        .foregroundStyle(LZ.inkSoft)
                        .lineSpacing(1.5)
                }
            }
            Spacer()
            if allowDelete {
                Button {
                    modelContext.delete(thing)
                    try? modelContext.save()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LZ.inkMute)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(allowDelete ? LZ.cream : Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Research footer

    private var researchNote: some View {
        Text("Seligman, Steen, Park & Peterson (2005). Participants who wrote three good things and explained *why they happened* once a week showed elevated happiness and reduced depressive symptoms 1, 3, and 6 months later.")
            .font(LZType.serifItalic(11.5))
            .lineSpacing(2)
            .foregroundStyle(LZ.inkMute)
            .padding(.top, 12)
    }

    private func weekLabel(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return "WEEK OF \(f.string(from: d))".uppercased()
    }

    struct Draft {
        var text: String = ""
        var why: String = ""
    }
}
