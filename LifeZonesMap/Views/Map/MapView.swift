import SwiftUI

struct MapView: View {
    let scores: [ZoneID: Int]
    var onZoneTap: (ZoneID) -> Void = { _ in }

    @State private var pulseScale: CGFloat = 1.0
    @State private var animatedScores: [ZoneID: Double] = [:]

    private let zones = ZoneID.allCases
    private let nodeMinRadius: CGFloat = 8
    private let nodeMaxRadius: CGFloat = 22

    var body: some View {
        GeometryReader { geo in
            let size   = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let maxR   = size * 0.42

            ZStack {
                Canvas { ctx, _ in
                    drawGrid(ctx: ctx, center: center, maxR: maxR)
                    drawSpokes(ctx: ctx, center: center, maxR: maxR)
                    drawFilledPolygon(ctx: ctx, center: center, maxR: maxR)
                }
                .accessibilityHidden(true)

                ForEach(Array(zones.enumerated()), id: \.element) { idx, zone in
                    let angle  = angle(for: idx)
                    let score  = animatedScores[zone] ?? 5
                    let pt     = point(center: center, angle: angle, score: score, maxR: maxR)
                    let def    = ZoneRegistry.definition(for: zone)
                    let radius = nodeRadius(for: score)

                    ZStack {
                        Circle()
                            .fill(def.color.opacity(0.25))
                            .frame(width: radius * 2.6, height: radius * 2.6)
                        Circle()
                            .fill(def.color)
                            .frame(width: radius * 2, height: radius * 2)
                            .scaleEffect(pulseScale)
                    }
                    .position(pt)
                    .onTapGesture { onZoneTap(zone) }
                    .accessibilityLabel("\(def.name): \(Int(score)) out of 10")
                    .accessibilityAddTraits(.isButton)

                    Text(labelText(zone: def.name, score: score))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .position(labelPosition(center: center, angle: angle, score: score, maxR: maxR, size: size))
                        .allowsHitTesting(false)
                }
            }
        }
        .onAppear {
            syncAnimatedScores(animated: false)
            startPulse()
        }
        .onChange(of: scores) {
            syncAnimatedScores(animated: true)
        }
    }

    // MARK: - Canvas drawing

    private func drawGrid(ctx: GraphicsContext, center: CGPoint, maxR: CGFloat) {
        for scale in [0.3, 0.6, 1.0] as [Double] {
            var path = Path()
            let r = maxR * scale
            for i in 0..<zones.count {
                let pt = radialPoint(center: center, angle: angle(for: i), radius: r)
                i == 0 ? path.move(to: pt) : path.addLine(to: pt)
            }
            path.closeSubpath()
            ctx.stroke(path, with: .color(.secondary.opacity(0.2)), style: StrokeStyle(lineWidth: 0.8, dash: [4, 4]))
        }
    }

    private func drawSpokes(ctx: GraphicsContext, center: CGPoint, maxR: CGFloat) {
        for i in 0..<zones.count {
            var path = Path()
            path.move(to: center)
            path.addLine(to: radialPoint(center: center, angle: angle(for: i), radius: maxR))
            ctx.stroke(path, with: .color(.secondary.opacity(0.15)), lineWidth: 0.5)
        }
    }

    private func drawFilledPolygon(ctx: GraphicsContext, center: CGPoint, maxR: CGFloat) {
        var path = Path()
        for (i, zone) in zones.enumerated() {
            let score = animatedScores[zone] ?? 5
            let pt = point(center: center, angle: angle(for: i), score: score, maxR: maxR)
            i == 0 ? path.move(to: pt) : path.addLine(to: pt)
        }
        path.closeSubpath()
        ctx.fill(path, with: .color(Color(hex: "#1D9E75").opacity(0.12)))
        ctx.stroke(path, with: .color(Color(hex: "#1D9E75").opacity(0.35)), lineWidth: 1.5)
    }

    // MARK: - Geometry helpers

    private func angle(for index: Int) -> Double {
        let step = (2 * Double.pi) / Double(zones.count)
        return -Double.pi / 2 + step * Double(index)
    }

    private func radialPoint(center: CGPoint, angle: Double, radius: CGFloat) -> CGPoint {
        CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }

    private func point(center: CGPoint, angle: Double, score: Double, maxR: CGFloat) -> CGPoint {
        radialPoint(center: center, angle: angle, radius: maxR * (score / 10))
    }

    private func nodeRadius(for score: Double) -> CGFloat {
        nodeMinRadius + (nodeMaxRadius - nodeMinRadius) * CGFloat(score - 1) / 9
    }

    private func labelPosition(center: CGPoint, angle: Double, score: Double, maxR: CGFloat, size: CGFloat) -> CGPoint {
        let offset: CGFloat = nodeRadius(for: score) + 18
        let nodePt = point(center: center, angle: angle, score: score, maxR: maxR)
        return CGPoint(
            x: nodePt.x + offset * cos(angle),
            y: nodePt.y + offset * sin(angle)
        )
    }

    private func labelText(zone: String, score: Double) -> String {
        "\(zone)\n\(Int(score))"
    }

    // MARK: - Animation

    private func syncAnimatedScores(animated: Bool) {
        for zone in zones {
            let target = Double(scores[zone] ?? 5)
            if animated {
                withAnimation(DS.Anim.spring) { animatedScores[zone] = target }
            } else {
                animatedScores[zone] = target
            }
        }
    }

    private func startPulse() {
        withAnimation(DS.Anim.pulse) { pulseScale = 1.03 }
    }
}

#Preview {
    MapView(scores: MapViewModel.demoScores())
        .frame(height: 340)
        .padding()
}
