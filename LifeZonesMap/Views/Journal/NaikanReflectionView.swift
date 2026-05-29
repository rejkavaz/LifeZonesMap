import SwiftUI
import SwiftData

/// Naikan reflection — Japanese self-reflection method developed by Ishin
/// Yoshimoto in the 1940s, adapted into Naikan therapy and now used widely
/// in cross-cultural positive psychology and gratitude research.
///
/// Three questions about a single relationship:
///   1. What have I received from this person?
///   2. What have I given to this person?
///   3. What troubles or difficulties have I caused this person?
///
/// The 3:1 weighting toward awareness of what one has received and how one
/// has affected others (vs grievances) is the core mechanism — it directly
/// counters the negativity bias most people apply to relationships under
/// stress.
struct NaikanReflectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PromptResponse.createdAt, order: .reverse) private var allResponses: [PromptResponse]

    @State private var step: Int = 0     // 0 = pick person, 1-3 = questions, 4 = saved
    @State private var person: String = ""
    @State private var received: String = ""
    @State private var given: String = ""
    @State private var troubles: String = ""
    @FocusState private var focused: Bool

    private static let promptID = "naikan-reflection"

    private var pastSessions: [PromptResponse] {
        allResponses.filter { $0.promptID == Self.promptID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                switch step {
                case 0: personStep
                case 1: receivedStep
                case 2: givenStep
                case 3: troublesStep
                default: completedStep
                }
                if step == 0 && !pastSessions.isEmpty {
                    pastSessionsSection
                }
                researchFooter
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(LZ.paper.ignoresSafeArea())
        .navigationTitle("Naikan")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header

    private var header: some View {
        let label: String = {
            switch step {
            case 0: return "Naikan reflection"
            case 1: return "Step 1 of 3"
            case 2: return "Step 2 of 3"
            case 3: return "Step 3 of 3"
            default: return "Saved"
            }
        }()
        let title: String = {
            switch step {
            case 0: return "Three questions, one person."
            case 1: return "What have I received from \(person)?"
            case 2: return "What have I given to \(person)?"
            case 3: return "What troubles have I caused \(person)?"
            default: return "Saved."
            }
        }()
        return VStack(alignment: .leading, spacing: 6) {
            Text(label).uppercaseCaption(color: LZ.zConnect)
            Text(title)
                .font(.system(size: 22, weight: .medium))
                .tracking(-0.45)
                .lineSpacing(2)
                .foregroundStyle(LZ.ink)
            if step == 0 {
                Text("Hold one person in mind. Pick the same relationship for all three answers. Sit with each before writing.")
                    .font(LZType.serifItalic(13))
                    .lineSpacing(2)
                    .foregroundStyle(LZ.inkSoft)
            }
        }
    }

    // MARK: - Steps

    private var personStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("THE PERSON").uppercaseCaption()
            TextField("Their name", text: $person)
                .font(.system(size: 17, weight: .medium))
                .padding(14)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .focused($focused)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(i + 1)")
                            .font(.system(size: 14, weight: .medium).monospacedDigit())
                            .foregroundStyle(LZ.zConnect)
                            .frame(width: 22)
                        Text([
                            "What have I received from this person?",
                            "What have I given to this person?",
                            "What troubles or difficulties have I caused this person?"
                        ][i])
                        .font(LZType.serifItalic(13.5))
                        .foregroundStyle(LZ.inkSoft)
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

            Button {
                step = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { focused = true }
            } label: {
                Text("Continue")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(canAdvancePerson ? LZ.zConnect : LZ.rule)
                    .foregroundStyle(LZ.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!canAdvancePerson)
        }
        .onAppear { focused = true }
    }

    private var canAdvancePerson: Bool {
        !person.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var receivedStep: some View {
        questionStep(
            text: $received,
            placeholder: "Material things, time, attention, kindness — the small and the large.",
            isLastQuestion: false
        )
    }

    private var givenStep: some View {
        questionStep(
            text: $given,
            placeholder: "What did I offer? Be specific. The point isn't to feel virtuous.",
            isLastQuestion: false
        )
    }

    private var troublesStep: some View {
        questionStep(
            text: $troubles,
            placeholder: "Honestly. This isn't self-flagellation — it's recognition. The point is the looking, not the verdict.",
            isLastQuestion: true
        )
    }

    @ViewBuilder
    private func questionStep(text: Binding<String>, placeholder: String, isLastQuestion: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: text)
                .font(LZType.serif(15))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 200)
                .padding(12)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .focused($focused)
                .overlay(alignment: .topLeading) {
                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .font(LZType.serifItalic(14))
                            .foregroundStyle(LZ.inkMute)
                            .padding(20)
                            .allowsHitTesting(false)
                    }
                }

            HStack(spacing: 10) {
                Button { step -= 1 } label: {
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
                Button {
                    if isLastQuestion {
                        save(); step = 4
                    } else {
                        step += 1
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { focused = true }
                    }
                } label: {
                    Text(isLastQuestion ? "Finish" : "Continue")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? LZ.rule : LZ.zConnect)
                        .foregroundStyle(LZ.cream)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear { focused = true }
    }

    private var completedStep: some View {
        VStack(spacing: 14) {
            ZoneGlyph(glyph: .people, size: 32, stroke: 1.5)
                .foregroundStyle(LZ.zConnect)
                .padding(.top, 20)
            Text("Saved.")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(LZ.ink)
            Text("Sit with what you just wrote.")
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

    private var pastSessionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { SectionTitle(text: "Past reflections") }
                .padding(.horizontal, 6)
            ForEach(pastSessions) { session in
                VStack(alignment: .leading, spacing: 6) {
                    Text(formatted(session.createdAt))
                        .uppercaseCaption(color: LZ.inkMute, size: 9.5, tracking: 1.6)
                    Text(session.response)
                        .font(LZType.serif(13))
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

    private var researchFooter: some View {
        Text("Naikan (Yoshimoto, 1940s). Now used widely in psychotherapy + positive psychology contexts. The 3:1 ratio toward awareness of received vs caused suffering counters the negativity bias most people apply to close relationships under stress.")
            .font(LZType.serifItalic(11.5))
            .lineSpacing(2)
            .foregroundStyle(LZ.inkMute)
            .padding(.top, 12)
    }

    // MARK: - Save

    private func save() {
        let body = """
        About: \(person)

        RECEIVED
        \(received.trimmingCharacters(in: .whitespacesAndNewlines))

        GIVEN
        \(given.trimmingCharacters(in: .whitespacesAndNewlines))

        TROUBLES CAUSED
        \(troubles.trimmingCharacters(in: .whitespacesAndNewlines))
        """
        modelContext.insert(PromptResponse(promptID: Self.promptID, response: body))
        try? modelContext.save()
    }

    private func reset() {
        step = 0
        person = ""; received = ""; given = ""; troubles = ""
    }

    private func formatted(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"
        return f.string(from: d).uppercased()
    }
}
