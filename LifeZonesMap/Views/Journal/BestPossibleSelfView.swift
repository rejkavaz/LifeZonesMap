import SwiftUI
import SwiftData

/// Best Possible Self exercise (King 2001; Sheldon & Lyubomirsky 2006;
/// Layous, Nelson, Lyubomirsky 2013).
///
/// Across multiple RCTs, writing 15 minutes a week for 4 weeks about
/// the best version of your future self produced sustained increases in
/// optimism, positive affect, and life satisfaction. The mechanism is
/// thought to be increased self-efficacy and goal-clarity.
///
/// Stored as PromptResponse entries against a synthetic prompt id so the
/// search/answered features pick them up automatically.
struct BestPossibleSelfView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PromptResponse.createdAt, order: .reverse) private var allResponses: [PromptResponse]

    @State private var response = ""
    @State private var savedJustNow = false
    @State private var showSession = false
    @FocusState private var focused: Bool

    private static let promptID = "bps-current"
    private static let promptText = "Imagine yourself five years from now, having lived as well as you reasonably could have. Don't make it magical — just plausibly the best version. Where do you live? What does an average Tuesday look like? Who's around? What have you become? Write for 10–15 minutes, in present tense, without editing."

    private var prompt: Prompt {
        Prompt(id: Self.promptID, text: Self.promptText, customCategory: "Best Possible Self")
    }

    private var pastSessions: [PromptResponse] {
        allResponses.filter { $0.promptID == Self.promptID }
    }

    private var weeksOfPractice: Int {
        let dates = pastSessions.map { Calendar.current.startOfDay(for: $0.createdAt) }
        return Set(dates).count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if showSession {
                    sessionView
                } else {
                    introCard
                    startButton
                }
                if !pastSessions.isEmpty {
                    pastSessionsSection
                }
                researchFooter
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(LZ.paper.ignoresSafeArea())
        .navigationTitle("Best possible self")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Long exercise · King / Lyubomirsky").uppercaseCaption()
            HStack(alignment: .firstTextBaseline) {
                Text("Five years from now.")
                    .font(.system(size: 24, weight: .medium))
                    .tracking(-0.5)
                    .foregroundStyle(LZ.ink)
                Spacer()
                if weeksOfPractice > 0 {
                    Text("\(weeksOfPractice) session\(weeksOfPractice == 1 ? "" : "s")")
                        .font(.system(size: 12).monospacedDigit())
                        .foregroundStyle(LZ.inkMute)
                }
            }
        }
        .padding(.horizontal, 6)
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Self.promptText)
                .font(LZType.serif(15))
                .lineSpacing(3.5)
                .foregroundStyle(LZ.ink)
        }
        .padding(16)
        .background(LZ.cream)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var startButton: some View {
        Button {
            showSession = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { focused = true }
        } label: {
            Text(pastSessions.isEmpty ? "Begin a session" : "New session")
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(LZ.tealDeep)
                .foregroundStyle(LZ.cream)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var sessionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YOUR FUTURE").uppercaseCaption()
            TextEditor(text: $response)
                .font(LZType.serif(15.5))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 320)
                .padding(12)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .focused($focused)

            HStack {
                Text("\(wordCount) words")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(LZ.inkMute)
                Spacer()
                Text("Aim for 10–15 minutes")
                    .font(LZType.serifItalic(11.5))
                    .foregroundStyle(LZ.inkMute)
            }

            Button(action: save) {
                HStack(spacing: 8) {
                    if savedJustNow {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Saved")
                    } else {
                        Text("Save this session")
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(canSave ? LZ.tealDeep : LZ.rule)
                .foregroundStyle(LZ.cream)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!canSave)
        }
    }

    private var pastSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { SectionTitle(text: "Earlier sessions") }
                .padding(.horizontal, 6)
            ForEach(pastSessions) { session in
                VStack(alignment: .leading, spacing: 6) {
                    Text(dateLabel(session.createdAt))
                        .uppercaseCaption(color: LZ.inkMute, size: 9.5, tracking: 1.6)
                    HStack(alignment: .top, spacing: 8) {
                        Rectangle().fill(LZ.tealDeep.opacity(0.5)).frame(width: 2)
                        Text(session.response)
                            .font(LZType.serifItalic(14))
                            .lineSpacing(2.5)
                            .foregroundStyle(LZ.ink)
                            .lineLimit(8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
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
        }
    }

    private var researchFooter: some View {
        Text("King (2001); Sheldon & Lyubomirsky (2006); Layous, Nelson & Lyubomirsky (2013). Across multiple controlled studies, 15 minutes of weekly writing about your best future self for 4 weeks produced measurable, sustained increases in optimism and life satisfaction.")
            .font(LZType.serifItalic(11.5))
            .lineSpacing(2)
            .foregroundStyle(LZ.inkMute)
            .padding(.top, 12)
    }

    private var canSave: Bool {
        !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var wordCount: Int {
        response.split { $0.isWhitespace }.count
    }

    private func save() {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let r = PromptResponse(promptID: Self.promptID, response: trimmed)
        modelContext.insert(r)
        try? modelContext.save()
        savedJustNow = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            savedJustNow = false
            showSession = false
            response = ""
        }
    }

    private func dateLabel(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"
        return f.string(from: d).uppercased()
    }
}
