import SwiftUI
import SwiftData

/// Behavioral Activation — Lewinsohn (1974), Jacobson, Martell & Dimidjian
/// (2001). The single most-replicated behavioral intervention for depression:
/// schedule and complete small pleasurable or mastery activities, regardless
/// of mood. Acting first, feeling-better-second.
///
/// Cadence: weekly. Pick ONE small activity (10-30 min), commit, then mark
/// it done — or honestly mark it didn't happen. Both teach.
struct BehavioralActivationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PromptResponse.createdAt, order: .reverse) private var allResponses: [PromptResponse]

    @State private var category: ActivityCategory = .pleasure
    @State private var activity: String = ""
    @State private var when: String = ""        // optional plan (e.g. "Tuesday after dinner")

    private static let basePromptID = "behavioral-activation"

    enum ActivityCategory: String, CaseIterable {
        case pleasure   // enjoyable, sense-driven
        case mastery    // produces a sense of competence/accomplishment
        case connection // tightens a bond
        var label: String {
            switch self {
            case .pleasure:   return "Pleasure"
            case .mastery:    return "Mastery"
            case .connection: return "Connection"
            }
        }
        var hint: String {
            switch self {
            case .pleasure:   return "A 30-minute walk. Cooking something good. A long bath. Calling someone."
            case .mastery:    return "Finishing the small admin task that's been hanging. Practicing an instrument for 15 minutes."
            case .connection: return "Texting a friend you've been quiet with. Sitting with family without your phone."
            }
        }
        var color: Color {
            switch self {
            case .pleasure:   return LZ.zCreate
            case .mastery:    return LZ.zDeepWork
            case .connection: return LZ.zConnect
            }
        }
    }

    private var pastPlans: [PromptResponse] {
        allResponses.filter { $0.promptID.hasPrefix(Self.basePromptID) }
    }

    private var thisWeekStart: Date { Date().isoWeekMonday }

    private var thisWeeksPlan: PromptResponse? {
        pastPlans.first { Calendar.current.isDate($0.createdAt.isoWeekMonday,
                                                  inSameDayAs: thisWeekStart) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if let plan = thisWeeksPlan {
                    activePlanCard(plan: plan)
                } else {
                    categoryPicker
                    activityField
                    whenField
                    saveButton
                }
                if pastPlans.count > (thisWeeksPlan == nil ? 0 : 1) {
                    pastPlansSection
                }
                researchFooter
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(LZ.paper.ignoresSafeArea())
        .navigationTitle("Plan one small thing")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Weekly · 1 minute to commit").uppercaseCaption(color: LZ.zDeepWork)
            Text(thisWeeksPlan == nil ? "Pick one small thing for the week." : "This week's plan.")
                .font(.system(size: 22, weight: .medium))
                .tracking(-0.45)
                .foregroundStyle(LZ.ink)
            Text("Action first, feelings later. The point is to do it, not to do it well.")
                .font(LZType.serifItalic(13))
                .lineSpacing(2)
                .foregroundStyle(LZ.inkSoft)
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CATEGORY").uppercaseCaption()
            HStack(spacing: 6) {
                ForEach(ActivityCategory.allCases, id: \.self) { cat in
                    Button { category = cat } label: {
                        Text(cat.label)
                            .font(.system(size: 12, weight: category == cat ? .semibold : .medium))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(category == cat ? cat.color.opacity(0.15) : .clear))
                            .overlay(Capsule().strokeBorder(category == cat ? cat.color : LZ.rule, lineWidth: 0.5))
                            .foregroundStyle(category == cat ? cat.color : LZ.inkSoft)
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(category.hint)
                .font(LZType.serifItalic(12.5))
                .foregroundStyle(LZ.inkSoft)
                .padding(.top, 4)
        }
    }

    private var activityField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("THE ACTIVITY").uppercaseCaption()
            TextField("What's the one small thing?", text: $activity, axis: .vertical)
                .font(.system(size: 16, weight: .medium))
                .lineLimit(2...3)
                .padding(12)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var whenField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WHEN · OPTIONAL BUT HELPFUL").uppercaseCaption()
            TextField("e.g. Tuesday after dinner", text: $when)
                .font(LZType.serifItalic(14))
                .padding(12)
                .background(LZ.cream)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text("Implementation intentions (Gollwitzer): naming WHEN you'll do it produces 2-3× better follow-through.")
                .font(LZType.serifItalic(11))
                .foregroundStyle(LZ.inkMute)
                .padding(.top, 2)
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Text("Commit")
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(activity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? LZ.rule : category.color)
                .foregroundStyle(LZ.cream)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(activity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    @ViewBuilder
    private func activePlanCard(plan: PromptResponse) -> some View {
        let parsed = parse(plan.response)
        let color: Color = parsed.category?.color ?? LZ.tealDeep

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text((parsed.category?.label ?? "Plan").uppercased())
                    .uppercaseCaption(color: color)
                Spacer()
                Text("CHANGE STATE")
                    .uppercaseCaption(color: LZ.inkMute, size: 9, tracking: 1.6)
            }
            Text(parsed.activity)
                .font(.system(size: 18, weight: .medium))
                .lineSpacing(2)
                .foregroundStyle(LZ.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let when = parsed.when, !when.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                    Text(when)
                        .font(LZType.serifItalic(13.5))
                }
                .foregroundStyle(LZ.inkSoft)
            }

            HStack(spacing: 10) {
                Button { update(plan: plan, status: .done) } label: {
                    Label("Did it", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(parsed.status == .done ? color.opacity(0.2) : color)
                        .foregroundStyle(parsed.status == .done ? color : LZ.cream)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                Button { update(plan: plan, status: .skipped) } label: {
                    Label("Didn't happen", systemImage: "minus.circle")
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(parsed.status == .skipped ? LZ.zVitality : LZ.inkSoft)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(
                                    parsed.status == .skipped ? LZ.zVitality : LZ.rule,
                                    lineWidth: 0.5
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            Text("Both teach something. Honesty beats performance.")
                .font(LZType.serifItalic(11.5))
                .foregroundStyle(LZ.inkMute)

            Button {
                modelContext.delete(plan)
                try? modelContext.save()
            } label: {
                Text("Replace this plan")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LZ.inkMute)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(color.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(color.opacity(0.35), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var pastPlansSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { SectionTitle(text: "Past plans") }
                .padding(.horizontal, 6)
            ForEach(pastPlans.filter { $0.id != thisWeeksPlan?.id }) { plan in
                let parsed = parse(plan.response)
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: parsed.status == .done ? "checkmark.circle.fill"
                                    : parsed.status == .skipped ? "minus.circle"
                                    : "questionmark.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(parsed.status == .done ? LZ.zGrowth
                                       : parsed.status == .skipped ? LZ.inkMute
                                       : LZ.inkMute)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(parsed.activity)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(LZ.ink)
                        Text(dateLabel(plan.createdAt))
                            .uppercaseCaption(color: LZ.inkMute, size: 9, tracking: 1.5)
                    }
                    Spacer()
                }
                .padding(12)
                .background(LZ.cream)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private var researchFooter: some View {
        Text("Lewinsohn (1974); Jacobson, Martell & Dimidjian (2001); Dimidjian et al. (2006). Behavioral activation is one of the most-replicated treatments for depression — schedule small pleasurable or mastery activities regardless of mood, and the mood follows.")
            .font(LZType.serifItalic(11.5))
            .lineSpacing(2)
            .foregroundStyle(LZ.inkMute)
            .padding(.top, 12)
    }

    // MARK: - Serialization

    private struct ParsedPlan {
        let category: ActivityCategory?
        let activity: String
        let when: String?
        let status: Status
        enum Status { case pending, done, skipped }
    }

    private func encode(category: ActivityCategory, activity: String, when: String, status: ParsedPlan.Status) -> String {
        let statusStr = status == .done ? "DONE" : (status == .skipped ? "SKIPPED" : "PENDING")
        return [
            "category=\(category.rawValue)",
            "status=\(statusStr)",
            "activity=\(activity)",
            "when=\(when)"
        ].joined(separator: "\n")
    }

    private func parse(_ raw: String) -> ParsedPlan {
        var dict: [String: String] = [:]
        for line in raw.components(separatedBy: "\n") {
            if let eq = line.firstIndex(of: "=") {
                let key = String(line[..<eq])
                let val = String(line[line.index(after: eq)...])
                dict[key] = val
            }
        }
        let cat = dict["category"].flatMap { ActivityCategory(rawValue: $0) }
        let status: ParsedPlan.Status = {
            switch dict["status"] {
            case "DONE":    return .done
            case "SKIPPED": return .skipped
            default:        return .pending
            }
        }()
        return ParsedPlan(
            category: cat,
            activity: dict["activity"] ?? raw,
            when: dict["when"],
            status: status
        )
    }

    // MARK: - Actions

    private func save() {
        let trimmed = activity.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let body = encode(
            category: category, activity: trimmed,
            when: when.trimmingCharacters(in: .whitespacesAndNewlines),
            status: .pending
        )
        modelContext.insert(PromptResponse(promptID: Self.basePromptID, response: body))
        try? modelContext.save()
        activity = ""
        when = ""
    }

    private func update(plan: PromptResponse, status: ParsedPlan.Status) {
        let parsed = parse(plan.response)
        let newBody = encode(
            category: parsed.category ?? .pleasure,
            activity: parsed.activity,
            when: parsed.when ?? "",
            status: status
        )
        plan.response = newBody
        try? modelContext.save()
    }

    private func dateLabel(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: d).uppercased()
    }
}

private extension Date {
    /// Reuse the existing isoWeekMonday calculation by name for consistency.
    var isoWeekStart: Date { self.isoWeekMonday }
}
