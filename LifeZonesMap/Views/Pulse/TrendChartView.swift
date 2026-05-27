import SwiftUI

/// Multi-line trend chart drawn directly in Canvas (matches pulse-screen.jsx LineChart).
/// Custom legend below shows series + first→last delta.
struct TrendChartView: View {
    let checkIns: [WeeklyCheckIn]

    var body: some View {
        VStack(spacing: 0) {
            Canvas { ctx, size in
                draw(in: ctx, size: size)
            }
            .frame(height: 180)
            .padding(.horizontal, 14)
            .padding(.top, 14)

            legend
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LZ.paper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
    }

    // MARK: - Drawing

    private func draw(in ctx: GraphicsContext, size: CGSize) {
        let pad = (l: 22.0, r: 24.0, t: 8.0, b: 22.0)
        let w = size.width, h = size.height
        let n = max(1, checkIns.count - 1)
        let chartW = w - pad.l - pad.r
        let chartH = h - pad.t - pad.b

        // y gridlines + labels at 0, 2.5, 5, 7.5, 10
        for v in [0.0, 2.5, 5.0, 7.5, 10.0] {
            let y = pad.t + (1 - v / 10) * chartH
            var p = Path()
            p.move(to: CGPoint(x: pad.l, y: y))
            p.addLine(to: CGPoint(x: pad.l + chartW, y: y))
            let isEdge = (v == 0 || v == 10)
            ctx.stroke(
                p,
                with: .color(LZ.rule),
                style: StrokeStyle(lineWidth: 0.5, dash: isEdge ? [] : [3, 3])
            )
            let label = Text("\(Int(v))")
                .font(.system(size: 9).monospacedDigit())
                .foregroundStyle(LZ.inkMute)
            ctx.draw(label, at: CGPoint(x: pad.l - 6, y: y), anchor: .trailing)
        }

        // x labels — week index
        if !checkIns.isEmpty {
            for (i, _) in checkIns.enumerated() {
                let x = pad.l + (CGFloat(i) / CGFloat(n)) * chartW
                let label = Text("W\(i + 1)")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(LZ.inkMute)
                ctx.draw(label, at: CGPoint(x: x, y: h - 8), anchor: .center)
            }
        }

        // Series lines
        for zone in ZoneID.allCases {
            let def = ZoneRegistry.definition(for: zone)
            let data: [CGFloat] = checkIns.map { CGFloat($0.score(for: zone)) }
            guard data.count >= 2 else { continue }

            var line = Path()
            for (i, v) in data.enumerated() {
                let x = pad.l + (CGFloat(i) / CGFloat(n)) * chartW
                let y = pad.t + (1 - v / 10) * chartH
                if i == 0 { line.move(to: CGPoint(x: x, y: y)) }
                else { line.addLine(to: CGPoint(x: x, y: y)) }
            }
            ctx.stroke(
                line,
                with: .color(def.color.opacity(0.92)),
                style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
            )

            // Dots
            for (i, v) in data.enumerated() {
                let x = pad.l + (CGFloat(i) / CGFloat(n)) * chartW
                let y = pad.t + (1 - v / 10) * chartH
                let r: CGFloat = (i == data.count - 1) ? 2.6 : 1.6
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                    with: .color(def.color)
                )
            }

            // End label
            if let last = data.last {
                let x = pad.l + chartW + 4
                let y = pad.t + (1 - last / 10) * chartH
                let label = Text(String(format: "%.1f", Double(last)))
                    .font(.system(size: 8.5, weight: .semibold).monospacedDigit())
                    .foregroundStyle(def.color)
                ctx.draw(label, at: CGPoint(x: x, y: y), anchor: .leading)
            }
        }
    }

    // MARK: - Legend

    private var legend: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)],
                  spacing: 4) {
            ForEach(ZoneRegistry.all) { def in
                HStack(spacing: 7) {
                    Capsule().fill(def.color).frame(width: 14, height: 2)
                    Text(def.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(LZ.inkSoft)
                    Spacer(minLength: 0)
                    if let (first, last) = firstAndLast(zone: def.id) {
                        Text("\(String(format: "%.1f", first)) → \(String(format: "%.1f", last))")
                            .font(.system(size: 10.5).monospacedDigit())
                            .foregroundStyle(LZ.inkMute)
                    }
                }
            }
        }
    }

    private func firstAndLast(zone: ZoneID) -> (Double, Double)? {
        guard let first = checkIns.first, let last = checkIns.last else { return nil }
        return (Double(first.score(for: zone)), Double(last.score(for: zone)))
    }
}
