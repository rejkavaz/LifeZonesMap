import SwiftUI
import TipKit

// MARK: - Shared radar geometry

/// Angle for vertex `i` in a regular n-sided polygon, starting at -π/2 (top).
private func radarAngle(index i: Int, of n: Int) -> CGFloat {
    -CGFloat.pi / 2 + (CGFloat(i) / CGFloat(n)) * .pi * 2
}

/// Build the polygon path for a set of zone scores. `scale` lets the caller
/// scale all vertex distances by a single multiplier — used by the reveal
/// animation (0 → 1) and by ghost overlays at 1.
private func radarPolygonPath(
    scores: [ZoneID: Int],
    zones: [ZoneID],
    center: CGPoint,
    R: CGFloat,
    scale: CGFloat = 1
) -> Path {
    var path = Path()
    for (i, z) in zones.enumerated() {
        let v = CGFloat(scores[z] ?? 5) / 10 * scale
        let a = radarAngle(index: i, of: zones.count)
        let pt = CGPoint(x: center.x + cos(a) * R * v,
                         y: center.y + sin(a) * R * v)
        if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
    }
    path.closeSubpath()
    return path
}

// MARK: - Animatable reveal layer
// Canvas can't animate implicitly, so we wrap it in a view that conforms to
// Animatable over a single CGFloat. SwiftUI calls `body` with interpolated
// progress values while the animation runs, and the Canvas re-renders each
// frame using the new value.

private struct RadarRevealLayer: View, Animatable {
    let scores: [ZoneID: Int]
    let zones: [ZoneID]
    let insetProportion: CGFloat
    let fill: Color
    let fillOpacity: Double
    let stroke: Color
    let dotRadius: CGFloat
    let showNodes: Bool

    var progress: CGFloat
    // Animatable's protocol requirement is nonisolated, but View is
    // implicitly @MainActor in Swift 6 strict-concurrency mode. Mark this
    // property nonisolated so it can satisfy the protocol — safe because
    // CGFloat is Sendable and the struct is a value type.
    nonisolated var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        Canvas { ctx, size in
            let dim = min(size.width, size.height)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let insetVal = dim * insetProportion
            let R = dim / 2 - insetVal

            let poly = radarPolygonPath(
                scores: scores, zones: zones,
                center: center, R: R,
                scale: progress
            )
            ctx.fill(poly, with: .color(fill.opacity(fillOpacity)))
            ctx.stroke(poly,
                       with: .color(stroke),
                       style: StrokeStyle(lineWidth: 1.4, lineJoin: .round))

            if showNodes {
                for (i, z) in zones.enumerated() {
                    let v = CGFloat(scores[z] ?? 5) / 10 * progress
                    let a = radarAngle(index: i, of: zones.count)
                    let pt = CGPoint(x: center.x + cos(a) * R * v,
                                     y: center.y + sin(a) * R * v)
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
    }
}

// MARK: - RadarMap (the radar polygon — used at many sizes)

struct RadarMap: View {
    let scores: [ZoneID: Int]
    /// Optional ghost overlay of the previous week's scores. When nil, no
    /// ghost is drawn.
    var previousScores: [ZoneID: Int]? = nil
    /// Whether to show the ghost overlay. Owner of this view decides;
    /// MapView wires this to a small bottom-left toggle.
    var showPreviousOverlay: Bool = true
    /// Set to false for tiny radars in History / YearOverview tiles — they
    /// shouldn't pop one-by-one as the list scrolls.
    var animateReveal: Bool = true

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

    @State private var revealProgress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let zones = ZoneID.allCases
    private let insetProportion: CGFloat = 0.18

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
            // 1. Static rings + spokes (never animate)
            Canvas { ctx, canvasSize in
                let dim = min(canvasSize.width, canvasSize.height)
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let insetVal = dim * insetProportion
                let R = dim / 2 - insetVal

                if showRings {
                    let ringScales: [CGFloat] = [0.25, 0.5, 0.75, 1.0]
                    for (i, scale) in ringScales.enumerated() {
                        var path = Path()
                        for k in 0..<zones.count {
                            let a = radarAngle(index: k, of: zones.count)
                            let pt = CGPoint(x: center.x + cos(a) * R * scale,
                                             y: center.y + sin(a) * R * scale)
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

                if showGrid {
                    for k in 0..<zones.count {
                        let a = radarAngle(index: k, of: zones.count)
                        var p = Path()
                        p.move(to: center)
                        p.addLine(to: CGPoint(x: center.x + cos(a) * R,
                                              y: center.y + sin(a) * R))
                        ctx.stroke(p, with: .color(ringColor.opacity(0.55)), lineWidth: 0.6)
                    }
                }
            }

            // 2. Previous-week ghost polygon (only if data + visible)
            if let previousScores, showPreviousOverlay {
                Canvas { ctx, canvasSize in
                    let dim = min(canvasSize.width, canvasSize.height)
                    let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                    let insetVal = dim * insetProportion
                    let R = dim / 2 - insetVal

                    let ghost = radarPolygonPath(
                        scores: previousScores, zones: zones,
                        center: center, R: R, scale: 1
                    )
                    ctx.stroke(
                        ghost,
                        with: .color(LZ.ink.opacity(0.28)),
                        style: StrokeStyle(lineWidth: 1.2, lineJoin: .round, dash: [3, 4])
                    )
                }
                .transition(.opacity)
            }

            // 3. Current polygon + nodes, animated via Animatable progress
            RadarRevealLayer(
                scores: scores,
                zones: zones,
                insetProportion: insetProportion,
                fill: fill,
                fillOpacity: fillOpacity,
                stroke: stroke,
                dotRadius: dotRadius,
                showNodes: showNodes,
                progress: revealProgress
            )

            // 4. Labels — SwiftUI Text overlay
            if showLabels {
                labels
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            // Respect the system Reduce Motion accessibility setting — when
            // it's on, skip the grow-in entirely and snap to full state.
            if animateReveal && !reduceMotion {
                withAnimation(.easeOut(duration: 0.55)) {
                    revealProgress = 1
                }
            } else {
                revealProgress = 1
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityAddTraits(.isImage)
    }

    // MARK: - Labels

    @ViewBuilder private var labels: some View {
        let center = CGPoint(x: size / 2, y: size / 2)
        let inset  = size * insetProportion
        let R      = size / 2 - inset
        // Pull labels closer to the polygon ring (was 0.62 originally, which
        // combined with the previous +/-38 hard offset pushed Foundation /
        // Connection past the canvas edge on narrow screens). 0.42 keeps
        // labels outside the node but well inside the canvas frame.
        let labelMultiplier: CGFloat = 0.42

        ForEach(Array(zones.enumerated()), id: \.element) { i, z in
            let angle = radarAngle(index: i, of: zones.count)
            let pt    = CGPoint(x: center.x + cos(angle) * (R + inset * labelMultiplier),
                                y: center.y + sin(angle) * (R + inset * labelMultiplier))
            let def   = ZoneRegistry.definition(for: z)
            let score = scores[z] ?? 5
            let isRight = cos(angle) > 0.2
            let isLeft  = cos(angle) < -0.2
            let hAlignment: HorizontalAlignment = isRight ? .leading : (isLeft ? .trailing : .center)

            // Intrinsic-width text via fixedSize() so labels are exactly as
            // wide as they need to be; minimumScaleFactor handles the long
            // names ("Inner World" / "Foundation" / "Connection") gracefully.
            VStack(alignment: hAlignment, spacing: 1) {
                Text(def.name)
                    .font(.system(size: size * 0.034, weight: .medium))
                    .tracking(0.1)
                    .foregroundStyle(LZ.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(String(format: "%.1f", Double(score)))
                    .font(.system(size: size * 0.038, weight: .semibold).monospacedDigit())
                    .foregroundStyle(def.color)
                    .lineLimit(1)
            }
            .fixedSize()
            .position(x: pt.x, y: pt.y)
        }
    }
}

// MARK: - The Map screen

struct MapView: View {
    let scores: [ZoneID: Int]
    var previousScores: [ZoneID: Int]? = nil
    var onZoneTap: (ZoneID) -> Void = { _ in }
    var onSettingsTap: () -> Void = {}

    @State private var showingQuickMark = false
    @State private var showPreviousOverlay = true

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
            .popoverTip(MarkTodayTip())
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
                previousScores: previousScores,
                showPreviousOverlay: showPreviousOverlay,
                animateReveal: true,
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

            // Bottom-left previous-week toggle (only when data exists)
            if previousScores != nil {
                VStack {
                    Spacer()
                    HStack {
                        previousWeekToggle
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(height: 372)
        .padding(.horizontal, 18)
    }

    private var previousWeekToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                showPreviousOverlay.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(LZ.ink.opacity(showPreviousOverlay ? 0.28 : 0.10))
                    .frame(width: 6, height: 6)
                Text(showPreviousOverlay ? "vs last week" : "show last week")
                    .uppercaseCaption(
                        color: showPreviousOverlay ? LZ.inkSoft : LZ.inkMute,
                        size: 9.5, tracking: 1.5
                    )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showPreviousOverlay ? "Hide last week overlay" : "Show last week overlay")
        .popoverTip(CompareLastWeekTip())
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
