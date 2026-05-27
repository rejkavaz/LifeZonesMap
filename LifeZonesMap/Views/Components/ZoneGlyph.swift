import SwiftUI

/// Custom 24×24 SVG-style line glyphs, drawn as `Shape` for full control.
/// Based on design/life-zones/project/shared.jsx → ZoneGlyph
struct ZoneGlyph: View {
    let glyph: ZoneGlyphID
    var size: CGFloat = 18
    var stroke: CGFloat = 1.6

    var body: some View {
        ZoneGlyphShape(glyph: glyph)
            .stroke(style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
            .aspectRatio(1, contentMode: .fit)
    }
}

struct ZoneGlyphShape: Shape {
    let glyph: ZoneGlyphID

    func path(in rect: CGRect) -> Path {
        // Normalize to 24-unit viewBox
        let s = min(rect.width, rect.height) / 24
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * s, y: rect.minY + y * s)
        }
        var path = Path()

        switch glyph {
        case .spark:
            // 8-point spark / sun rays
            for (a, b) in [
                ((12, 3), (12, 7)),  ((12, 17), (12, 21)),
                ((3, 12), (7, 12)),  ((17, 12), (21, 12)),
                ((5.6, 5.6), (8.4, 8.4)),   ((15.6, 15.6), (18.4, 18.4)),
                ((5.6, 18.4), (8.4, 15.6)), ((15.6, 8.4), (18.4, 5.6)),
            ] as [((CGFloat, CGFloat), (CGFloat, CGFloat))] {
                path.move(to: p(a.0, a.1))
                path.addLine(to: p(b.0, b.1))
            }
        case .focus:
            // Concentric circles 3 and 8
            path.addEllipse(in: CGRect(x: rect.minX + 9 * s, y: rect.minY + 9 * s, width: 6 * s, height: 6 * s))
            path.addEllipse(in: CGRect(x: rect.minX + 4 * s, y: rect.minY + 4 * s, width: 16 * s, height: 16 * s))
        case .people:
            // Two figures with shoulders
            path.addEllipse(in: CGRect(x: rect.minX + 6 * s, y: rect.minY + 6 * s, width: 6 * s, height: 6 * s))
            path.addEllipse(in: CGRect(x: rect.minX + 14.8 * s, y: rect.minY + 7.8 * s, width: 4.4 * s, height: 4.4 * s))
            // M3 19c.6-3 3-5 6-5s5.4 2 6 5
            path.move(to: p(3, 19))
            path.addCurve(to: p(15, 19),
                          control1: p(3.6, 16),
                          control2: p(12, 14))
            // M15 17.2c.4-1.6 1.8-2.7 3.5-2.7 1.4 0 2.6.7 3 2
            path.move(to: p(15, 17.2))
            path.addCurve(to: p(21.5, 16.5),
                          control1: p(15.4, 15.6),
                          control2: p(16.8, 14.5))
        case .moon:
            // Crescent
            path.move(to: p(19, 14.5))
            path.addCurve(to: p(9.5, 5),
                          control1: p(14.5, 14),
                          control2: p(10, 9.5))
            // Bottom curve back
            path.addCurve(to: p(19, 14.5),
                          control1: p(4.5, 9.5),
                          control2: p(13.5, 19.5))
        case .pen:
            // Diagonal pen line
            path.move(to: p(4, 20))
            path.addLine(to: p(7.5, 19))
            path.addLine(to: p(18.5, 8))
            path.addLine(to: p(16, 5.5))
            path.addLine(to: p(5, 16.5))
            path.addLine(to: p(4, 20))
            path.closeSubpath()
            path.move(to: p(14.5, 7.5))
            path.addLine(to: p(17, 10))
        case .house:
            // Roof
            path.move(to: p(4, 11))
            path.addLine(to: p(12, 4))
            path.addLine(to: p(20, 11))
            // Body
            path.move(to: p(6, 10))
            path.addLine(to: p(6, 19))
            path.addLine(to: p(18, 19))
            path.addLine(to: p(18, 10))
            // Door
            path.move(to: p(10, 19))
            path.addLine(to: p(10, 14))
            path.addLine(to: p(14, 14))
            path.addLine(to: p(14, 19))
        case .leaf:
            // Outer leaf shape
            path.move(to: p(5, 19))
            path.addCurve(to: p(19, 5),
                          control1: p(5, 11),
                          control2: p(11, 5))
            path.addCurve(to: p(5, 19),
                          control1: p(19, 13),
                          control2: p(13, 19))
            // Vein
            path.move(to: p(5, 19))
            path.addCurve(to: p(19, 5),
                          control1: p(9, 15),
                          control2: p(13, 11))
        }
        return path
    }
}
