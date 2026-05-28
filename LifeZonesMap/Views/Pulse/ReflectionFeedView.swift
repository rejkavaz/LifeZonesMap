import SwiftUI
import SwiftData

/// Quote-styled list of the user's recent WeeklyReflection entries.
/// Shown on the Pulse page between insights and the connection web.
struct ReflectionFeedView: View {
    @Query(sort: \WeeklyReflection.weekStartDate, order: .reverse) private var reflections: [WeeklyReflection]
    var limit: Int = 4

    private var visible: [WeeklyReflection] {
        Array(reflections.prefix(limit))
    }

    var body: some View {
        if !visible.isEmpty {
            VStack(spacing: 10) {
                ForEach(visible) { r in
                    ReflectionCard(reflection: r)
                        .padding(.horizontal, 18)
                }
            }
        }
    }
}

struct ReflectionCard: View {
    let reflection: WeeklyReflection

    private var weekLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return "WEEK OF \(f.string(from: reflection.weekStartDate))".uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(weekLabel)
                    .uppercaseCaption(color: LZ.inkMute, size: 9.5, tracking: 1.8)
                Spacer()
                ZoneGlyph(glyph: .pen, size: 13, stroke: 1.7)
                    .foregroundStyle(LZ.inkMute)
            }

            // Prompt as eyebrow
            Text(reflection.prompt)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(LZ.inkSoft)
                .lineSpacing(1.5)

            // Response in serif italic — the "field guide" voice
            HStack(alignment: .top, spacing: 8) {
                Rectangle()
                    .fill(LZ.tealDeep.opacity(0.5))
                    .frame(width: 2)
                Text(reflection.response)
                    .font(LZType.serifItalic(14.5))
                    .lineSpacing(3)
                    .foregroundStyle(LZ.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(LZ.paper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
    }
}
