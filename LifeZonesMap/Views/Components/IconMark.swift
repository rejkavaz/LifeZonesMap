import SwiftUI

/// The app icon mark — a slightly irregular 7-point polygon ("half gem, half island").
/// Mirrors design/life-zones/project/shared.jsx → IconMark
struct IconMark: View {
    var size: CGFloat = 200
    var color: Color = LZ.tealDeep
    var bg: Color = LZ.cream
    var rounded: CGFloat = 44

    private let offsets: [CGFloat] = [0.95, 0.78, 1.0, 0.86, 0.92, 0.74, 1.0]

    var body: some View {
        ZStack {
            // Background tile
            RoundedRectangle(cornerRadius: rounded, style: .continuous)
                .fill(bg)

            // Faint inner ring — surveyor's marker
            Circle()
                .stroke(color.opacity(0.12), lineWidth: 1)
                .frame(width: size * 0.71, height: size * 0.71)

            // Closed 7-point polygon at 92% fill
            IslandPolygon(offsets: offsets, radiusFactor: 0.34)
                .fill(color.opacity(0.92))
                .frame(width: size, height: size)

            // Center survey dot
            Circle()
                .fill(bg)
                .frame(width: 4.8, height: 4.8)
        }
        .frame(width: size, height: size)
    }
}

/// 7-point polygon used inside `IconMark` and the animated radar.
struct IslandPolygon: Shape {
    let offsets: [CGFloat]
    var radiusFactor: CGFloat = 0.34

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let R  = min(rect.width, rect.height) * radiusFactor
        var path = Path()
        let n = offsets.count
        for i in 0..<n {
            let angle = -CGFloat.pi / 2 + (CGFloat(i) / CGFloat(n)) * .pi * 2
            let r = R * offsets[i]
            let pt = CGPoint(x: cx + cos(angle) * r, y: cy + sin(angle) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Corner ticks (decoration on the Map card)

struct CornerTicks: View {
    var color: Color = LZ.inkMute.opacity(0.45)
    var size: CGFloat = 14
    var inset: CGFloat = 6
    var thickness: CGFloat = 0.5

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Tick(corner: .topLeft, color: color, size: size, thickness: thickness)
                    Spacer()
                    Tick(corner: .topRight, color: color, size: size, thickness: thickness)
                }
                Spacer()
                HStack {
                    Tick(corner: .bottomLeft, color: color, size: size, thickness: thickness)
                    Spacer()
                    Tick(corner: .bottomRight, color: color, size: size, thickness: thickness)
                }
            }
            .padding(inset)
        }
        .allowsHitTesting(false)
    }

    enum Corner { case topLeft, topRight, bottomLeft, bottomRight }

    struct Tick: View {
        let corner: Corner
        let color: Color
        let size: CGFloat
        let thickness: CGFloat
        var body: some View {
            Canvas { ctx, _ in
                let p = Path { path in
                    switch corner {
                    case .topLeft:
                        path.move(to: CGPoint(x: size, y: 0));      path.addLine(to: .zero)
                        path.move(to: .zero);                       path.addLine(to: CGPoint(x: 0, y: size))
                    case .topRight:
                        path.move(to: CGPoint(x: 0, y: 0));         path.addLine(to: CGPoint(x: size, y: 0))
                        path.move(to: CGPoint(x: size, y: 0));      path.addLine(to: CGPoint(x: size, y: size))
                    case .bottomLeft:
                        path.move(to: CGPoint(x: 0, y: 0));         path.addLine(to: CGPoint(x: 0, y: size))
                        path.move(to: CGPoint(x: 0, y: size));      path.addLine(to: CGPoint(x: size, y: size))
                    case .bottomRight:
                        path.move(to: CGPoint(x: size, y: 0));      path.addLine(to: CGPoint(x: size, y: size))
                        path.move(to: CGPoint(x: size, y: size));   path.addLine(to: CGPoint(x: 0, y: size))
                    }
                }
                ctx.stroke(p, with: .color(color), lineWidth: thickness)
            }
            .frame(width: size, height: size)
        }
    }
}

// MARK: - Wordmark

struct Wordmark: View {
    var size: CGFloat = 44
    var color: Color = LZ.ink
    var accent: Color = LZ.tealDeep
    var withMark: Bool = false

    var body: some View {
        HStack(spacing: size * 0.32) {
            if withMark {
                IconMark(size: size * 1.15, color: accent, bg: LZ.cream, rounded: size * 0.26)
            }
            Text("Life\u{00A0}Zones")
                .font(.system(size: size, weight: .medium, design: .default))
                .tracking(-size * 0.022)
                .foregroundStyle(color)
        }
    }
}
