import SwiftUI
import SwiftData

struct PromptLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PromptResponse.createdAt, order: .reverse) private var responses: [PromptResponse]
    @Query(sort: \CustomPrompt.createdAt, order: .reverse) private var custom: [CustomPrompt]

    @State private var filter: ZoneID?    // nil = all zones
    @State private var showAnsweredOnly = false
    @State private var showingNewPrompt = false

    private var answeredIDs: Set<String> {
        Set(responses.map { $0.promptID })
    }

    /// Merge library + custom prompts, applying the zone filter.
    private var prompts: [Prompt] {
        let library = PromptLibrary.filtered(by: filter)
        let userOwn = custom.filter { filter == nil || $0.zone == filter }.map(\.asPrompt)
        var list = library + userOwn
        if showAnsweredOnly {
            list = list.filter { answeredIDs.contains($0.id) }
        }
        return list
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                zoneFilterChips
                Toggle("Only answered", isOn: $showAnsweredOnly)
                    .toggleStyle(.switch)
                    .tint(LZ.tealDeep)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LZ.inkSoft)
                    .padding(.horizontal, 24)
                addYourOwnButton
                promptList
            }
            .padding(.bottom, 40)
        }
        .background(LZ.paper.ignoresSafeArea())
        .navigationTitle("Prompt library")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingNewPrompt = true } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(LZ.tealDeep)
                }
                .accessibilityLabel("Add your own prompt")
            }
        }
        .sheet(isPresented: $showingNewPrompt) {
            CustomPromptEditor()
        }
    }

    private var addYourOwnButton: some View {
        Button { showingNewPrompt = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(LZ.tealDeep)
                Text("Add your own prompt")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(LZ.ink)
                Spacer()
                Text("\(custom.count) saved")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(LZ.inkMute)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(LZ.tealDeep.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(LZ.tealDeep.opacity(0.3), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 18)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(PromptLibrary.all.count) questions").uppercaseCaption()
            Text("Pick a thread.")
                .font(.system(size: 24, weight: .medium))
                .tracking(-0.5)
                .foregroundStyle(LZ.ink)
            Text("Each one's been chosen carefully. Answer in your own time, or just sit with one.")
                .font(LZType.serifItalic(13.5))
                .lineSpacing(2)
                .foregroundStyle(LZ.inkSoft)
                .padding(.top, 2)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private var zoneFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Self.filterChip(label: "All", isSelected: filter == nil, color: LZ.tealDeep) {
                    filter = nil
                }
                ForEach(ZoneID.allCases) { zone in
                    let def = ZoneRegistry.definition(for: zone)
                    Self.filterChip(label: def.name, isSelected: filter == zone, color: def.color) {
                        filter = (filter == zone) ? nil : zone
                    }
                }
            }
            .padding(.horizontal, 18)
        }
    }

    @ViewBuilder
    private static func filterChip(label: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(isSelected ? color.opacity(0.15) : Color.clear))
                .overlay(Capsule().strokeBorder(isSelected ? color : LZ.rule, lineWidth: 0.5))
                .foregroundStyle(isSelected ? color : LZ.inkSoft)
        }
        .buttonStyle(.plain)
    }

    private var promptList: some View {
        LazyVStack(spacing: 8) {
            // Group by category so research notes can sit at section breaks
            let grouped = Dictionary(grouping: prompts, by: { $0.category })
            let categoryOrder = orderedCategories(grouped: grouped)

            ForEach(categoryOrder, id: \.self) { category in
                if let bucket = grouped[category] {
                    if filter == nil {
                        categoryHeader(category)
                    }
                    ForEach(bucket) { prompt in
                        NavigationLink {
                            PromptDetailView(prompt: prompt)
                        } label: {
                            promptRow(prompt: prompt)
                        }
                        .buttonStyle(.plain)
                    }
                    if let note = PromptLibrary.researchNote(for: category) {
                        researchFooter(note: note)
                    }
                }
            }

            if prompts.isEmpty {
                Text("Nothing here yet.")
                    .font(LZType.serifItalic(13.5))
                    .foregroundStyle(LZ.inkSoft)
                    .padding(.top, 60)
            }
        }
        .padding(.horizontal, 18)
    }

    /// Stable order: zone order, then Open, then If-Then, then Custom.
    private func orderedCategories(grouped: [String: [Prompt]]) -> [String] {
        var order: [String] = ZoneRegistry.all.map(\.name)
        order += ["Open", "If-Then", "Custom"]
        return order.filter { grouped[$0] != nil }
    }

    private func categoryHeader(_ name: String) -> some View {
        HStack {
            Text(name.uppercased())
                .uppercaseCaption()
            Rectangle().fill(LZ.ruleSoft).frame(height: 0.5)
        }
        .padding(.top, 14)
    }

    private func researchFooter(note: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 11))
                .foregroundStyle(LZ.inkMute)
                .padding(.top, 2)
            Text(note)
                .font(LZType.serifItalic(11.5))
                .lineSpacing(2)
                .foregroundStyle(LZ.inkSoft)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .padding(.bottom, 6)
    }

    private func promptRow(prompt: Prompt) -> some View {
        let answered = answeredIDs.contains(prompt.id)
        let accent: Color = prompt.zone.map { ZoneRegistry.definition(for: $0).color } ?? LZ.tealDeep

        return HStack(alignment: .top, spacing: 14) {
            Rectangle().fill(accent).frame(width: 3)
            VStack(alignment: .leading, spacing: 6) {
                Text(prompt.category.uppercased())
                    .font(.system(size: 9.5, weight: .bold))
                    .tracking(2.0)
                    .foregroundStyle(accent)
                Text(prompt.text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(LZ.ink)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 12)
            Spacer()
            if answered {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(accent.opacity(0.75))
                    .padding(.top, 14)
                    .padding(.trailing, 4)
            }
        }
        .padding(.trailing, 14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
