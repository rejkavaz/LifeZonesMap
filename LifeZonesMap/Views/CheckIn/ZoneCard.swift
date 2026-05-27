import SwiftUI

struct ZoneCard: View {
    let definition: ZoneDefinition
    @Binding var score: Int
    @Binding var selectedTag: String?
    @Binding var note: String
    var hapticsEnabled: Bool = true
    var rated: Bool = false   // false → show "—" until user moves slider

    @State private var noteExpanded = false
    @FocusState private var noteFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Card surface
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)

            // Left color bar
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 16,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
            .fill(definition.color)
            .frame(width: 4)

            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .firstTextBaseline) {
                    HStack(spacing: 10) {
                        ZoneGlyph(glyph: definition.glyph, size: 18, stroke: 1.6)
                            .foregroundStyle(definition.color)
                        Text(definition.name)
                            .font(.system(size: 15, weight: .medium))
                            .tracking(-0.075)
                            .foregroundStyle(LZ.ink)
                    }
                    Spacer()
                    Text(rated ? String(format: "%.1f", Double(score)) : "—")
                        .font(.system(size: 30, weight: .light).monospacedDigit())
                        .tracking(-0.75)
                        .foregroundStyle(rated ? LZ.ink : LZ.inkMute)
                        .opacity(rated ? 1.0 : 0.4)
                }

                // Slider
                LZSlider(
                    color: definition.color,
                    score: $score,
                    rated: rated,
                    hapticsEnabled: hapticsEnabled
                )
                .frame(height: 22)

                // Tag pills (wrap)
                FlowLayout(spacing: 6) {
                    ForEach(definition.exampleTags, id: \.self) { tag in
                        TagPill(
                            label: tag,
                            isSelected: selectedTag == tag,
                            color: definition.color
                        ) {
                            withAnimation(DS.Anim.sheet) {
                                selectedTag = (selectedTag == tag) ? nil : tag
                            }
                        }
                    }
                }

                // Note
                if noteExpanded || !note.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Note").uppercaseCaption(size: 9, tracking: 1.8)
                        TextField("Walked twice this week…", text: $note, axis: .vertical)
                            .font(LZType.serifItalic(13))
                            .foregroundStyle(LZ.inkSoft)
                            .focused($noteFocused)
                            .lineLimit(2...4)
                            .onChange(of: note) {
                                if note.count > 120 { note = String(note.prefix(120)) }
                            }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(LZ.cream)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    Button {
                        noteExpanded = true
                        noteFocused = true
                    } label: {
                        HStack(spacing: 6) {
                            ZoneGlyph(glyph: .pen, size: 13, stroke: 2.0)
                            Text("Add a note")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(LZ.inkMute)
                    }
                }
            }
            .padding(.leading, 18)
            .padding(.trailing, 16)
            .padding(.vertical, 14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Slider with custom track, fill, tick marks, and thumb

struct LZSlider: View {
    let color: Color
    @Binding var score: Int
    var rated: Bool
    var hapticsEnabled: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pct = CGFloat(score) / 10

            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color(hex: "#EFE7D2"))
                    .frame(height: 6)

                // Fill
                if rated {
                    Capsule()
                        .fill(color)
                        .frame(width: max(0, w * pct), height: 6)
                }

                // Tick marks at 0, 0.25, 0.5, 0.75, 1.0
                ForEach(0..<5, id: \.self) { i in
                    let t = CGFloat(i) / 4
                    let isEnd = (i == 0 || i == 4)
                    Circle()
                        .fill(isEnd ? LZ.inkMute : Color(hex: "#C9BFA6"))
                        .frame(width: 2, height: 2)
                        .opacity(0.6)
                        .position(x: max(1, w * t), y: h / 2)
                }

                // Thumb
                if rated {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 22, height: 22)
                            .overlay(Circle().strokeBorder(color, lineWidth: 1.5))
                            .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 2)
                        Circle().fill(color).frame(width: 6, height: 6)
                    }
                    .position(x: max(11, min(w - 11, w * pct)), y: h / 2)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let p = max(0, min(w, value.location.x))
                        let newVal = max(1, min(10, Int(round((p / w) * 10))))
                        if newVal != score {
                            score = newVal
                            if hapticsEnabled {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    }
            )
        }
    }
}

// MARK: - Tag pill

struct TagPill: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11.5, weight: isSelected ? .semibold : .medium))
                .tracking(0.1)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(isSelected ? color.opacity(0.12) : Color.clear)
                )
                .overlay(
                    Capsule().strokeBorder(
                        isSelected ? color : LZ.rule,
                        lineWidth: 0.5
                    )
                )
                .foregroundStyle(isSelected ? color : LZ.inkSoft)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FlowLayout (wraps tags onto multiple lines)

struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let w = proposal.width ?? 320
        var x: CGFloat = 0, y: CGFloat = 0, maxH: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > w && x > 0 {
                x = 0; y += maxH + lineSpacing; maxH = 0
            }
            x += s.width + spacing
            maxH = max(maxH, s.height)
        }
        return CGSize(width: w, height: y + maxH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX, y = bounds.minY, maxH: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX; y += maxH + lineSpacing; maxH = 0
            }
            sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            maxH = max(maxH, s.height)
        }
    }
}
