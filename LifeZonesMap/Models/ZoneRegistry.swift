import SwiftUI

// Glyph identifiers — drawn as custom Shapes (see ZoneGlyph.swift)
enum ZoneGlyphID: String {
    case spark, focus, people, moon, pen, house, leaf
}

extension ZoneDefinition {
    var glyph: ZoneGlyphID {
        switch id {
        case .vitality:   return .spark
        case .deepWork:   return .focus
        case .connection: return .people
        case .innerWorld: return .moon
        case .creation:   return .pen
        case .foundation: return .house
        case .growth:     return .leaf
        }
    }
    /// Short blurb used on Map list rows and Onboarding cards
    var blurb: String {
        switch id {
        case .vitality:   return "Body, sleep, energy"
        case .deepWork:   return "Focus, craft, output"
        case .connection: return "People you love"
        case .innerWorld: return "Mind, mood, meaning"
        case .creation:   return "Make something new"
        case .foundation: return "Money, home, admin"
        case .growth:     return "Learn, stretch, change"
        }
    }
}

enum ZoneRegistry {
    static let all: [ZoneDefinition] = [
        .init(
            id: .vitality,
            name: "Vitality",
            iconName: "heart.fill",
            color: LZ.zVitality,
            tagline: "Body, sleep, energy",
            exampleTags: ["Slept well", "Moved", "Foggy", "Wired"]
        ),
        .init(
            id: .deepWork,
            name: "Deep Work",
            iconName: "brain",
            color: LZ.zDeepWork,
            tagline: "Focus, craft, output",
            exampleTags: ["In flow", "Shipped", "Distracted", "Stuck"]
        ),
        .init(
            id: .connection,
            name: "Connection",
            iconName: "person.2.fill",
            color: LZ.zConnect,
            tagline: "People you love",
            exampleTags: ["Saw friends", "Called family", "Lonely", "Drained"]
        ),
        .init(
            id: .innerWorld,
            name: "Inner World",
            iconName: "moon.stars.fill",
            color: LZ.zInner,
            tagline: "Mind, mood, meaning",
            exampleTags: ["Steady", "Anxious", "Curious", "Tender"]
        ),
        .init(
            id: .creation,
            name: "Creation",
            iconName: "paintbrush.fill",
            color: LZ.zCreate,
            tagline: "Make something new",
            exampleTags: ["Made things", "Stalled", "Inspired", "Quiet"]
        ),
        .init(
            id: .foundation,
            name: "Foundation",
            iconName: "house.fill",
            color: LZ.zFound,
            tagline: "Money, home, admin",
            exampleTags: ["On top", "Tidy", "Behind", "Worried"]
        ),
        .init(
            id: .growth,
            name: "Growth",
            iconName: "leaf.fill",
            color: LZ.zGrowth,
            tagline: "Learn, stretch, change",
            exampleTags: ["Learning", "Stretching", "Coasting", "Drifting"]
        )
    ]

    static func definition(for id: ZoneID) -> ZoneDefinition {
        all.first { $0.id == id } ?? all[0]
    }

    static func displayName(for id: ZoneID, preferences: UserPreferences?) -> String {
        preferences?.customZoneNames[id.rawValue] ?? definition(for: id).name
    }
}

// MARK: - Design System constants (kept lightweight; LZ + LZType in Theme.swift)

enum DS {
    enum Spacing {
        static let s4: CGFloat = 4
        static let s8: CGFloat = 8
        static let s12: CGFloat = 12
        static let s16: CGFloat = 16
        static let s24: CGFloat = 24
        static let s32: CGFloat = 32
        static let s48: CGFloat = 48
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 14   // cards
        static let xl: CGFloat = 18   // canvas card
        static let xxl: CGFloat = 22  // widget
    }

    enum Anim {
        static let spring = Animation.spring(response: 0.5, dampingFraction: 0.7)
        static let sheet  = Animation.easeInOut(duration: 0.3)
        static let pulse  = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)
    }
}
