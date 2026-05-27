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
            (c.weekStartDate, c.score(for: zone))
        }.reversed()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header tile
                    HStack(spacing: 12) {
                        ZoneGlyph(glyph: def.glyph, size: 22, stroke: 1.7)
                            .foregroundStyle(def.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(def.name)
                                .font(.system(size: 22, weight: .medium))
                                .tracking(-0.44)
                                .foregroundStyle(LZ.ink)
                            Text(def.blurb)
                                .font(LZType.serifItalic(13))
                                .foregroundStyle(LZ.inkSoft)
                        }
                        Spacer()
                        if let latest = checkIns.first {
                            Text("\(latest.score(for: zone))")
                                .font(.system(size: 40, weight: .light).monospacedDigit())
                                .tracking(-1)
                                .foregroundStyle(def.color)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(def.color.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    // History sparkline
                    if recentScores.count >= 2 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent weeks").uppercaseCaption()
                            ZoneHistoryView(scores: recentScores, color: def.color)
                                .frame(height: 80)
                        }
                    }

                    // Latest note
                    if let note = checkIns.first?.note(for: zone), !note.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("This week's note").uppercaseCaption()
                            Text(note)
                                .font(LZType.serifItalic(14))
                                .lineSpacing(2)
                                .foregroundStyle(LZ.inkSoft)
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

                    // Tag chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Common feelings").uppercaseCaption()
                        FlowLayout(spacing: 6) {
                            ForEach(def.exampleTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(def.color.opacity(0.12)))
                                    .overlay(Capsule().strokeBorder(def.color.opacity(0.4), lineWidth: 0.5))
                                    .foregroundStyle(def.color)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(LZ.paper.ignoresSafeArea())
            .navigationTitle(def.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(LZ.tealDeep)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
