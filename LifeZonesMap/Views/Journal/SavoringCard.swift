import SwiftUI
import SwiftData

/// Surfaces a randomly-picked past 'Three Good Things' entry from
/// 30+ days ago. Based on savoring research (Bryant & Veroff, 2007;
/// Quoidbach, Berry, Hansenne & Mikolajczak, 2010): actively dwelling on
/// past positive events amplifies their wellbeing effect — the act of
/// revisiting matters as much as the original experience.
///
/// Selection is stable within the calendar week so the user isn't shown
/// a different memory every time they open the Journal tab.
struct SavoringCard: View {
    @Query(sort: \GoodThing.weekStartDate, order: .reverse) private var allThings: [GoodThing]

    private var resurfaced: GoodThing? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date.distantPast
        let eligible = allThings.filter { $0.weekStartDate < cutoff }
        guard !eligible.isEmpty else { return nil }
        let seed = abs(Date().isoWeekMonday.hashValue)
        return eligible[seed % eligible.count]
    }

    var body: some View {
        if let thing = resurfaced {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("WORTH SAVORING")
                        .uppercaseCaption(color: LZ.zGrowth, size: 9.5, tracking: 1.8)
                    Spacer()
                    Text(daysAgoLabel(thing.weekStartDate))
                        .uppercaseCaption(color: LZ.inkMute, size: 9.5, tracking: 1.6)
                }
                HStack(alignment: .top, spacing: 10) {
                    Rectangle().fill(LZ.zGrowth.opacity(0.5)).frame(width: 2)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(thing.text)
                            .font(.system(size: 15, weight: .medium))
                            .lineSpacing(2)
                            .foregroundStyle(LZ.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if !thing.why.isEmpty {
                            Text(thing.why)
                                .font(LZType.serifItalic(13))
                                .lineSpacing(1.5)
                                .foregroundStyle(LZ.inkSoft)
                        }
                    }
                }
                Text("Sit with it for a moment.")
                    .font(LZType.serifItalic(11.5))
                    .foregroundStyle(LZ.inkMute)
                    .padding(.top, 2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LZ.zGrowth.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(LZ.zGrowth.opacity(0.3), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func daysAgoLabel(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        switch days {
        case ..<60:   return "FROM \(days) DAYS AGO"
        case ..<365:  return "FROM \(days / 30) MONTHS AGO"
        default:      return "FROM \(days / 365) YEAR\(days / 365 == 1 ? "" : "S") AGO"
        }
    }
}
