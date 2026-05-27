import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @Environment(\.modelContext) private var modelContext
    @State private var page = 0
    @State private var checkInDay = 6   // Sunday default in [Mon..Sun] index → 6
    @State private var checkInHour = 19
    @State private var notificationsGranted = false
    @State private var scores: [ZoneID: Int] = [:]
    @State private var rated: Set<ZoneID> = []

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            switch page {
            case 0: welcomePage
            case 1: zonesPage
            case 2: schedulePage
            default: firstCheckInPage
            }
        }
        .ignoresSafeArea()
        .animation(DS.Anim.sheet, value: page)
    }

    // MARK: - Step 1 — Welcome

    private var welcomePage: some View {
        ZStack {
            Color(hex: "#E8E2CE").ignoresSafeArea()
            TopoTexture(
                lines: 40,
                palette: TopoPalette.sageCoast,
                seed: 4,
                opacity: 0.85,
                lineWidth: 1.0
            )
            .opacity(0.75)
            .ignoresSafeArea()

            // Vignette
            LinearGradient(colors: [.clear, Color(hex: "#785A28").opacity(0.18)],
                           startPoint: .center, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()
                AnimatedRadar(size: 232)
                    .shadow(color: Color.black.opacity(0.15), radius: 24, x: 0, y: 12)

                VStack(spacing: 14) {
                    Text("LIFE ZONES")
                        .uppercaseCaption(color: LZ.inkSoft, size: 11, tracking: 3.1)
                    Text("Your life,\nmapped.")
                        .font(.system(size: 34, weight: .medium))
                        .tracking(-0.75)
                        .lineSpacing(2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(LZ.ink)
                    Text("A quiet weekly check-in.\nNo streaks. No judgment.")
                        .font(LZType.serifItalic(15.5))
                        .foregroundStyle(LZ.inkSoft)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(.horizontal, 32)
                Spacer()

                bottomCTA("Get started") { withAnimation { page = 1 } }
                    .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Step 2 — Zones

    private var zonesPage: some View {
        ZStack {
            LZ.paper.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                stepHeader(step: 2, title: "Seven areas.\nOne picture.",
                           body: "Each week you'll rate these. Over time they sketch the shape of your life.")

                Spacer(minLength: 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(ZoneRegistry.all.enumerated()), id: \.element.id) { i, def in
                            VStack(alignment: .leading, spacing: 0) {
                                Rectangle().fill(def.color).frame(height: 3)
                                VStack(alignment: .leading, spacing: 10) {
                                    ZoneGlyph(glyph: def.glyph, size: 22, stroke: 1.7)
                                        .foregroundStyle(def.color)
                                        .padding(.top, 14)
                                    Text(def.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .tracking(-0.07)
                                        .foregroundStyle(LZ.ink)
                                    Text(def.blurb)
                                        .font(.system(size: 11))
                                        .lineSpacing(1)
                                        .foregroundStyle(LZ.inkSoft)
                                }
                                .padding(.horizontal, 14)
                                .padding(.bottom, 14)
                            }
                            .frame(width: 138, alignment: .leading)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
                            .offset(y: i % 2 == 0 ? 0 : 22)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                }

                Spacer()

                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { i in
                        Capsule()
                            .fill(i == 0 ? LZ.tealDeep : LZ.rule)
                            .frame(width: i == 0 ? 16 : 5, height: 5)
                    }
                }
                .frame(maxWidth: .infinity)

                bottomCTA("Continue", secondary: "Skip") {
                    withAnimation { page = 2 }
                } onSecondary: {
                    withAnimation { page = 3 }
                }
                .padding(.bottom, 32)
                .padding(.top, 16)
            }
            .padding(.top, 56)
        }
    }

    // MARK: - Step 3 — Schedule

    private var schedulePage: some View {
        ZStack {
            LZ.paper.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                stepHeader(step: 3, title: "When should we\nremind you?",
                           body: "A Sunday evening ritual. Or whenever works for you.",
                           bodySerif: true)

                wheelPickers
                    .padding(.horizontal, 18)
                    .padding(.top, 24)

                quietHoursNote
                    .padding(.horizontal, 18)
                    .padding(.top, 20)

                Spacer()

                bottomCTA("Set reminder", secondary: "Back") {
                    if notificationsGranted {
                        Task {
                            await NotificationScheduler.shared.scheduleWeeklyReminder(
                                dayOfWeek: dayIndexMonFirstToSunZero(checkInDay),
                                hour: checkInHour
                            )
                        }
                    }
                    withAnimation { page = 3 }
                } onSecondary: {
                    withAnimation { page = 1 }
                }
                .padding(.bottom, 32)
            }
            .padding(.top, 56)
        }
        .task {
            notificationsGranted = await NotificationScheduler.shared.requestPermission()
        }
    }

    private var wheelPickers: some View {
        ZStack(alignment: .center) {
            // Selection band
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white)
                .frame(height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(LZ.rule, lineWidth: 0.5)
                )
                .padding(.horizontal, 12)

            HStack(spacing: 0) {
                LZWheel(items: ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"], selection: $checkInDay)
                LZWheel(items: hourLabels(), selectionIndex: Binding(
                    get: { hourLabels().firstIndex(of: hourLabel(checkInHour)) ?? 2 },
                    set: { checkInHour = 17 + $0 }
                ))
            }
            .frame(height: 192)
        }
        .background(LZ.cream)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var quietHoursNote: some View {
        HStack(alignment: .top, spacing: 10) {
            ZoneGlyph(glyph: .moon, size: 16, stroke: 1.6)
                .foregroundStyle(LZ.tealDeep)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text("One gentle nudge. Never more.")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(LZ.ink)
                Text("Skip a week and we'll keep quiet. Skip a month and we'll wait for you.")
                    .font(.system(size: 11.5))
                    .lineSpacing(1.5)
                    .foregroundStyle(LZ.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(LZ.cream)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Step 4 — First check-in

    private var firstCheckInPage: some View {
        ZStack {
            LZ.paper.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                stepHeader(step: 4, title: "Where are you\nright now?",
                           body: "Slide each line — gut feel is fine. Five seconds, not five minutes.",
                           bodySerif: true)

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(ZoneRegistry.all.enumerated()), id: \.element.id) { idx, def in
                            HStack(spacing: 12) {
                                ZoneGlyph(glyph: def.glyph, size: 18, stroke: 1.6)
                                    .foregroundStyle(def.color)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(def.name)
                                        .font(.system(size: 13.5, weight: .medium))
                                        .tracking(-0.07)
                                        .foregroundStyle(LZ.ink)
                                    CompactSlider(
                                        color: def.color,
                                        score: Binding(
                                            get: { scores[def.id] ?? 0 },
                                            set: { scores[def.id] = $0; rated.insert(def.id) }
                                        ),
                                        rated: rated.contains(def.id)
                                    )
                                    .frame(height: 14)
                                }
                                Text(rated.contains(def.id) ? "\(scores[def.id] ?? 0)" : "—")
                                    .font(.system(size: 16, weight: .light).monospacedDigit())
                                    .tracking(-0.32)
                                    .foregroundStyle(rated.contains(def.id) ? LZ.ink : LZ.inkMute)
                                    .frame(width: 42, alignment: .trailing)
                            }
                            .padding(.vertical, 14)

                            if idx != ZoneRegistry.all.count - 1 {
                                Rectangle().fill(LZ.ruleSoft).frame(height: 0.5)
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                }
                .padding(.top, 8)

                bottomCTA("Begin") { saveAndFinish() }
                    .padding(.bottom, 32)
                    .padding(.top, 8)
            }
            .padding(.top, 56)
        }
    }

    // MARK: - Shared header

    private func stepHeader(step: Int, title: String, body: String, bodySerif: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Step \(step) of 4").uppercaseCaption()
            Text(title)
                .font(.system(size: 28, weight: .medium))
                .tracking(-0.62)
                .lineSpacing(2)
                .foregroundStyle(LZ.ink)
                .padding(.top, 2)
            Text(body)
                .font(bodySerif ? LZType.serifItalic(14) : .system(size: 14))
                .lineSpacing(2)
                .foregroundStyle(LZ.inkSoft)
                .padding(.top, 2)
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Bottom CTA

    @ViewBuilder
    private func bottomCTA(
        _ title: String,
        secondary: String? = nil,
        action: @escaping () -> Void,
        onSecondary: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: 10) {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .tracking(-0.08)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LZ.tealDeep)
                    .foregroundStyle(LZ.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: LZ.tealDeep.opacity(0.22), radius: 12, x: 0, y: 4)
            }
            if let s = secondary {
                Button(action: { onSecondary?() }) {
                    Text(s)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(LZ.inkSoft)
                        .frame(height: 36)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private func hourLabels() -> [String] {
        ["5 pm", "6 pm", "7 pm", "8 pm", "9 pm", "10 pm", "11 pm"]
    }

    private func hourLabel(_ h: Int) -> String {
        let f = DateFormatter(); f.dateFormat = "h a"
        var c = DateComponents(); c.hour = h; c.minute = 0
        return Calendar.current.date(from: c).map { f.string(from: $0).lowercased() } ?? "\(h):00"
    }

    /// Convert "Mon-first index 0..6" to model's "Sun-zero 0..6"
    private func dayIndexMonFirstToSunZero(_ idx: Int) -> Int {
        // Mon=0 → Sun-zero=1, Tue=1 → 2, ... Sun=6 → 0
        (idx + 1) % 7
    }

    private func saveAndFinish() {
        let service = CheckInService(modelContext: modelContext)

        // Save first check-in
        let zoneScores: [ZoneID: Int] = Dictionary(uniqueKeysWithValues:
            ZoneID.allCases.map { ($0, scores[$0] ?? 5) }
        )
        _ = try? service.save(scores: zoneScores, tags: [:], notes: [:])

        // Preferences
        let prefs = UserPreferences()
        prefs.checkInDayOfWeek = dayIndexMonFirstToSunZero(checkInDay)
        prefs.checkInHour = checkInHour
        prefs.notificationsEnabled = notificationsGranted
        prefs.onboardingComplete = true
        modelContext.insert(prefs)
        try? modelContext.save()

        if notificationsGranted {
            Task {
                await NotificationScheduler.shared.scheduleWeeklyReminder(
                    dayOfWeek: prefs.checkInDayOfWeek, hour: checkInHour
                )
            }
        }
        onComplete()
    }
}

// MARK: - Animated radar (welcome page hero)

struct AnimatedRadar: View {
    var size: CGFloat = 232
    @State private var pulse: CGFloat = 0
    @State private var pulseRadius: CGFloat = 3
    @State private var pulseOpacity: Double = 1

    private let offsets: [CGFloat] = [0.78, 0.85, 0.72, 0.88, 0.80, 0.92, 0.74]

    var body: some View {
        ZStack {
            // Rings
            ForEach([0.4, 0.7, 1.0], id: \.self) { (t: Double) in
                IslandPolygon(offsets: Array(repeating: CGFloat(t), count: 7), radiusFactor: 0.36)
                    .stroke(
                        Color(hex: "#7E8C7A").opacity(0.4),
                        style: StrokeStyle(
                            lineWidth: t == 1.0 ? 1.0 : 0.6,
                            dash: t == 1.0 ? [] : [3, 4]
                        )
                    )
                    .frame(width: size, height: size)
            }

            // Axis spokes
            Canvas { ctx, _ in
                let cx = size / 2
                let cy = size / 2
                let R = size * 0.36
                for i in 0..<7 {
                    let a = -CGFloat.pi / 2 + (CGFloat(i) / 7) * .pi * 2
                    var p = Path()
                    p.move(to: CGPoint(x: cx, y: cy))
                    p.addLine(to: CGPoint(x: cx + cos(a) * R, y: cy + sin(a) * R))
                    ctx.stroke(p, with: .color(Color(hex: "#7E8C7A").opacity(0.25)), lineWidth: 0.6)
                }
            }
            .frame(width: size, height: size)

            // Polygon
            IslandPolygon(offsets: offsets, radiusFactor: 0.36)
                .fill(LZ.tealDeep.opacity(0.18 + pulse * 0.12))
                .frame(width: size, height: size)
            IslandPolygon(offsets: offsets, radiusFactor: 0.36)
                .stroke(LZ.tealDeep, lineWidth: 1.6)
                .frame(width: size, height: size)

            // Nodes
            Canvas { ctx, _ in
                let cx = size / 2
                let cy = size / 2
                let R = size * 0.36
                for (i, off) in offsets.enumerated() {
                    let a = -CGFloat.pi / 2 + (CGFloat(i) / 7) * .pi * 2
                    let pt = CGPoint(x: cx + cos(a) * R * off, y: cy + sin(a) * R * off)
                    let r: CGFloat = 4
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)),
                        with: .color(LZ.tealDeep)
                    )
                }
            }
            .frame(width: size, height: size)

            // Pulsing center
            Circle()
                .fill(LZ.tealDeep.opacity(pulseOpacity))
                .frame(width: pulseRadius * 2, height: pulseRadius * 2)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                pulse = 1.0
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                pulseRadius = 7
                pulseOpacity = 0.2
            }
        }
    }
}

// MARK: - LZWheel — wheel picker styled to match the design

struct LZWheel: View {
    let items: [String]
    @Binding var selectionIndex: Int

    init(items: [String], selection: Binding<Int>) {
        self.items = items
        self._selectionIndex = selection
    }
    init(items: [String], selectionIndex: Binding<Int>) {
        self.items = items
        self._selectionIndex = selectionIndex
    }

    var body: some View {
        Picker("", selection: $selectionIndex) {
            ForEach(0..<items.count, id: \.self) { i in
                Text(items[i])
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(LZ.ink)
                    .tag(i)
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
    }
}

// MARK: - CompactSlider for first check-in

struct CompactSlider: View {
    let color: Color
    @Binding var score: Int
    var rated: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let pct = CGFloat(score) / 10

            ZStack(alignment: .leading) {
                Capsule().fill(Color(hex: "#EFE7D2")).frame(height: 4)
                if rated {
                    Capsule().fill(color).frame(width: max(0, w * pct), height: 4)
                }
                if rated {
                    Circle()
                        .fill(Color.white)
                        .overlay(Circle().strokeBorder(color, lineWidth: 1.5))
                        .frame(width: 14, height: 14)
                        .position(x: max(7, min(w - 7, w * pct)), y: geo.size.height / 2)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { value in
                    let p = max(0, min(w, value.location.x))
                    let newVal = max(1, min(10, Int(round((p / w) * 10))))
                    if newVal != score { score = newVal }
                }
            )
        }
    }
}
