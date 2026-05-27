import SwiftUI

/// Topographic isolines drawn with deterministic noise.
/// Same seed → same lines, so the texture is stable across renders.
/// Mirrors design/life-zones/project/shared.jsx → TopoTexture
struct TopoTexture: View {
    var lines: Int = 28
    var palette: [Color] = [Color(hex: "#C9BDA0"), Color(hex: "#B8AB89")]
    var seed: Int = 1
    var opacity: Double = 0.7
    var lineWidth: CGFloat = 1.0

    var body: some View {
        Canvas { ctx, size in
            let rng = SeededRNG(seed: seed)
            let cx = size.width  * (0.3 + rng.next() * 0.4)
            let cy = size.height * (0.4 + rng.next() * 0.2)

            for i in 0..<lines {
                let rx = (CGFloat(i) + 4) * (size.width / (CGFloat(lines) * 0.8))
                         * (0.6 + CGFloat(rng.next()) * 0.3)
                let ry = rx * (0.55 + CGFloat(rng.next()) * 0.25)
                let rot = (rng.next() - 0.5) * 30
                let wob = 6 + CGFloat(rng.next()) * 12

                var path = Path()
                let segments = 60
                for k in 0...segments {
                    let t = (Double(k) / Double(segments)) * .pi * 2
                    let r1 = rx + sin(t * 3 + rng.next() * 2) * wob
                    let r2 = ry + cos(t * 2 + rng.next() * 2) * wob
                    let x = cx + cos(t) * r1
                    let y = cy + sin(t) * r2
                    let pt = CGPoint(x: x, y: y)
                    if k == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                }
                path.closeSubpath()

                // Rotate around (cx, cy) — apply transform
                let xform = CGAffineTransform.identity
                    .translatedBy(x: cx, y: cy)
                    .rotated(by: rot * .pi / 180)
                    .translatedBy(x: -cx, y: -cy)
                let rotated = path.applying(xform)

                let color = palette[i % palette.count]
                ctx.stroke(
                    rotated,
                    with: .color(color.opacity(opacity)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }
}

/// Deterministic pseudo-random generator matching the JS impl.
final class SeededRNG {
    private var s: Double
    init(seed: Int) { self.s = Double(seed) * 9301 + 49297 }
    func next() -> CGFloat {
        s = (s * 9301 + 49297).truncatingRemainder(dividingBy: 233280)
        return CGFloat(s / 233280)
    }
}

// MARK: - Topo palettes used in design

enum TopoPalette {
    static let sageCoast    = [Color(hex: "#A9B59A"), Color(hex: "#8DA383")]
    static let clayValley   = [Color(hex: "#C19A6F"), Color(hex: "#A8754F")]
    static let twilightRidge = [Color(hex: "#7D8FA3"), Color(hex: "#536376")]
    static let mapHint      = [Color(hex: "#B6A88B")]
}
