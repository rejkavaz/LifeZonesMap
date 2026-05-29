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
    /// Optional: tapping a zone's label/node calls back so the radar itself
    /// becomes navigable, not just the list below it.
    var onZoneTap: ((ZoneID) -> Void)? = nil
    /// Optional faint "last week" polygon drawn behind the current one for
    /// at-a-glance comparison. Nil = no overlay.
    var ghostScores: [ZoneID: Int]? = nil
    /// Grow the polygon out from the centre on appear / when scores change.
    /// Disabled for the tiny radars in lists, which shouldn't pop as you scroll.
    var animateReveal = true

    @State private var revealProgress: CGFloat = 0

    private let zones = ZoneID.allCases

    /// Polygon inset from the frame edge. When labels are shown we pull the
    /// polygon in further so the surrounding text has room to sit *inside*
    /// the canvas bounds instead of spilling past them.
    private var inset: CGFloat { size * (showLabels ? 0.22 : 0.18) }

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
            // The Canvas is wrapped so a single animatable `progress` (0→1)
            // grows the data polygon out from the centre. Rings/grid stay put.
            AnimatableReveal(progress: animateReveal ? revealProgress : 1) { p in
                Canvas { ctx, _ in
                    let center = CGPoint(x: size / 2, y: size / 2)
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
                            var path = Path()
                            path.move(to: center)
                            path.addLine(to: radialPoint(center: center, index: k, radius: R))
                            ctx.stroke(path, with: .color(ringColor.opacity(0.55)), lineWidth: 0.6)
                        }
                    }

                    // "Last week" ghost polygon — faint dashed outline behind
                    // the current one, grown by the same reveal progress.
                    if let ghost = ghostScores {
                        let gpoly = polygonPath(for: ghost, center: center, R: R, scale: p)
                        ctx.stroke(
                            gpoly,
                            with: .color(LZ.ink.opacity(0.28)),
                            style: StrokeStyle(lineWidth: 1, lineJoin: .round, dash: [3, 3])
                        )
                    }

                    // Score polygon
                    let poly = polygonPath(for: scores, center: center, R: R, scale: p)
                    ctx.fill(poly, with: .color(fill.opacity(fillOpacity)))
                    ctx.stroke(poly, with: .color(stroke), style: StrokeStyle(lineWidth: 1.4, lineJoin: .round))

                    // Nodes (white halo + colored center)
                    if showNodes {
                        for (i, z) in zones.enumerated() {
                            let v = CGFloat(scores[z] ?? 5) / 10 * p
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
            }

            // Labels — SwiftUI Text so it picks up dynamic type if needed
            if showLabels {
                labels
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            guard animateReveal, revealProgress < 1 else { return }
            withAnimation(.easeOut(duration: 0.55)) { revealProgress = 1 }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityAddTraits(.isImage)
    }

    /// Closed polygon path for a set of zone scores, with each vertex pulled
    /// toward the centre by `scale` (used for the grow-in reveal).
    private func polygonPath(for values: [ZoneID: Int], center: CGPoint, R: CGFloat, scale: CGFloat) -> Path {
        var path = Path()
        for (i, z) in zones.enumerated() {
            let v = CGFloat(values[z] ?? 5) / 10 * scale
            let pt = radialPoint(center: center, index: i, radius: R * v)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }

    // MARK: - Labels

    @ViewBuilder private var labels: some View {
        let center = size / 2
        let R      = center - inset
        // Sit the labels just outside the outer ring …
        let labelRadius = R + inset * 0.34
        // … then anchor each label's *inner* edge to that point and clamp the
        // whole box inside [0, size] so side zones (Foundation / Connection)
        // can never run past the canvas. lineLimit + minimumScaleFactor are a
        // final backstop for large Dynamic Type sizes.
        let labelW: CGFloat = size * 0.24
        let edge: CGFloat = 4

        ForEach(Array(zones.enumerated()), id: \.element) { i, z in
            let angle = angleFor(index: i)
            let vx = center + cos(angle) * labelRadius
            let vy = center + sin(angle) * labelRadius
            let def   = ZoneRegistry.definition(for: z)
            let score = scores[z] ?? 5
            let isRight = cos(angle) > 0.2
            let isLeft  = cos(angle) < -0.2
            let hAlign: HorizontalAlignment = isRight ? .leading : (isLeft ? .trailing : .center)
            let tAlign: TextAlignment = isRight ? .leading : (isLeft ? .trailing : .center)

            // Anchor the edge nearest the polygon to the ring point, then keep
            // the box fully on-canvas.
            let rawCenterX = isRight ? vx + labelW / 2 : (isLeft ? vx - labelW / 2 : vx)
            let centerX = min(max(rawCenterX, labelW / 2 + edge), size - labelW / 2 - edge)

            VStack(alignment: hAlign, spacing: 1) {
                Text(def.name)
                    .font(.system(size: size * 0.033, weight: .medium))
                    .tracking(0.2)
                    .foregroundStyle(LZ.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(String(format: "%.1f", Double(score)))
                    .font(.system(size: size * 0.04, weight: .semibold).monospacedDigit())
                    .foregroundStyle(def.color)
            }
            .multilineTextAlignment(tAlign)
            .frame(width: labelW, alignment: Alignment(horizontal: hAlign, vertical: .center))
            .contentShape(Rectangle())
            .onTapGesture { onZoneTap?(z) }
            .position(x: centerX, y: vy)
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

// MARK: - Animatable reveal wrapper

/// Re-renders its content for every interpolated frame of `progress`, which
/// lets a `Canvas` (not otherwise implicitly animatable) grow on appear and
/// when its data changes.
private struct AnimatableReveal<Content: View>: View, Animatable {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    @ViewBuilder var content: (CGFloat) -> Content

    var body: some View { content(progress) }
}

// MARK: - The Map screen

struct MapView: View {
    let scores: [ZoneID: Int]
    var previousScores: [ZoneID: Int]? = nil
    var onZoneTap: (ZoneID) -> Void = { _ in }
    var onSettingsTap: () -> Void = {}

    @State private var showingQuickMark = false
    @State private var showComparison = true

    private var overallAverage: Double {
        let vals = scores.values
        guard !vals.isEmpty else { return 0 }
        return Double(vals.reduce(0, +)) / Double(vals.count)
    }

    /// The lowest-scoring zone this week — surfaced as a gentle "needs care"
    /// cue, mirroring the lock-screen widget. Never a scold, just a pointer.
    private var lowestZone: ZoneDefinition? {
        guard !scores.isEmpty else { return nil }
        let lowest = ZoneID.allCases.min { (scores[$0] ?? 5) < (scores[$1] ?? 5) }
        return lowest.map { ZoneRegistry.definition(for: $0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            canvasCard
            zoneList
        }
        .background(LZ.paper.ignoresSafeArea())
        .sheet(isPresented: $showingQuickMark) {
            QuickMarkSheet()
        }
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
            Button { showingQuickMark = true } label: {
                Image(systemName: "plus.circle")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(LZ.tealDeep)
            }
            .accessibilityLabel("Mark today")
            .padding(.leading, DS.Spacing.s8)
            Button(action: onSettingsTap) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(LZ.inkMute)
            }
            .padding(.leading, DS.Spacing.s4)
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
                ringColor: Color(hex: "#C2B79C"),
                onZoneTap: onZoneTap,
                ghostScores: showComparison ? previousScores : nil
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

            // "vs last week" legend / toggle — only when there's prior data
            if previousScores != nil {
                VStack {
                    Spacer()
                    HStack {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) { showComparison.toggle() }
                        } label: {
                            HStack(spacing: 6) {
                                Capsule()
                                    .fill(LZ.ink.opacity(showComparison ? 0.28 : 0.14))
                                    .frame(width: 14, height: 2)
                                Text(showComparison ? "vs last week" : "show last week")
                                    .uppercaseCaption(
                                        color: showComparison ? LZ.inkSoft : LZ.inkMute,
                                        size: 9, tracking: 1.5
                                    )
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(LZ.paper.opacity(showComparison ? 0.5 : 0))
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(showComparison ? "Hide last week comparison" : "Show last week comparison")
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                }
            }
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
                    if let low = lowestZone {
                        Button { onZoneTap(low.id) } label: {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(low.color)
                                    .frame(width: 6, height: 6)
                                Text("Needs care · \(low.name)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(LZ.inkSoft)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Lowest zone: \(low.name). Open zone.")
                    }
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
    MapView(
        scores: [
            .vitality: 6, .deepWork: 8, .connection: 7,
            .innerWorld: 5, .creation: 7, .foundation: 8, .growth: 6
        ],
        previousScores: [
            .vitality: 5, .deepWork: 7, .connection: 5,
            .innerWorld: 6, .creation: 6, .foundation: 7, .growth: 5
        ]
    )
}
