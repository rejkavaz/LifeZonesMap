import SwiftUI
import SwiftData

/// Small-multiples grid: every check-in as a tiny radar so you can see
/// the "shape of your year" at a glance. Reachable from Pulse → "Year shape".
struct YearOverviewView: View {
    @Query(sort: \WeeklyCheckIn.weekStartDate, order: .reverse) private var checkIns: [WeeklyCheckIn]
    @State private var selected: WeeklyCheckIn?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    private var grouped: [(String, [WeeklyCheckIn])] {
        let cal = Calendar.current
        let df = DateFormatter(); df.dateFormat = "MMMM yyyy"
        var buckets: [String: [WeeklyCheckIn]] = [:]
        for c in checkIns {
            let month = df.string(from: c.weekStartDate)
            buckets[month, default: []].append(c)
        }
        // Sort by underlying date descending
        return buckets
            .sorted {
                let a = $0.value.first?.weekStartDate ?? .distantPast
                let b = $1.value.first?.weekStartDate ?? .distantPast
                return a > b
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                if checkIns.isEmpty {
                    emptyState
                } else {
                    ForEach(grouped, id: \.0) { (month, items) in
                        monthSection(month: month, items: items)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(LZ.paper.ignoresSafeArea())
        .navigationTitle("Year shape")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selected) { c in
            HistoryDetailView(checkIn: c)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(checkIns.count) week\(checkIns.count == 1 ? "" : "s") mapped").uppercaseCaption()
            Text("Every week, side by side.")
                .font(.system(size: 22, weight: .medium))
                .tracking(-0.45)
                .foregroundStyle(LZ.ink)
            Text("Tap a tile to revisit that week.")
                .font(LZType.serifItalic(13))
                .foregroundStyle(LZ.inkSoft)
        }
        .padding(.top, 8)
    }

    private func monthSection(month: String, items: [WeeklyCheckIn]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(month.uppercased()).uppercaseCaption()
                Rectangle().fill(LZ.ruleSoft).frame(height: 0.5)
            }
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(items) { c in
                    Button { selected = c } label: {
                        tile(for: c)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func tile(for c: WeeklyCheckIn) -> some View {
        VStack(spacing: 4) {
            RadarMap(
                scores: Dictionary(uniqueKeysWithValues: ZoneID.allCases.map { ($0, c.score(for: $0)) }),
                size: 64,
                showNodes: false,
                showLabels: false,
                showGrid: false,
                fill: LZ.teal,
                fillOpacity: 0.20,
                stroke: LZ.tealDeep,
                dotRadius: 1,
                animateReveal: false
            )
            Text(dayLabel(c.weekStartDate))
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(LZ.inkMute)
            Text(String(format: "%.1f", c.overallAverage))
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundStyle(LZ.ink)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(LZ.cream)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func dayLabel(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: d)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            ZoneGlyph(glyph: .moon, size: 36, stroke: 1.5)
                .foregroundStyle(LZ.inkMute.opacity(0.5))
            Text("Check in a few weeks to see your year take shape.")
                .font(LZType.serifItalic(14))
                .foregroundStyle(LZ.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}
