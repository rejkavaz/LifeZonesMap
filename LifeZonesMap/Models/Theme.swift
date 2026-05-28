import SwiftUI
import UIKit

// MARK: - Dynamic color helper

extension Color {
    /// Resolves to one of two hex values based on the current trait collection.
    /// Lets the whole LZ palette respond to system Light/Dark mode without
    /// every callsite having to check colorScheme.
    static func dynamic(light: String, dark: String) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
    }
}

// MARK: - LZ color tokens (light + dark)
// Light source: design/life-zones/project/shared.jsx
// Dark inversion: warm-ink backgrounds, cream text, slightly lifted zone hues
//   so they still feel of the same family in either mode.

enum LZ {
    // Surfaces
    static let cream      = Color.dynamic(light: "#F2EBDC", dark: "#16140F")
    static let creamSoft  = Color.dynamic(light: "#EFE7D5", dark: "#1B1814")
    static let paper      = Color.dynamic(light: "#FAF6EB", dark: "#1F1C17")
    // Text — inverted in dark
    static let ink        = Color.dynamic(light: "#262320", dark: "#F0E9D7")
    static let inkSoft    = Color.dynamic(light: "#5B554A", dark: "#B8B0A0")
    static let inkMute    = Color.dynamic(light: "#9A9182", dark: "#7C7568")
    // Rules / borders
    static let rule       = Color.dynamic(light: "#D8CFBC", dark: "#3A352E")
    static let ruleSoft   = Color.dynamic(light: "#E6DEC9", dark: "#2D2924")
    // Brand teal — slightly more luminous in dark
    static let teal       = Color.dynamic(light: "#1D9E75", dark: "#2DBA8C")
    static let tealDeep   = Color.dynamic(light: "#15795A", dark: "#22A37A")
    // Zone signature colors (muted, earthy)
    static let zVitality  = Color.dynamic(light: "#BE5A45", dark: "#DE7058")
    static let zDeepWork  = Color.dynamic(light: "#3C6E91", dark: "#5E94BB")
    static let zConnect   = Color.dynamic(light: "#2D9474", dark: "#43B68F")
    static let zInner     = Color.dynamic(light: "#6E5B8A", dark: "#9582AE")
    static let zCreate    = Color.dynamic(light: "#CC8A4A", dark: "#E2A164")
    static let zFound     = Color.dynamic(light: "#B6913E", dark: "#D1AC58")
    static let zGrowth    = Color.dynamic(light: "#5E8C5A", dark: "#7DB078")
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
