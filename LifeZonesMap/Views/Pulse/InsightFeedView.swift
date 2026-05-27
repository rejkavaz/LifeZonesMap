import SwiftUI

struct InsightFeedView: View {
    let insights: [ZoneInsight]
    var onDismiss: (ZoneInsight) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 10) {
            if insights.isEmpty {
                emptyState
            } else {
                ForEach(insights.filter { !$0.dismissed }, id: \.id) { insight in
                    InsightCard(insight: insight, onDismiss: { onDismiss(insight) })
                        .padding(.horizontal, 18)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("Patterns will surface after a few weeks.")
                .font(LZType.serifItalic(13))
                .foregroundStyle(LZ.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 18)
    }
}

struct InsightCard: View {
    let insight: ZoneInsight
    var onDismiss: () -> Void

    private struct Palette {
        let accent: Color
        let label: String
    }

    private var palette: Palette {
        switch insight.type {
        case .warning:     return Palette(accent: Color(hex: "#C19036"), label: "Watch")
        case .positive:    return Palette(accent: LZ.zGrowth,           label: "Lift")
        case .correlation: return Palette(accent: LZ.zDeepWork,         label: "Pattern")
        case .trend:       return Palette(accent: LZ.zInner,            label: "Trend")
        }
    }

    private var glyph: ZoneGlyphID {
        guard let first = insight.zoneIDs.first,
              let id = ZoneID(rawValue: first) else { return .focus }
        return ZoneRegistry.definition(for: id).glyph
    }

    private var zoneName: String? {
        guard insight.zoneIDs.count == 1,
              let id = ZoneID(rawValue: insight.zoneIDs[0]) else { return nil }
        return ZoneRegistry.definition(for: id).name
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                bottomLeadingRadius: 12,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
            .fill(palette.accent)
            .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    Text(palette.label + (zoneName.map { " · \($0)" } ?? ""))
                        .font(.system(size: 9, weight: .bold))
                        .tracking(2.0)
                        .textCase(.uppercase)
                        .foregroundStyle(palette.accent)
                    Spacer()
                    ZoneGlyph(glyph: glyph, size: 16, stroke: 1.7)
                        .foregroundStyle(palette.accent.opacity(0.7))
                    Button(action: { withAnimation(DS.Anim.sheet) { onDismiss() } }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(LZ.inkMute)
                    }
                    .padding(.leading, 4)
                }
                Text(insight.body)
                    .font(.system(size: 13.5))
                    .lineSpacing(2)
                    .tracking(-0.07)
                    .foregroundStyle(LZ.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 18)
            .padding(.trailing, 13)
            .padding(.vertical, 11)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
