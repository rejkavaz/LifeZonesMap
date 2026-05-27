import SwiftUI
import SwiftData

struct ZoneDetailSheet: View {
    let zone: ZoneID
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WeeklyCheckIn.weekStartDate, order: .reverse) private var checkIns: [WeeklyCheckIn]

    private var def: ZoneDefinition { ZoneRegistry.definition(for: zone) }

    private var recentScores: [(Date, Int)] {
        checkIns.prefix(8).compactMap { c in
            let s = c.score(for: zone)
            return (c.weekStartDate, s)
        }.reversed()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.s24) {
                    // Zone header
                    HStack(spacing: DS.Spacing.s12) {
                        Image(systemName: def.iconName)
                            .font(.title2)
                            .foregroundStyle(def.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(def.name)
                                .font(.title2).fontWeight(.semibold)
                            Text(def.tagline)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let latest = checkIns.first {
                            Text("\(latest.score(for: zone))")
                                .font(.system(size: 44, weight: .thin))
                                .foregroundStyle(def.color)
                        }
                    }
                    .padding()
                    .background(def.color.opacity(0.08), in: RoundedRectangle(cornerRadius: DS.Radius.lg))

                    // History sparkline
                    if recentScores.count >= 2 {
                        VStack(alignment: .leading, spacing: DS.Spacing.s8) {
                            Text("Recent history")
                                .font(.headline)
                            ZoneHistoryView(scores: recentScores, color: def.color)
                                .frame(height: 80)
                        }
                    }

                    // Latest note
                    if let note = checkIns.first?.note(for: zone), !note.isEmpty {
                        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                            Text("This week's note")
                                .font(.headline)
                            Text(note)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                        }
                    }

                    // Common tags row
                    VStack(alignment: .leading, spacing: DS.Spacing.s8) {
                        Text("Common feelings")
                            .font(.headline)
                        FlowLayout(spacing: DS.Spacing.s8) {
                            ForEach(def.exampleTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, DS.Spacing.s12)
                                    .padding(.vertical, DS.Spacing.s4)
                                    .background(def.color.opacity(0.15), in: Capsule())
                                    .foregroundStyle(def.color)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(def.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// Minimal flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let w = proposal.width ?? 320
        var x: CGFloat = 0, y: CGFloat = 0, maxH: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > w && x > 0 { x = 0; y += maxH + spacing; maxH = 0 }
            x += s.width + spacing
            maxH = max(maxH, s.height)
        }
        return CGSize(width: w, height: y + maxH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX, y = bounds.minY, maxH: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX && x > bounds.minX { x = bounds.minX; y += maxH + spacing; maxH = 0 }
            sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            maxH = max(maxH, s.height)
        }
    }
}
