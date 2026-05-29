import SwiftUI
import SwiftData

/// Loving-Kindness Meditation (LKM) — Fredrickson, Cohn, Coffey, Pek & Finkel
/// (2008) showed that 7 weeks of LKM produced sustained increases in
/// daily positive emotions, social connection, and life satisfaction.
///
/// This is a guided 5-step flow. Each step offers a person/group to direct
/// warmth toward, with three traditional phrases. A breathing rhythm
/// indicator and a per-step timer let the user move at their own pace.
struct LovingKindnessView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PromptResponse.createdAt, order: .reverse) private var allResponses: [PromptResponse]

    @State private var stepIndex = 0
    @State private var sessionStartedAt: Date?
    @State private var sessionFinished = false
    @State private var stepDurations: [TimeInterval] = []
    @State private var stepStartedAt: Date = .now
    @State private var breathScale: CGFloat = 1.0

    private static let promptID = "lkm-session"

    private var pastSessions: [PromptResponse] {
        allResponses.filter { $0.promptID == Self.promptID }
    }

    private let steps: [LKMStep] = [
        .init(label: "STEP 1 OF 5", title: "Yourself.",
              note: "Start where it's hardest for many — by offering kindness to you.",
              accent: LZ.zCreate),
        .init(label: "STEP 2 OF 5", title: "Someone you love.",
              note: "Picture them clearly. A parent, partner, friend, child, pet — anyone easy.",
              accent: LZ.zConnect),
        .init(label: "STEP 3 OF 5", title: "Someone neutral.",
              note: "A barista, a colleague you barely know, a neighbor. Someone you have no particular feeling for.",
              accent: LZ.zInner),
        .init(label: "STEP 4 OF 5", title: "Someone difficult.",
              note: "Not your worst conflict — that's advanced. Pick someone mildly difficult. A coworker who annoys you.",
              accent: LZ.zVitality),
        .init(label: "STEP 5 OF 5", title: "All beings.",
              note: "Widen outward. Your block. Your city. The country. The world. Every being.",
              accent: LZ.zGrowth)
    ]

    /// The four classical LKM phrases.
    private let phrases: [String] = [
        "May you be safe.",
        "May you be healthy.",
        "May you be happy.",
        "May you live with ease."
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if sessionFinished {
                    finishedView
                } else if sessionStartedAt == nil {
                    introView
                } else {
                    sessionView
                }
                if sessionStartedAt == nil && !pastSessions.isEmpty {
                    pastSessionsSection
                }
                researchFooter
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(LZ.paper.ignoresSafeArea())
        .navigationTitle("Loving-kindness")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Five steps · about 5 minutes").uppercaseCaption(color: LZ.zCreate)
                Text("Send warmth in widening circles.")
                    .font(.system(size: 22, weight: .medium))
                    .tracking(-0.45)
                    .foregroundStyle(LZ.ink)
                Text("Traditional Buddhist practice; modern psychology research backs sustained effects on positive affect and social connection.")
                    .font(LZType.serifItalic(13.5))
                    .lineSpacing(2)
                    .foregroundStyle(LZ.inkSoft)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(steps.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(i + 1)")
                            .font(.system(size: 13, weight: .semibold).monospacedDigit())
                            .foregroundStyle(steps[i].accent)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(steps[i].title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(LZ.ink)
                            Text(steps[i].note)
                                .font(LZType.serifItalic(12.5))
                                .foregroundStyle(LZ.inkSoft)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .padding(14)
            .background(LZ.cream)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button(action: start) {
                Text(pastSessions.isEmpty ? "Begin" : "Begin another session")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LZ.zCreate)
                    .foregroundStyle(LZ.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // MARK: - Session

    private var sessionView: some View {
        let step = steps[stepIndex]
        return VStack(spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text(step.label).uppercaseCaption(color: step.accent)
                Text(step.title)
                    .font(.system(size: 28, weight: .medium))
                    .tracking(-0.55)
                    .foregroundStyle(LZ.ink)
                Text(step.note)
                    .font(LZType.serifItalic(14))
                    .lineSpacing(2)
                    .foregroundStyle(LZ.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Breathing circle
            ZStack {
                Circle()
                    .fill(step.accent.opacity(0.10))
                    .frame(width: 180, height: 180)
                Circle()
                    .fill(step.accent.opacity(0.25))
                    .frame(width: 120, height: 120)
                    .scaleEffect(breathScale)
                Circle()
                    .fill(step.accent)
                    .frame(width: 18, height: 18)
            }
            .frame(height: 200)

            // Phrases
            VStack(spacing: 10) {
                ForEach(phrases, id: \.self) { phrase in
                    Text(phrase)
                        .font(LZType.serif(17))
                        .foregroundStyle(LZ.ink)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)

            Button(action: nextStep) {
                Text(stepIndex == steps.count - 1 ? "Finish" : "Next")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(step.accent)
                    .foregroundStyle(LZ.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .onAppear { startBreath() }
        .onChange(of: stepIndex) { startBreath() }
    }

    // MARK: - Finished

    private var finishedView: some View {
        let total: Int = Int(stepDurations.reduce(0, +))
        return VStack(spacing: 14) {
            ZoneGlyph(glyph: .spark, size: 36, stroke: 1.5)
                .foregroundStyle(LZ.zCreate)
                .padding(.top, 20)
            Text("Session complete.")
                .font(.system(size: 22, weight: .medium))
                .tracking(-0.45)
                .foregroundStyle(LZ.ink)
            Text("\(AudioFormat.mmss(TimeInterval(total))) · saved.")
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

    // MARK: - Past sessions

    private var pastSessionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { SectionTitle(text: "Past sessions") }
                .padding(.horizontal, 6)
            HStack(spacing: 6) {
                Text("\(pastSessions.count) saved")
                    .uppercaseCaption(color: LZ.inkMute, size: 10, tracking: 1.6)
                Spacer()
                Text("Latest: \(relative(pastSessions[0].createdAt))")
                    .font(.system(size: 11))
                    .foregroundStyle(LZ.inkSoft)
            }
            .padding(12)
            .background(LZ.cream)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    // MARK: - Actions

    private func start() {
        stepIndex = 0
        sessionFinished = false
        sessionStartedAt = .now
        stepStartedAt = .now
        stepDurations = []
    }

    private func nextStep() {
        let elapsed = Date().timeIntervalSince(stepStartedAt)
        stepDurations.append(elapsed)
        if stepIndex == steps.count - 1 {
            finish()
        } else {
            stepIndex += 1
            stepStartedAt = .now
        }
    }

    private func finish() {
        let total = stepDurations.reduce(0, +)
        let body = "Loving-kindness session · \(AudioFormat.mmss(total)) over \(steps.count) steps"
        modelContext.insert(PromptResponse(promptID: Self.promptID, response: body))
        try? modelContext.save()
        sessionFinished = true
    }

    private func reset() {
        sessionStartedAt = nil
        sessionFinished = false
        stepIndex = 0
        stepDurations = []
    }

    private func startBreath() {
        breathScale = 1.0
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            breathScale = 1.4
        }
    }

    private func relative(_ d: Date) -> String {
        let f = RelativeDateTimeFormatter(); f.unitsStyle = .short
        return f.localizedString(for: d, relativeTo: Date())
    }

    private var researchFooter: some View {
        Text("Fredrickson, Cohn, Coffey, Pek & Finkel (2008). Seven weeks of loving-kindness meditation produced sustained increases in daily positive emotions, mindfulness, sense of purpose, and social connection — independent of baseline.")
            .font(LZType.serifItalic(11.5))
            .lineSpacing(2)
            .foregroundStyle(LZ.inkMute)
            .padding(.top, 12)
    }
}

struct LKMStep {
    let label: String
    let title: String
    let note: String
    let accent: Color
}
