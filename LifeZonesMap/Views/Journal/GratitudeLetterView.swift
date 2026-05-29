import SwiftUI
import SwiftData

/// The Gratitude Letter exercise (Seligman, Steen, Park & Peterson, 2005).
/// One of the largest single-session interventions in positive psychology:
/// writing a specific letter of gratitude to someone who positively impacted
/// you, and ideally reading it to them, produced an immediate bump in
/// happiness that lasted up to a month — even without delivery.
struct GratitudeLetterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PromptResponse.createdAt, order: .reverse) private var allResponses: [PromptResponse]

    @State private var step: Step = .recipient
    @State private var recipient: String = ""
    @State private var letter: String = ""
    @FocusState private var letterFocused: Bool

    private static let promptID = "gratitude-letter"

    private var pastLetters: [PromptResponse] {
        allResponses.filter { $0.promptID.hasPrefix(Self.promptID) }
    }

    enum Step { case recipient, draft, review }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                switch step {
                case .recipient: recipientStep
                case .draft:     draftStep
                case .review:    reviewStep
                }
                if step == .recipient && !pastLetters.isEmpty {
                    pastLettersSection
                }
                researchFooter
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(LZ.paper.ignoresSafeArea())
        .navigationTitle("Gratitude letter")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(stepLabel).uppercaseCaption(color: LZ.zConnect)
            Text(stepTitle)
                .font(.system(size: 22, weight: .medium))
                .tracking(-0.45)
                .lineSpacing(2)
                .foregroundStyle(LZ.ink)
            Text(stepSubtitle)
                .font(LZType.serifItalic(13.5))
                .lineSpacing(2)
                .foregroundStyle(LZ.inkSoft)
        }
    }

    private var stepLabel: String {
        switch step {
        case .recipient: return "Step 1 of 3"
        case .draft:     return "Step 2 of 3"
        case .review:    return "Step 3 of 3"
        }
    }

    private var stepTitle: String {
        switch step {
        case .recipient: return "Pick one person."
        case .draft:     return "Tell them what they did."
        case .review:    return "Optional: deliver it."
        }
    }

    private var stepSubtitle: String {
        switch step {
        case .recipient:
            return "Someone who positively impacted you and who hasn't been properly thanked. Anyone — alive, distant, departed."
        case .draft:
            return "Be specific. Concrete behaviors, exact moments. Skip the abstract gratitude."
        case .review:
            return "Reading it to them in person is the strongest version. But just writing it has its own effect."
        }
    }

    // MARK: - Step 1 — Recipient

    private var recipientStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Their name (or how you'd address them)", text: $recipient)
                .font(.system(size: 17))
                .padding(14)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button {
                step = .draft
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { letterFocused = true }
            } label: {
                Text("Continue")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(canAdvanceRecipient ? LZ.zConnect : LZ.rule)
                    .foregroundStyle(LZ.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!canAdvanceRecipient)
        }
    }

    private var canAdvanceRecipient: Bool {
        !recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Step 2 — Draft

    private var draftStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("DEAR \(recipient.uppercased()),").uppercaseCaption()
                TextEditor(text: $letter)
                    .font(LZType.serif(15.5))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 280)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .focused($letterFocused)
            }

            Text("\(letter.split { $0.isWhitespace }.count) words")
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(LZ.inkMute)

            HStack(spacing: 10) {
                Button { step = .recipient } label: {
                    Text("Back")
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(LZ.inkSoft)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(LZ.rule, lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)

                Button { step = .review } label: {
                    Text("Done writing")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(canAdvanceDraft ? LZ.zConnect : LZ.rule)
                        .foregroundStyle(LZ.cream)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(!canAdvanceDraft)
            }
        }
    }

    private var canAdvanceDraft: Bool {
        letter.trimmingCharacters(in: .whitespacesAndNewlines).split { $0.isWhitespace }.count >= 30
    }

    // MARK: - Step 3 — Review / save

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("DEAR \(recipient.uppercased()),").uppercaseCaption()
                Text(letter)
                    .font(LZType.serif(15))
                    .lineSpacing(3)
                    .foregroundStyle(LZ.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LZ.cream)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(LZ.zConnect.opacity(0.3), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            ShareLink(item: shareableLetter) {
                Label("Share to deliver", systemImage: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(LZ.tealDeep)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(LZ.tealDeep.opacity(0.4), lineWidth: 0.5)
                    )
            }

            Button(action: save) {
                Text("Save letter")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LZ.zConnect)
                    .foregroundStyle(LZ.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button { step = .draft } label: {
                Text("Keep editing")
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .foregroundStyle(LZ.inkSoft)
            }
        }
    }

    private var shareableLetter: String {
        "Dear \(recipient),\n\n\(letter)"
    }

    private func save() {
        let body = "To \(recipient):\n\n\(letter)"
        modelContext.insert(PromptResponse(promptID: Self.promptID, response: body))
        try? modelContext.save()
        recipient = ""
        letter = ""
        step = .recipient
    }

    // MARK: - Past letters

    private var pastLettersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { SectionTitle(text: "Letters you've written") }
                .padding(.horizontal, 6)
            ForEach(pastLetters) { letter in
                VStack(alignment: .leading, spacing: 6) {
                    Text(dateLabel(letter.createdAt))
                        .uppercaseCaption(color: LZ.inkMute, size: 9.5, tracking: 1.6)
                    Text(letter.response)
                        .font(LZType.serif(14))
                        .lineSpacing(2)
                        .foregroundStyle(LZ.ink)
                        .lineLimit(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LZ.cream)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func dateLabel(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"
        return f.string(from: d).uppercased()
    }

    private var researchFooter: some View {
        Text("Seligman, Steen, Park & Peterson (2005). Participants wrote and personally delivered a letter of gratitude. Wellbeing increased and depressive symptoms decreased — measurably — for up to a month after delivery. Effects appeared even without delivery, though smaller.")
            .font(LZType.serifItalic(11.5))
            .lineSpacing(2)
            .foregroundStyle(LZ.inkMute)
            .padding(.top, 12)
    }
}
