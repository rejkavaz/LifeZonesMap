import SwiftUI

/// Quiet, non-celebratory ribbon that appears once the user crosses a
/// milestone (10 weeks, 6 months, 1 year, …). Never enforces anything —
/// just a small acknowledgment.
struct MilestoneRibbon: View {
    let checkInCount: Int

    private struct Milestone {
        let threshold: Int       // weeks
        let title: String
        let subtitle: String
    }

    private static let milestones: [Milestone] = [
        .init(threshold: 4,  title: "First month, mapped.",            subtitle: "Four weeks of paying attention."),
        .init(threshold: 10, title: "Ten weeks in.",                    subtitle: "Patterns are starting to show."),
        .init(threshold: 26, title: "Half a year of weekly check-ins.", subtitle: "A real picture, not a guess."),
        .init(threshold: 52, title: "A full year, week by week.",       subtitle: "What you've kept track of, no one else can give back to you."),
        .init(threshold: 78, title: "Eighteen months of this.",         subtitle: "Quiet consistency."),
        .init(threshold: 104, title: "Two years on the map.",           subtitle: "Some of the longest threads are just starting to read.")
    ]

    /// Highest milestone the user has crossed.
    private var current: Milestone? {
        Self.milestones.last { checkInCount >= $0.threshold }
    }

    var body: some View {
        if let m = current {
            HStack(alignment: .top, spacing: 12) {
                ZoneGlyph(glyph: .leaf, size: 18, stroke: 1.6)
                    .foregroundStyle(LZ.tealDeep)
                    .padding(8)
                    .background(LZ.tealDeep.opacity(0.10))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(m.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(LZ.ink)
                    Text(m.subtitle)
                        .font(LZType.serifItalic(12.5))
                        .lineSpacing(1.5)
                        .foregroundStyle(LZ.inkSoft)
                }
                Spacer()
                Text("\(checkInCount) wks")
                    .uppercaseCaption(color: LZ.tealDeep, size: 9.5, tracking: 1.6)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(LZ.tealDeep.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(LZ.tealDeep.opacity(0.3), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
