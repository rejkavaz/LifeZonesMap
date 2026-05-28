import SwiftUI

// MARK: - The radar polygon itself (used at many sizes)

struct RadarMap: View {
    let scores: [ZoneID: Int]
    var size: CGFloat = 342
    var showNodes = true
    var showLabels = true
    var showRings = true
    var showGrid = true
    var fill: Color = LZ.teal
    var fillOpacity: Double = 0.16
    var stroke: Color = LZ.tealDeep
    var ringColor: Color = Color(hex: "#C2B79C")
    var dotRadius: CGFloat = 5.5

    private let zones = ZoneID.allCases

    /// Plain-text summary used by VoiceOver instead of the Canvas drawing.
    var accessibilitySummary: String {
        let avg = Double(scores.values.reduce(0, +)) / Double(max(1, scores.count))
        let parts = ZoneID.allCases.map { zone -> String in
            "\(ZoneRegistry.definition(for: zone).name): \(scores[zone] ?? 5)"
        }
        return "Life Zones map. Overall average \(String(format: "%.1f", avg)). " + parts.joined(separator: ", ") + "."
    }

    var body: some View {
        ZStack {
            Canvas { ctx, _ in
                let center = CGPoint(x: size / 2, y: size / 2)
                let inset  = size * 0.18
                let R      = size / 2 - inset

                // Rings — 4 dashed 7-sided polygons at 0.25, 0.5, 0.75, 1.0
                if showRings {
                    let ringScales: [CGFloat] = [0.25, 0.5, 0.75, 1.0]
                    for (i, scale) in ringScales.enumerated() {
                        var path = Path()
                        for k in 0..<zones.count {
                            let pt = radialPoint(center: center, index: k, radius: R * scale)
                            if k == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                        }
                        path.closeSubpath()
                        let isOuter = i == ringScales.count - 1
                        ctx.stroke(
                            path,
                            with: .color(ringColor.opacity(0.55)),
                            style: StrokeStyle(
                                lineWidth: isOuter ? 0.9 : 0.7,
                                dash: isOuter ? [] : [3, 4]
                            )
                        )
                    }
                }

                // Axis spokes
                if showGrid {
                    for k in 0..<zones.count {
                        var p = Path()
                        p.move(to: center)
                        p.addLine(to: radialPoint(center: center, index: k, radius: R))
                        ctx.stroke(p, with: .color(ringColor.opacity(0.55)), lineWidth: 0.6)
                    }
                }

                // Score polygon
                var poly = Path()
                for (i, z) in zones.enumerated() {
                    let v = CGFloat(scores[z] ?? 5) / 10
                    let pt = radialPoint(center: center, index: i, radius: R * v)
                    if i == 0 { poly.move(to: pt) } else { poly.addLine(to: pt) }
                }
                poly.closeSubpath()
                ctx.fill(poly, with: .color(fill.opacity(fillOpacity)))
                ctx.stroke(poly, with: .color(stroke), style: StrokeStyle(lineWidth: 1.4, lineJoin: .round))

                // Nodes (white halo + colored center)
                if showNodes {
                    for (i, z) in zones.enumerated() {
                        let v = CGFloat(scores[z] ?? 5) / 10
                        let pt = radialPoint(center: center, index: i, radius: R * v)
                        let def = ZoneRegistry.definition(for: z)
                        let outerR = dotRadius + 2
                        let innerR = max(dotRadius - 1, 1.5)
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: pt.x - outerR, y: pt.y - outerR,
                                                   width: outerR * 2, height: outerR * 2)),
                            with: .color(LZ.paper)
                        )
                        ctx.stroke(
                            Path(ellipseIn: CGRect(x: pt.x - outerR, y: pt.y - outerR,
                                                   width: outerR * 2, height: outerR * 2)),
                            with: .color(def.color), lineWidth: 1.2
                        )
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: pt.x - innerR, y: pt.y - innerR,
                                                   width: innerR * 2, height: innerR * 2)),
                            with: .color(def.color)
                        )
                    }
                }
            }
            .frame(width: size, height: size)

            // Labels — SwiftUI Text so it picks up dynamic type if needed
            if showLabels {
                labels
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityAddTraits(.isImage)
    }

    // MARK: - Labels

    @ViewBuilder private var labels: some View {
        let center = CGPoint(x: size / 2, y: size / 2)
        let inset  = size * 0.18
        let R      = size / 2 - inset

        ForEach(Array(zones.enumerated()), id: \.element) { i, z in
            let angle = angleFor(index: i)
            let pt    = CGPoint(x: center.x + cos(angle) * (R + inset * 0.62),
                                y: center.y + sin(angle) * (R + inset * 0.62))
            let def   = ZoneRegistry.definition(for: z)
            let score = scores[z] ?? 5
            let isRight = cos(angle) > 0.2
            let isLeft  = cos(angle) < -0.2
            let alignment: HorizontalAlignment = isRight ? .leading : (isLeft ? .trailing : .center)
            let frameAlign: Alignment = isRight ? .leading : (isLeft ? .trailing : .center)

            VStack(alignment: alignment, spacing: 1) {
                Text(def.name)
                    .font(.system(size: size * 0.034, weight: .medium))
                    .tracking(0.2)
                    .foregroundStyle(LZ.ink)
                Text(String(format: "%.1f", Double(score)))
                    .font(.system(size: size * 0.038, weight: .semibold).monospacedDigit())
                    .foregroundStyle(def.color)
            }
            .frame(width: 90, alignment: frameAlign)
            .position(x: pt.x + (isRight ? 38 : (isLeft ? -38 : 0)),
                      y: pt.y)
        }
    }

    // MARK: - Geometry

    private func angleFor(index: Int) -> CGFloat {
        let n = CGFloat(zones.count)
        return -CGFloat.pi / 2 + (CGFloat(index) / n) * .pi * 2
    }

    private func radialPoint(center: CGPoint, index: Int, radius: CGFloat) -> CGPoint {
        let a = angleFor(index: index)
        return CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius)
    }
}

// MARK: - The Map screen

struct MapView: View {
    let scores: [ZoneID: Int]
    var onZoneTap: (ZoneID) -> Void = { _ in }
    var onSettingsTap: () -> Void = {}

    private var overallAverage: Double {
        let vals = scores.values
        guard !vals.isEmpty else { return 0 }
        return Double(vals.reduce(0, +)) / Double(vals.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            canvasCard
            zoneList
        }
        .background(LZ.paper.ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Life Zones")
                .font(.system(size: 19, weight: .medium))
                .tracking(-0.34)
                .foregroundStyle(LZ.ink)
            Spacer()
            Text(currentWeekLabel())
                .uppercaseCaption(size: 11)
            Button(action: onSettingsTap) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(LZ.inkMute)
            }
            .padding(.leading, DS.Spacing.s8)
        }
        .padding(.horizontal, 24)
        .padding(.top, DS.Spacing.s4)
        .padding(.bottom, DS.Spacing.s8)
    }

    private func currentWeekLabel() -> String {
        let monday = Date().isoWeekMonday
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return "Week of \(f.string(from: monday))"
    }

    // MARK: - Canvas card

    private var canvasCard: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                .fill(LZ.cream)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                        .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                )

            // Faint topo
            TopoTexture(
                lines: 14,
                palette: TopoPalette.mapHint,
                seed: 3,
                opacity: 0.55,
                lineWidth: 0.8
            )
            .blendMode(.multiply)
            .opacity(0.20)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))

            CornerTicks()

            // Top-left "THIS WEEK" pin
            VStack {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(LZ.tealDeep.opacity(0.7))
                            .frame(width: 6, height: 6)
                        Text("This week").uppercaseCaption(size: 9.5, tracking: 1.5)
                    }
                    Spacer()
                    Text("Scale 0 — 10").uppercaseCaption(size: 9.5, tracking: 1.5)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                Spacer()
            }

            // The radar
            RadarMap(
                scores: scores,
                size: 342,
                fill: LZ.teal,
                fillOpacity: 0.16,
                stroke: LZ.tealDeep,
                ringColor: Color(hex: "#C2B79C")
            )
            .padding(.top, 10)
            .padding(.bottom, 6)

            // Center avg badge
            VStack(spacing: 0) {
                Text("Avg").uppercaseCaption(size: 9, tracking: 2.0)
                Text(String(format: "%.1f", overallAverage))
                    .font(.system(size: 26, weight: .medium).monospacedDigit())
                    .tracking(-0.5)
                    .foregroundStyle(LZ.ink)
            }
            .offset(y: -4)
            .allowsHitTesting(false)
        }
        .frame(height: 372)
        .padding(.horizontal, 18)
    }

    // MARK: - Zone list

    private var zoneList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("By zone").uppercaseCaption()
                    Spacer()
                }
                .padding(.bottom, 10)

                ForEach(Array(ZoneRegistry.all.enumerated()), id: \.element.id) { idx, def in
                    Button(action: { onZoneTap(def.id) }) {
                        ZoneRow(
                            definition: def,
                            score: scores[def.id] ?? 5,
                            isLast: idx == ZoneRegistry.all.count - 1
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Zone row

struct ZoneRow: View {
    let definition: ZoneDefinition
    let score: Int
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                // Color dot with halo
                ZStack {
                    Circle().fill(definition.color.opacity(0.13)).frame(width: 14, height: 14)
                    Circle().fill(definition.color).frame(width: 8, height: 8)
                }
                .frame(width: 14)

                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text(definition.name)
                            .font(.system(size: 15, weight: .medium))
                            .tracking(-0.075)
                            .foregroundStyle(LZ.ink)
                        Spacer()
                        Text(definition.blurb)
                            .font(.system(size: 10.5, weight: .medium))
                            .tracking(0.4)
                            .foregroundStyle(LZ.inkMute)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: "#E2D8C0")).frame(height: 4)
                            Capsule().fill(definition.color)
                                .frame(width: geo.size.width * CGFloat(score) / 10, height: 4)
                        }
                    }
                    .frame(height: 4)
                }

                Text(String(format: "%.1f", Double(score)))
                    .font(.system(size: 18, weight: .medium).monospacedDigit())
                    .tracking(-0.18)
                    .foregroundStyle(LZ.ink)
                    .frame(minWidth: 34, alignment: .trailing)
            }
            .padding(.vertical, 14)

            if !isLast {
                Rectangle().fill(LZ.ruleSoft).frame(height: 0.5)
            }
        }
    }
}

#Preview {
    MapView(scores: [
        .vitality: 6, .deepWork: 8, .connection: 7,
        .innerWorld: 5, .creation: 7, .foundation: 8, .growth: 6
    ])
}
