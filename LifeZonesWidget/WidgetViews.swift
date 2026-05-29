import SwiftUI
import WidgetKit

struct LifeZonesWidgetView: View {
    let entry: LifeZonesEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:  smallWidget
        case .systemMedium: mediumWidget
        case .accessoryRectangular: lockScreenWidget
        default: smallWidget
        }
    }

    // MARK: - Small (2×2) — mini radar + avg
    private var smallWidget: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#F2EBDC"), Color(hex: "#E6E4DC")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                HStack {
                    Text("Life Zones")
                        .uppercaseCaption(color: LZ.inkMute, size: 9, tracking: 1.6)
                    Spacer()
                    IconMark(size: 14, color: LZ.tealDeep, bg: .clear, rounded: 3)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline) {
                    Text(entry.snapshot.map { String(format: "%.1f", $0.overallAverage) } ?? "—")
                        .font(.system(size: 26, weight: .medium).monospacedDigit())
                        .tracking(-0.65)
                        .foregroundStyle(LZ.ink)
                    Spacer()
                    Text("avg").uppercaseCaption(color: LZ.inkMute, size: 9, tracking: 1.8)
                }
            }
            .padding(10)

            if let snap = entry.snapshot {
                MiniRadar(scores: snap.scores)
                    .frame(width: 108, height: 108)
                    .offset(y: -8)
            }
        }
    }

    // MARK: - Medium (4×2) — seven rows
    private var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Life Zones")
                    .font(.system(size: 11.5, weight: .medium))
                    .tracking(-0.05)
                    .foregroundStyle(LZ.ink)
                Spacer()
                Text(monthDayLabel())
                    .uppercaseCaption(color: LZ.inkMute, size: 9, tracking: 1.6)
            }
            .padding(.bottom, 6)

            if let snap = entry.snapshot {
                VStack(spacing: 1) {
                    ForEach(ZoneID.allCases) { zone in
                        let def = ZoneRegistry.definition(for: zone)
                        let score = snap.scores[zone.rawValue] ?? 5
                        HStack(spacing: 8) {
                            Circle().fill(def.color).frame(width: 5, height: 5)
                            Text(def.name)
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundStyle(LZ.ink)
                                .frame(width: 60, alignment: .leading)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color(hex: "#E8DFC8")).frame(height: 3)
                                    Capsule().fill(def.color)
                                        .frame(width: geo.size.width * CGFloat(score) / 10, height: 3)
                                }
                            }
                            .frame(height: 3)
                            Text(String(format: "%.1f", Double(score)))
                                .font(.system(size: 10, weight: .medium).monospacedDigit())
                                .foregroundStyle(LZ.ink)
                                .frame(width: 22, alignment: .trailing)
                        }
                    }
                }
            } else {
                emptyHint
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(LZ.paper)
    }

    // MARK: - Lock screen rectangular
    private var lockScreenWidget: some View {
        Group {
            if let snap = entry.snapshot, isCheckInDay(snap: snap) {
                checkInDayLockView
            } else if let snap = entry.snapshot {
                needsCareLockView(snap: snap)
            } else {
                Text("Check in to see your map").font(.caption2)
            }
        }
    }

    private var checkInDayLockView: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text("Tap to check in")
                    .font(.system(size: 12, weight: .semibold))
            }
            Text("Your weekly map is waiting.")
                .font(.system(size: 10))
                .opacity(0.85)
        }
    }

    private func needsCareLockView(snap: WidgetDataProvider.Snapshot) -> some View {
        let needsCare = ZoneID.allCases
            .sorted { (snap.scores[$0.rawValue] ?? 5) < (snap.scores[$1.rawValue] ?? 5) }
            .prefix(3)
        return VStack(alignment: .leading, spacing: 2) {
            Text("Needs care")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.6)
                .textCase(.uppercase)
                .opacity(0.85)
            HStack(spacing: 8) {
                ForEach(Array(needsCare), id: \.self) { zone in
                    let def = ZoneRegistry.definition(for: zone)
                    let score = snap.scores[zone.rawValue] ?? 5
                    HStack(spacing: 4) {
                        Circle().fill(def.color).frame(width: 6, height: 6)
                        Text(def.name).font(.system(size: 11, weight: .semibold))
                        Text(String(format: "%.1f", Double(score)))
                            .font(.system(size: 11, weight: .medium).monospacedDigit())
                            .opacity(0.85)
                    }
                }
            }
        }
    }

    /// True iff today is the user's configured check-in weekday AND they
    /// haven't already done this week's check-in.
    private func isCheckInDay(snap: WidgetDataProvider.Snapshot) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: entry.date)
        let mondayOfThisWeek = entry.date.isoWeekMonday
        let alreadyChecked = Calendar.current.isDate(snap.weekStart, inSameDayAs: mondayOfThisWeek)
        return weekday == snap.checkInWeekday && !alreadyChecked
    }

    private var emptyHint: some View {
        VStack(spacing: 4) {
            Spacer()
            Image(systemName: "map").foregroundStyle(LZ.inkMute.opacity(0.45))
            Text("Check in to update your map")
                .font(.system(size: 10))
                .foregroundStyle(LZ.inkMute)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func monthDayLabel() -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: entry.date).uppercased()
    }
}

// MARK: - Mini radar for small widget — matches MapView visual

struct MiniRadar: View {
    let scores: [String: Int]

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let R = min(size.width, size.height) * 0.44
            let zones = ZoneID.allCases
            let n = zones.count

            // Faint grid rings
            for scale in [0.33, 0.66, 1.0] as [Double] {
                var path = Path()
                for k in 0..<n {
                    let a = -CGFloat.pi / 2 + (CGFloat(k) / CGFloat(n)) * .pi * 2
                    let pt = CGPoint(x: cx + R * CGFloat(scale) * cos(a),
                                     y: cy + R * CGFloat(scale) * sin(a))
                    if k == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                }
                path.closeSubpath()
                ctx.stroke(path, with: .color(Color(hex: "#C2B79C").opacity(0.55)),
                           style: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
            }

            // Filled polygon
            var poly = Path()
            for (i, zone) in zones.enumerated() {
                let s = CGFloat(scores[zone.rawValue] ?? 5) / 10
                let a = -CGFloat.pi / 2 + (CGFloat(i) / CGFloat(n)) * .pi * 2
                let pt = CGPoint(x: cx + R * s * cos(a), y: cy + R * s * sin(a))
                if i == 0 { poly.move(to: pt) } else { poly.addLine(to: pt) }
            }
            poly.closeSubpath()
            ctx.fill(poly, with: .color(LZ.teal.opacity(0.20)))
            ctx.stroke(poly, with: .color(LZ.tealDeep), lineWidth: 1.4)

            // Nodes
            for (i, zone) in zones.enumerated() {
                let def = ZoneRegistry.definition(for: zone)
                let s = CGFloat(scores[zone.rawValue] ?? 5) / 10
                let a = -CGFloat.pi / 2 + (CGFloat(i) / CGFloat(n)) * .pi * 2
                let pt = CGPoint(x: cx + R * s * cos(a), y: cy + R * s * sin(a))
                ctx.fill(
                    Path(ellipseIn: CGRect(x: pt.x - 3, y: pt.y - 3, width: 6, height: 6)),
                    with: .color(def.color)
                )
            }
        }
    }
}
