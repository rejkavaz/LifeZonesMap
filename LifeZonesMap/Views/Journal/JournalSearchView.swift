import SwiftUI
import SwiftData

/// Search across every text field in the app: check-in notes, weekly
/// reflections, prompt responses, mood drops. Results grouped by source.
struct JournalSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \WeeklyCheckIn.weekStartDate, order: .reverse) private var checkIns: [WeeklyCheckIn]
    @Query(sort: \WeeklyReflection.weekStartDate, order: .reverse) private var reflections: [WeeklyReflection]
    @Query(sort: \PromptResponse.createdAt, order: .reverse) private var promptResponses: [PromptResponse]
    @Query(sort: \MoodDrop.date, order: .reverse) private var moodDrops: [MoodDrop]

    @State private var query = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(LZ.paper)

                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    placeholder
                } else if hasNoResults {
                    noResults
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            if !noteMatches.isEmpty { notesSection }
                            if !reflectionMatches.isEmpty { reflectionsSection }
                            if !promptMatches.isEmpty { promptsSection }
                            if !moodMatches.isEmpty { moodsSection }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .background(LZ.paper.ignoresSafeArea())
            .navigationTitle("Search journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(LZ.tealDeep)
                }
            }
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(LZ.inkMute)
            TextField("Find a word, a feeling, a week...", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(LZ.inkMute)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(LZ.cream)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var placeholder: some View {
        VStack(spacing: 14) {
            Spacer()
            ZoneGlyph(glyph: .focus, size: 32, stroke: 1.4)
                .foregroundStyle(LZ.inkMute.opacity(0.45))
            Text("Try \u{201C}tired\u{201D} or \u{201C}walking\u{201D}.")
                .font(LZType.serifItalic(14))
                .foregroundStyle(LZ.inkSoft)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var noResults: some View {
        VStack(spacing: 10) {
            Spacer()
            Text("No matches.")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(LZ.ink)
            Text("Try a shorter word.")
                .font(LZType.serifItalic(13))
                .foregroundStyle(LZ.inkSoft)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var hasNoResults: Bool {
        noteMatches.isEmpty && reflectionMatches.isEmpty
            && promptMatches.isEmpty && moodMatches.isEmpty
    }

    // MARK: - Matching helpers

    private var needle: String {
        query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// (zone, week date, note text) for each check-in note that matches.
    private var noteMatches: [(ZoneID, Date, String)] {
        guard !needle.isEmpty else { return [] }
        var out: [(ZoneID, Date, String)] = []
        for c in checkIns {
            for zone in ZoneID.allCases {
                if let note = c.note(for: zone),
                   note.lowercased().contains(needle) {
                    out.append((zone, c.weekStartDate, note))
                }
            }
        }
        return out
    }

    private var reflectionMatches: [WeeklyReflection] {
        guard !needle.isEmpty else { return [] }
        return reflections.filter {
            $0.response.lowercased().contains(needle) || $0.prompt.lowercased().contains(needle)
        }
    }

    private var promptMatches: [PromptResponse] {
        guard !needle.isEmpty else { return [] }
        return promptResponses.filter { r in
            if r.response.lowercased().contains(needle) { return true }
            return PromptLibrary.prompt(id: r.promptID)?.text.lowercased().contains(needle) == true
        }
    }

    private var moodMatches: [MoodDrop] {
        guard !needle.isEmpty else { return [] }
        return moodDrops.filter {
            $0.mood.lowercased().contains(needle) || $0.detail.lowercased().contains(needle)
        }
    }

    // MARK: - Sections

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { SectionTitle(text: "Check-in notes · \(noteMatches.count)") }
                .padding(.horizontal, 24)
            ForEach(Array(noteMatches.enumerated()), id: \.offset) { _, match in
                noteRow(zone: match.0, date: match.1, text: match.2)
                    .padding(.horizontal, 18)
            }
        }
    }

    private var reflectionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { SectionTitle(text: "Reflections · \(reflectionMatches.count)") }
                .padding(.horizontal, 24)
            ForEach(reflectionMatches) { r in
                ReflectionCard(reflection: r)
                    .padding(.horizontal, 18)
            }
        }
    }

    private var promptsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { SectionTitle(text: "Prompt answers · \(promptMatches.count)") }
                .padding(.horizontal, 24)
            ForEach(promptMatches) { r in
                if let prompt = PromptLibrary.prompt(id: r.promptID) {
                    promptRow(prompt: prompt, response: r)
                        .padding(.horizontal, 18)
                }
            }
        }
    }

    private var moodsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { SectionTitle(text: "Mood drops · \(moodMatches.count)") }
                .padding(.horizontal, 24)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(moodMatches) { d in MoodDropChip(drop: d) }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    private func noteRow(zone: ZoneID, date: Date, text: String) -> some View {
        let def = ZoneRegistry.definition(for: zone)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                ZoneGlyph(glyph: def.glyph, size: 14, stroke: 1.6)
                    .foregroundStyle(def.color)
                Text(def.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(def.color)
                Spacer()
                Text(date.isoWeekLabel.uppercased())
                    .uppercaseCaption(size: 9.5, tracking: 1.6)
            }
            HStack(alignment: .top, spacing: 8) {
                Rectangle().fill(def.color.opacity(0.5)).frame(width: 2)
                Text(text)
                    .font(LZType.serifItalic(13.5))
                    .lineSpacing(2)
                    .foregroundStyle(LZ.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func promptRow(prompt: Prompt, response: PromptResponse) -> some View {
        let accent: Color = prompt.zone.map { ZoneRegistry.definition(for: $0).color } ?? LZ.tealDeep
        return NavigationLink {
            PromptDetailView(prompt: prompt)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(prompt.category.uppercased())
                    .font(.system(size: 9.5, weight: .bold))
                    .tracking(2.0)
                    .foregroundStyle(accent)
                Text(prompt.text)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(LZ.ink)
                    .lineSpacing(1.5)
                    .multilineTextAlignment(.leading)
                Text(response.response)
                    .font(LZType.serifItalic(13))
                    .lineSpacing(2)
                    .foregroundStyle(LZ.inkSoft)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
