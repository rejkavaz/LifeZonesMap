import SwiftUI

/// Hub for the evidence-based exercises that don't fit the regular prompt
/// library — multi-step guided flows from positive psychology and clinical
/// research. Reachable from a single Journal callout.
struct PracticesHubView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                practiceList
                researchFooter
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(LZ.paper.ignoresSafeArea())
        .navigationTitle("Practices")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Evidence-based exercises").uppercaseCaption()
            Text("Short practices, real research.")
                .font(.system(size: 24, weight: .medium))
                .tracking(-0.5)
                .foregroundStyle(LZ.ink)
            Text("Each of these has measurable effects on wellbeing in controlled studies. Try one. Not all at once.")
                .font(LZType.serifItalic(13.5))
                .lineSpacing(2)
                .foregroundStyle(LZ.inkSoft)
        }
        .padding(.horizontal, 6)
    }

    private var practiceList: some View {
        VStack(spacing: 10) {
            NavigationLink {
                ThreeGoodThingsView()
            } label: {
                practiceRow(
                    glyph: .leaf,
                    accent: LZ.zGrowth,
                    title: "Three good things",
                    cadence: "Weekly · 5 minutes",
                    summary: "Three positive events from the week — and why they happened.",
                    citation: "Seligman et al., 2005"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                BestPossibleSelfView()
            } label: {
                practiceRow(
                    glyph: .moon,
                    accent: LZ.zInner,
                    title: "Best possible self",
                    cadence: "Weekly · 15 minutes",
                    summary: "Visualize your best plausible future self, 5 years out.",
                    citation: "King 2001; Lyubomirsky 2006"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                GratitudeLetterView()
            } label: {
                practiceRow(
                    glyph: .people,
                    accent: LZ.zConnect,
                    title: "Gratitude letter",
                    cadence: "One-time · 10–20 minutes",
                    summary: "Write to someone who positively impacted you. Optionally deliver.",
                    citation: "Seligman, Steen, Park & Peterson, 2005"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                LovingKindnessView()
            } label: {
                practiceRow(
                    glyph: .spark,
                    accent: LZ.zCreate,
                    title: "Loving-kindness meditation",
                    cadence: "Daily · 5 minutes",
                    summary: "Five-step practice of offering warmth — to self, others, all beings.",
                    citation: "Fredrickson et al., 2008"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                SelfCompassionBreakView()
            } label: {
                practiceRow(
                    glyph: .moon,
                    accent: LZ.zVitality,
                    title: "Self-compassion break",
                    cadence: "As needed · 2–3 minutes",
                    summary: "Three steps to meet a hard moment with kindness.",
                    citation: "Neff, 2003 / 2011"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func practiceRow(
        glyph: ZoneGlyphID,
        accent: Color,
        title: String,
        cadence: String,
        summary: String,
        citation: String
    ) -> some View {
        HStack(spacing: 14) {
            ZoneGlyph(glyph: glyph, size: 22, stroke: 1.6)
                .foregroundStyle(accent)
                .padding(12)
                .background(accent.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(LZ.ink)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LZ.inkMute)
                }
                Text(cadence)
                    .uppercaseCaption(color: accent, size: 9.5, tracking: 1.6)
                Text(summary)
                    .font(LZType.serifItalic(13))
                    .lineSpacing(1.5)
                    .foregroundStyle(LZ.inkSoft)
                    .multilineTextAlignment(.leading)
                Text(citation)
                    .font(.system(size: 10).italic())
                    .foregroundStyle(LZ.inkMute)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var researchFooter: some View {
        Text("Each practice cites the original research in its own footer. The pattern engine doesn't substitute for any of these — it just makes the case for which to try when.")
            .font(LZType.serifItalic(11.5))
            .lineSpacing(2)
            .foregroundStyle(LZ.inkMute)
            .padding(.top, 12)
    }
}
