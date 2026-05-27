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

    // MARK: - Small: Radar + avg score

    private var smallWidget: some View {
        VStack(spacing: 6) {
            if let snap = entry.snapshot {
                MiniRadarView(scores: snap.scores)
                    .frame(height: 80)
                Text(String(format: "%.1f", snap.overallAverage))
                    .font(.system(size: 22, weight: .thin))
                    .foregroundStyle(Color(hex: "#1D9E75"))
                Text("avg")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                emptyRadar
            }
        }
    }

    // MARK: - Medium: Zone bars

    private var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Life Zones")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            if let snap = entry.snapshot {
                ForEach(ZoneID.allCases) { zone in
                    let def   = ZoneRegistry.definition(for: zone)
                    let score = snap.scores[zone.rawValue] ?? 5
                    HStack(spacing: 6) {
                        Circle().fill(def.color).frame(width: 6, height: 6)
                        Text(def.name).font(.system(size: 9)).lineLimit(1).frame(width: 56, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(def.color.opacity(0.15))
                                Capsule().fill(def.color).frame(width: geo.size.width * CGFloat(score) / 10)
                            }
                        }
                        .frame(height: 5)
                        Text("\(score)").font(.system(size: 9)).frame(width: 12)
                    }
                }
            } else {
                emptyRadar
            }
        }
        .padding(8)
    }

    // MARK: - Lock screen

    private var lockScreenWidget: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let snap = entry.snapshot {
                let low = ZoneID.allCases
                    .sorted { (snap.scores[$0.rawValue] ?? 5) < (snap.scores[$1.rawValue] ?? 5) }
                    .prefix(3)

                Text("Needs care")
                    .font(.caption2).fontWeight(.semibold)

                ForEach(Array(low), id: \.self) { zone in
                    let def   = ZoneRegistry.definition(for: zone)
                    let score = snap.scores[zone.rawValue] ?? 5
                    HStack(spacing: 4) {
                        Circle().fill(def.color).frame(width: 5, height: 5)
                        Text(def.name).font(.system(size: 10))
                        Spacer()
                        Text("\(score)").font(.system(size: 10, weight: .medium))
                    }
                }
            } else {
                Text("No data yet").font(.caption2)
            }
        }
    }

    private var emptyRadar: some View {
        VStack(spacing: 4) {
            Image(systemName: "map").foregroundStyle(.quaternary)
            Text("Check in to\nupdate your map")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Mini radar for small widget

struct MiniRadarView: View {
    let scores: [String: Int]

    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let maxR   = min(size.width, size.height) * 0.44
            let zones  = ZoneID.allCases

            // Grid
            for scale in [0.33, 0.66, 1.0] as [Double] {
                var path = Path()
                for i in 0..<zones.count {
                    let a = angle(i, count: zones.count)
                    let pt = CGPoint(x: center.x + maxR * scale * cos(a), y: center.y + maxR * scale * sin(a))
                    i == 0 ? path.move(to: pt) : path.addLine(to: pt)
                }
                path.closeSubpath()
                ctx.stroke(path, with: .color(.secondary.opacity(0.2)), style: StrokeStyle(lineWidth: 0.5))
            }

            // Filled polygon
            var poly = Path()
            for (i, zone) in zones.enumerated() {
                let s  = Double(scores[zone.rawValue] ?? 5) / 10
                let a  = angle(i, count: zones.count)
                let pt = CGPoint(x: center.x + maxR * s * cos(a), y: center.y + maxR * s * sin(a))
                i == 0 ? poly.move(to: pt) : poly.addLine(to: pt)
            }
            poly.closeSubpath()
            ctx.fill(poly, with: .color(Color(hex: "#1D9E75").opacity(0.2)))
            ctx.stroke(poly, with: .color(Color(hex: "#1D9E75").opacity(0.6)), lineWidth: 1.5)
        }
    }

    private func angle(_ i: Int, count: Int) -> Double {
        -Double.pi / 2 + (2 * Double.pi / Double(count)) * Double(i)
    }
}
