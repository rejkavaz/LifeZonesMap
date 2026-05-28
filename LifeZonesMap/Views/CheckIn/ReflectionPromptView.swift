import SwiftUI
import SwiftData

/// Shown after a successful check-in. Asks one open-ended question seeded
/// by the just-saved scores. Optional — "Skip" is a peer to "Save".
struct ReflectionPromptView: View {
    let checkIn: WeeklyCheckIn
    var onClose: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeeklyCheckIn.weekStartDate, order: .reverse) private var history: [WeeklyCheckIn]

    @State private var response = ""
    @State private var prompt = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hairline header
            HStack {
                Text("Optional · 60 seconds").uppercaseCaption()
                Spacer()
                Button("Skip") { onClose() }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LZ.inkSoft)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Prompt
            Text(prompt)
                .font(.system(size: 26, weight: .medium))
                .tracking(-0.55)
                .lineSpacing(2)
                .foregroundStyle(LZ.ink)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .fixedSize(horizontal: false, vertical: true)

            // Serif-italic guide copy
            Text("Just a line. Not a journal entry.")
                .font(LZType.serifItalic(13))
                .foregroundStyle(LZ.inkSoft)
                .padding(.horizontal, 24)
                .padding(.top, 6)

            // Response field
            VStack(alignment: .leading, spacing: 6) {
                TextEditor(text: $response)
                    .font(LZType.serif(15))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 140)
                    .padding(8)
                    .background(LZ.cream)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .focused($focused)
                HStack {
                    Text("\(response.count) / 280")
                        .font(.system(size: 10).monospacedDigit())
                        .foregroundStyle(LZ.inkMute)
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer()

            Button(action: save) {
                Text("Save reflection")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? LZ.rule : LZ.tealDeep)
                    .foregroundStyle(LZ.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: LZ.tealDeep.opacity(0.22), radius: 12, x: 0, y: 4)
            }
            .disabled(response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .background(LZ.paper.ignoresSafeArea())
        .onAppear {
            prompt = ReflectionPromptGenerator.prompt(for: checkIn, history: history)
            // Don't auto-focus — let the user read the prompt first.
        }
        .onChange(of: response) {
            if response.count > 280 { response = String(response.prefix(280)) }
        }
    }

    private func save() {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let r = WeeklyReflection(
            weekStartDate: checkIn.weekStartDate,
            prompt: prompt,
            response: trimmed
        )
        modelContext.insert(r)
        try? modelContext.save()
        onClose()
    }
}
