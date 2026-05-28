import SwiftUI

struct MoodDropEntryView: View {
    var onSave: (MoodDrop) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var mood = ""
    @State private var detail = ""
    @FocusState private var moodFocused: Bool

    private static let suggestions: [[String]] = [
        ["steady",  "tired",   "curious", "tender",  "wired",  "soft"],
        ["restless","content", "foggy",   "lit",     "frayed", "hopeful"],
        ["quiet",   "scattered","sharp",  "anxious", "alive",  "stuck"]
    ]

    /// A new random row every time the sheet opens — keeps it from feeling like
    /// the same six choices forever.
    @State private var visibleRow: [String] = MoodDropEntryView.suggestions.randomElement()!

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("How are you, right now?").uppercaseCaption()
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                Text("Just a word")
                    .font(.system(size: 24, weight: .medium))
                    .tracking(-0.5)
                    .foregroundStyle(LZ.ink)
                    .padding(.horizontal, 24)

                TextField("steady, curious, foggy...", text: $mood)
                    .font(.system(size: 22, weight: .light, design: .serif).italic())
                    .foregroundStyle(LZ.ink)
                    .focused($moodFocused)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.return)
                    .padding(14)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 18)

                FlowLayout(spacing: 6) {
                    ForEach(visibleRow, id: \.self) { s in
                        Button {
                            mood = s
                        } label: {
                            Text(s)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(LZ.cream))
                                .overlay(Capsule().strokeBorder(LZ.rule, lineWidth: 0.5))
                                .foregroundStyle(LZ.inkSoft)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)

                Text("Optional: anything else?").uppercaseCaption()
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                TextField("A line, if there's one...", text: $detail, axis: .vertical)
                    .font(LZType.serifItalic(14))
                    .lineLimit(2...4)
                    .padding(12)
                    .background(LZ.cream)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 18)

                Spacer()

                Button(action: commit) {
                    Text("Drop it")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(canSave ? LZ.tealDeep : LZ.rule)
                        .foregroundStyle(LZ.cream)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: canSave ? LZ.tealDeep.opacity(0.22) : .clear,
                                radius: 12, x: 0, y: 4)
                }
                .disabled(!canSave)
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
            .background(LZ.paper.ignoresSafeArea())
            .navigationTitle("Mood drop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LZ.inkSoft)
                }
            }
        }
        .onAppear { moodFocused = true }
    }

    private var canSave: Bool {
        !mood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func commit() {
        let trimmed = mood.trimmingCharacters(in: .whitespacesAndNewlines)
        let drop = MoodDrop(mood: trimmed,
                            detail: detail.trimmingCharacters(in: .whitespacesAndNewlines))
        onSave(drop)
    }
}

// MARK: - Mood chip used in the journal strip

struct MoodDropChip: View {
    let drop: MoodDrop

    private static let palette: [Color] = [
        LZ.zVitality, LZ.zDeepWork, LZ.zConnect, LZ.zInner,
        LZ.zCreate,   LZ.zFound,    LZ.zGrowth
    ]

    private var color: Color {
        Self.palette[abs(drop.mood.hashValue) % Self.palette.count]
    }

    private var dayLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: drop.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(drop.mood)
                .font(.system(size: 16, weight: .medium, design: .serif).italic())
                .foregroundStyle(color)
            Text(dayLabel)
                .uppercaseCaption(color: LZ.inkMute, size: 9, tracking: 1.4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(color.opacity(0.35), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .frame(minWidth: 90)
    }
}
