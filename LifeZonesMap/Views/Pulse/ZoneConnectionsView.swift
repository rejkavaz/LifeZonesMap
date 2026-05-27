import SwiftUI

/// Circular zone connection web. Line thickness encodes correlation strength.
struct ZoneConnectionsView: View {
    let correlationStrength: (ZoneID, ZoneID) -> Double

    private let threshold: Double = 0.4
    private let zones = ZoneID.allCases

    var body: some View {
        VStack(spacing: 0) {
            Canvas { ctx, size in
                let cx = size.width / 2
                let cy = size.height / 2
                let R = min(size.width, size.height) * 0.36

                // Faint dashed ring
                let ring = Path(ellipseIn: CGRect(x: cx - R, y: cy - R, width: R * 2, height: R * 2))
                ctx.stroke(ring, with: .color(LZ.rule), style: StrokeStyle(lineWidth: 0.6, dash: [2, 4]))

                // Positions
                let n = zones.count
                var pts: [CGPoint] = []
                for i in 0..<n {
                    let a = -CGFloat.pi / 2 + (CGFloat(i) / CGFloat(n)) * .pi * 2
                    pts.append(CGPoint(x: cx + cos(a) * R, y: cy + sin(a) * R))
                }

                // Edges
                for i in 0..<n {
                    for j in (i + 1)..<n {
                        let w = correlationStrength(zones[i], zones[j])
                        guard w >= threshold else { continue }
                        var p = Path()
                        p.move(to: pts[i])
                        p.addLine(to: pts[j])
                        ctx.stroke(
                            p,
                            with: .color(LZ.inkSoft.opacity(0.18 + w * 0.5)),
                            style: StrokeStyle(lineWidth: 0.6 + CGFloat(w) * 2.2, lineCap: .round)
                        )
                    }
                }

                // Nodes
                for (i, zone) in zones.enumerated() {
                    let def = ZoneRegistry.definition(for: zone)
                    let pt = pts[i]
                    let outerR: CGFloat = 9
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: pt.x - outerR, y: pt.y - outerR, width: outerR * 2, height: outerR * 2)),
                        with: .color(LZ.paper)
                    )
                    ctx.stroke(
                        Path(ellipseIn: CGRect(x: pt.x - outerR, y: pt.y - outerR, width: outerR * 2, height: outerR * 2)),
                        with: .color(def.color), lineWidth: 1.4
                    )
                    let innerR: CGFloat = 4
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: pt.x - innerR, y: pt.y - innerR, width: innerR * 2, height: innerR * 2)),
                        with: .color(def.color)
                    )
                }
            }
            .frame(height: 280)
            .overlay(labelsOverlay)

            Text("Thicker lines mean a stronger pull between two zones over the last twelve weeks.")
                .font(LZType.serifItalic(11.5))
                .foregroundStyle(LZ.inkSoft)
                .lineSpacing(2)
                .padding(.horizontal, 8)
                .padding(.bottom, 14)
                .padding(.top, 6)
        }
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LZ.paper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
    }

    // Place labels in SwiftUI (easier than Canvas text)
    @ViewBuilder private var labelsOverlay: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            let R = min(geo.size.width, geo.size.height) * 0.36
            ForEach(Array(zones.enumerated()), id: \.element) { i, zone in
                let a = -CGFloat.pi / 2 + (CGFloat(i) / CGFloat(zones.count)) * .pi * 2
                let isRight = cos(a) > 0.2
                let isLeft  = cos(a) < -0.2
                let dx: CGFloat = isRight ? 14 : (isLeft ? -14 : 0)
                let dy: CGFloat = sin(a) > 0.2 ? 18 : (sin(a) < -0.2 ? -10 : 4)
                Text(ZoneRegistry.definition(for: zone).name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(LZ.ink)
                    .frame(width: 72, alignment: isRight ? .leading : (isLeft ? .trailing : .center))
                    .position(x: cx + cos(a) * R + dx, y: cy + sin(a) * R + dy)
            }
        }
    }
}
