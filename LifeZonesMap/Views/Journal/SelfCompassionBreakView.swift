import SwiftUI
import SwiftData

/// The Self-Compassion Break — Kristin Neff's formal three-step practice
/// (Neff, 2003 / 2011). Designed to be used in the moment when something
/// hard is happening. The three steps map to Neff's three components of
/// self-compassion: mindfulness, common humanity, self-kindness.
struct SelfCompassionBreakView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PromptResponse.createdAt, order: .reverse) private var allResponses: [PromptResponse]

    @State private var step: Int = 0      // 0 = intro, 1-3 = steps, 4 = saved
    @State private var note: String = ""
    @FocusState private var noteFocused: Bool

    private static let promptID = "self-compassion-break"

    private var pastSessions: [PromptResponse] {
        allResponses.filter { $0.promptID == Self.promptID }
    }

    private let stepData: [SCBStep] = [
        .init(
            label: "STEP 1 OF 3 · MINDFULNESS",
            heading: "This is a moment of suffering.",
            note: "Acknowledge what's hard without exaggerating or minimizing it. Just naming it.",
            altPhrases: [
                "This hurts.",
                "Ouch.",
                "This is stress.",
                "I'm having a hard time right now."
            ]
        ),
        .init(
            label: "STEP 2 OF 3 · COMMON HUMANITY",
            heading: "Suffering is part of being human.",
            note: "Other people feel this. You're not uniquely broken. This is the cost of caring.",
            altPhrases: [
                "Other people feel this way.",
                "I'm not alone in this.",
                "Everyone struggles in their life.",
                "This is part of being alive."
            ]
        ),
        .init(
            label: "STEP 3 OF 3 · SELF-KINDNESS",
            heading: "May I be kind to myself.",
            note: "Place a hand on your heart if it helps. Speak to yourself as you'd speak to a friend going through this.",
            altPhrases: [
                "May I give myself the compassion I need.",
                "May I accept myself as I am.",
                "May I be patient with myself.",
                "May I forgive myself."
            ]
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if step == 0 {
                    introView
                } else if step >= 1 && step <= 3 {
                    stepView(stepData[step - 1])
                } else {
                    completedView
                }
                if step == 0 && !pastSessions.isEmpty {
                    historySection
                }
                researchFooter
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(LZ.paper.ignoresSafeArea())
        .navigationTitle("Self-compassion break")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("As needed · 2-3 minutes").uppercaseCaption(color: LZ.zVitality)
                Text("Three steps for a hard moment.")
                    .font(.system(size: 22, weight: .medium))
                    .tracking(-0.45)
                    .foregroundStyle(LZ.ink)
                Text("Kristin Neff's formal practice. Use it when you're being self-critical — at the desk, in the car, anywhere.")
                    .font(LZType.serifItalic(13.5))
                    .lineSpacing(2)
                    .foregroundStyle(LZ.inkSoft)
            }

            ForEach(stepData.indices, id: \.self) { i in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(i + 1)")
                        .font(.system(size: 18, weight: .medium).monospacedDigit())
                        .foregroundStyle(LZ.zVitality)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(stepData[i].heading)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(LZ.ink)
                        Text(stepData[i].note)
                            .font(LZType.serifItalic(12.5))
                            .foregroundStyle(LZ.inkSoft)
                            .lineSpacing(1.5)
                    }
                }
                .padding(.bottom, 8)
            }

            Button { step = 1 } label: {
                Text("Start")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LZ.zVitality)
                    .foregroundStyle(LZ.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // MARK: - Step view

    private func stepView(_ data: SCBStep) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(data.label).uppercaseCaption(color: LZ.zVitality)
                Text(data.heading)
                    .font(.system(size: 26, weight: .medium))
                    .tracking(-0.5)
                    .lineSpacing(3)
                    .foregroundStyle(LZ.ink)
                Text(data.note)
                    .font(LZType.serifItalic(14))
                    .lineSpacing(2)
                    .foregroundStyle(LZ.inkSoft)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("OR TRY ONE OF THESE").uppercaseCaption(color: LZ.inkMute)
                VStack(spacing: 8) {
                    ForEach(data.altPhrases, id: \.self) { p in
                        Text(p)
                            .font(LZType.serif(15))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(LZ.cream)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .foregroundStyle(LZ.ink)
                    }
                }
            }

            if step == 3 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("OPTIONAL · ONE LINE").uppercaseCaption()
                    TextField("What was the moment?", text: $note, axis: .vertical)
                        .font(LZType.serifItalic(14))
                        .lineLimit(2...4)
                        .padding(12)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .focused($noteFocused)
                }
            }

            Button { advance() } label: {
                Text(step == 3 ? "Finish" : "Next")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LZ.zVitality)
                    .foregroundStyle(LZ.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // MARK: - Completed

    private var completedView: some View {
        VStack(spacing: 14) {
            ZoneGlyph(glyph: .moon, size: 32, stroke: 1.5)
                .foregroundStyle(LZ.zVitality)
                .padding(.top, 20)
            Text("Saved.")
                .font(.system(size: 22, weight: .medium))
                .tracking(-0.45)
                .foregroundStyle(LZ.ink)
            Text("Come back any time you need it.")
                .font(LZType.serifItalic(13.5))
                .foregroundStyle(LZ.inkSoft)
            Button { reset() } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LZ.tealDeep)
                    .foregroundStyle(LZ.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.top, 12)
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { SectionTitle(text: "Past breaks") }
                .padding(.horizontal, 6)
            HStack(spacing: 8) {
                Text("\(pastSessions.count)")
                    .font(.system(size: 22, weight: .medium).monospacedDigit())
                    .foregroundStyle(LZ.zVitality)
                Text("breaks taken so far")
                    .font(LZType.serifItalic(13))
                    .foregroundStyle(LZ.inkSoft)
                Spacer()
            }
            .padding(14)
            .background(LZ.cream)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var researchFooter: some View {
        Text("Neff (2003, 2011). Self-compassion has three components: self-kindness vs self-judgment, common humanity vs isolation, and mindfulness vs over-identification. Meta-analyses link higher self-compassion to lower depression and anxiety, and greater wellbeing.")
            .font(LZType.serifItalic(11.5))
            .lineSpacing(2)
            .foregroundStyle(LZ.inkMute)
            .padding(.top, 12)
    }

    // MARK: - Actions

    private func advance() {
        if step == 3 {
            save()
            step = 4
        } else {
            step += 1
        }
    }

    private func save() {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = trimmed.isEmpty
            ? "Self-compassion break · 3 steps completed"
            : "Self-compassion break · \"\(trimmed)\""
        modelContext.insert(PromptResponse(promptID: Self.promptID, response: body))
        try? modelContext.save()
    }

    private func reset() {
        step = 0
        note = ""
    }
}

struct SCBStep {
    let label: String
    let heading: String
    let note: String
    let altPhrases: [String]
}
