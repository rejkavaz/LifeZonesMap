import SwiftUI

// MARK: - LZ color tokens (from design system)
// Source: design/life-zones/project/shared.jsx

enum LZ {
    // Surfaces
    static let cream      = Color(hex: "#F2EBDC")
    static let creamSoft  = Color(hex: "#EFE7D5")
    static let paper      = Color(hex: "#FAF6EB")
    static let ink        = Color(hex: "#262320")
    static let inkSoft    = Color(hex: "#5B554A")
    static let inkMute    = Color(hex: "#9A9182")
    static let rule       = Color(hex: "#D8CFBC")
    static let ruleSoft   = Color(hex: "#E6DEC9")
    // Brand
    static let teal       = Color(hex: "#1D9E75")
    static let tealDeep   = Color(hex: "#15795A")
    // Zone signature colors (muted, earthy)
    static let zVitality  = Color(hex: "#BE5A45")   // terracotta red
    static let zDeepWork  = Color(hex: "#3C6E91")   // ink blue
    static let zConnect   = Color(hex: "#2D9474")   // moss teal
    static let zInner     = Color(hex: "#6E5B8A")   // dusky violet
    static let zCreate    = Color(hex: "#CC8A4A")   // burnt orange
    static let zFound     = Color(hex: "#B6913E")   // amber ochre
    static let zGrowth    = Color(hex: "#5E8C5A")   // forest green
}

// MARK: - Typography

enum LZType {
    // Display – section heads, large numbers (headings)
    static func display(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
    static func heading(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
    static func body(_ size: CGFloat = 14, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        // Tabular numerals look — used for scores
        .system(size: size, weight: weight, design: .default).monospacedDigit()
    }
    // Caption – ALL CAPS labels, tracked +0.22em
    static func caption(_ size: CGFloat = 11, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    // Serif italic – quotes, notes, "field guide" voice
    static func serifItalic(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular, design: .serif).italic()
    }
    static func serif(_ size: CGFloat = 13, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

// MARK: - View modifier — uppercase caption text (eyebrow / kicker)

struct UppercaseCaption: ViewModifier {
    var color: Color = LZ.inkMute
    var size: CGFloat = 11
    var tracking: CGFloat = 2.4  // ~0.22em at 11pt

    func body(content: Content) -> some View {
        content
            .font(LZType.caption(size))
            .textCase(.uppercase)
            .tracking(tracking)
            .foregroundStyle(color)
    }
}

extension View {
    func uppercaseCaption(
        color: Color = LZ.inkMute,
        size: CGFloat = 11,
        tracking: CGFloat = 2.4
    ) -> some View {
        modifier(UppercaseCaption(color: color, size: size, tracking: tracking))
    }
}

// MARK: - Section divider used across screens

struct SectionTitle: View {
    let text: String
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(text)
                .uppercaseCaption()
            Rectangle()
                .fill(LZ.ruleSoft)
                .frame(height: 0.5)
        }
        .padding(.top, 22)
        .padding(.bottom, 10)
    }
}
