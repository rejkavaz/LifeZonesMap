import SwiftUI

struct ZoneConnectionsView: View {
    let correlationStrength: (ZoneID, ZoneID) -> Double

    private let zones = ZoneID.allCases
    private let threshold: Double = 0.4

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Zone connections")
                    .font(.headline)
                Text("Line weight shows correlation strength")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) * 0.38

                // Draw edges
                for i in 0..<zones.count {
                    for j in (i+1)..<zones.count {
                        let strength = correlationStrength(zones[i], zones[j])
                        guard strength >= threshold else { continue }

                        let ptA = nodePoint(index: i, center: center, radius: radius)
                        let ptB = nodePoint(index: j, center: center, radius: radius)
                        var path = Path()
                        path.move(to: ptA)
                        path.addLine(to: ptB)
                        let def = ZoneRegistry.definition(for: zones[i])
                        ctx.stroke(
                            path,
                            with: .color(def.color.opacity(0.3 + strength * 0.4)),
                            style: StrokeStyle(lineWidth: CGFloat(0.5 + strength * 4))
                        )
                    }
                }

                // Draw nodes
                for (i, zone) in zones.enumerated() {
                    let pt   = nodePoint(index: i, center: center, radius: radius)
                    let def  = ZoneRegistry.definition(for: zone)
                    let rect = CGRect(x: pt.x - 10, y: pt.y - 10, width: 20, height: 20)
                    ctx.fill(Path(ellipseIn: rect), with: .color(def.color))
                }
            }
            .frame(height: 220)
            .accessibilityLabel("Zone correlation web")

            // Node labels overlay
            GeometryReader { geo in
                let size   = geo.size
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) * 0.38

                ForEach(Array(zones.enumerated()), id: \.element) { i, zone in
                    let pt  = nodePoint(index: i, center: center, radius: radius)
                    let def = ZoneRegistry.definition(for: zone)
                    Text(def.name)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(def.color)
                        .position(labelPosition(index: i, center: center, radius: radius))
                }
            }
            .frame(height: 40)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
    }

    private func angle(for index: Int) -> Double {
        let step = (2 * Double.pi) / Double(zones.count)
        return -Double.pi / 2 + step * Double(index)
    }

    private func nodePoint(index: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let a = angle(for: index)
        return CGPoint(x: center.x + radius * cos(a), y: center.y + radius * sin(a))
    }

    private func labelPosition(index: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let a = angle(for: index)
        let offset = radius + 20
        return CGPoint(x: center.x + offset * cos(a), y: center.y + offset * sin(a))
    }
}
