import SwiftUI
import SwiftData

struct PromptDetailView: View {
    let prompt: Prompt

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingResponses: [PromptResponse]
    @State private var response = ""
    @FocusState private var focused: Bool
    @State private var savedJustNow = false

    private var existingForPrompt: [PromptResponse] {
        existingResponses
            .filter { $0.promptID == prompt.id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var accent: Color {
        prompt.zone.map { ZoneRegistry.definition(for: $0).color } ?? LZ.tealDeep
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Category eyebrow + prompt
                VStack(alignment: .leading, spacing: 8) {
                    Text(prompt.category.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2.4)
                        .foregroundStyle(accent)
                    Text(prompt.text)
                        .font(.system(size: 26, weight: .medium))
                        .tracking(-0.55)
                        .lineSpacing(3)
                        .foregroundStyle(LZ.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                // Response field
                VStack(alignment: .leading, spacing: 6) {
                    Text("YOUR ANSWER").uppercaseCaption()
                    TextEditor(text: $response)
                        .font(LZType.serif(15))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 180)
                        .padding(10)
                        .background(LZ.cream)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .focused($focused)
                }
                .padding(.horizontal, 18)

                // Save button
                Button(action: save) {
                    HStack(spacing: 8) {
                        if savedJustNow {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Saved")
                        } else {
                            Text("Save answer")
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(canSave ? accent : LZ.rule)
                    .foregroundStyle(LZ.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!canSave)
                .padding(.horizontal, 18)

                // Past answers to this same prompt
                if !existingForPrompt.isEmpty {
                    pastAnswersSection
                        .padding(.top, 6)
                }
            }
            .padding(.bottom, 40)
        }
        .background(LZ.paper.ignoresSafeArea())
        .navigationTitle(prompt.category)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !existingForPrompt.isEmpty {
                    Menu {
                        ForEach(existingForPrompt) { r in
                            Button("Delete \(short(r.createdAt))") {
                                modelContext.delete(r)
                                try? modelContext.save()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(LZ.inkSoft)
                    }
                }
            }
        }
    }

    private var pastAnswersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { SectionTitle(text: "Earlier answers") }
                .padding(.horizontal, 24)

            ForEach(existingForPrompt) { r in
                VStack(alignment: .leading, spacing: 6) {
                    Text(formatted(r.createdAt))
                        .uppercaseCaption(size: 9.5, tracking: 1.8)
                    HStack(alignment: .top, spacing: 8) {
                        Rectangle().fill(accent.opacity(0.5)).frame(width: 2)
                        Text(r.response)
                            .font(LZType.serifItalic(14.5))
                            .lineSpacing(2.5)
                            .foregroundStyle(LZ.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LZ.paper)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 18)
            }
        }
    }

    private var canSave: Bool {
        !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let r = PromptResponse(promptID: prompt.id, response: trimmed)
        modelContext.insert(r)
        try? modelContext.save()
        response = ""
        savedJustNow = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            savedJustNow = false
        }
    }

    private func formatted(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"; return f.string(from: d).uppercased()
    }

    private func short(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: d)
    }
}

// MARK: - Browse-only list of every prompt the user has answered

struct AnsweredPromptsView: View {
    @Query(sort: \PromptResponse.createdAt, order: .reverse) private var responses: [PromptResponse]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if responses.isEmpty {
                    Text("You haven't answered any prompts yet.")
                        .font(LZType.serifItalic(14))
                        .foregroundStyle(LZ.inkSoft)
                        .padding(.top, 60)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(responses) { r in
                        if let prompt = PromptLibrary.prompt(id: r.promptID) {
                            row(prompt: prompt, response: r)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(LZ.paper.ignoresSafeArea())
        .navigationTitle("Your answers")
        .navigationBarTitleDisplayMode(.large)
    }

    private func row(prompt: Prompt, response: PromptResponse) -> some View {
        let accent: Color = prompt.zone.map { ZoneRegistry.definition(for: $0).color } ?? LZ.tealDeep
        return NavigationLink {
            PromptDetailView(prompt: prompt)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(prompt.category.uppercased())
                        .font(.system(size: 9.5, weight: .bold))
                        .tracking(2.0)
                        .foregroundStyle(accent)
                    Spacer()
                    Text(timeLabel(response.createdAt))
                        .font(.system(size: 10))
                        .foregroundStyle(LZ.inkMute)
                }
                Text(prompt.text)
                    .font(.system(size: 14, weight: .medium))
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
            .padding(14)
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

    private func timeLabel(_ d: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: d, relativeTo: Date())
    }
}
