import SwiftUI

enum ZoneRegistry {
    static let all: [ZoneDefinition] = [
        .init(
            id: .vitality,
            name: "Vitality",
            iconName: "heart.fill",
            color: Color(hex: "#E24B4A"),
            tagline: "Energy, body, health",
            exampleTags: ["energized", "tired", "active", "unwell"]
        ),
        .init(
            id: .deepWork,
            name: "Deep Work",
            iconName: "brain",
            color: Color(hex: "#378ADD"),
            tagline: "Focus, productivity, craft",
            exampleTags: ["focused", "scattered", "creative", "blocked"]
        ),
        .init(
            id: .connection,
            name: "Connection",
            iconName: "person.2.fill",
            color: Color(hex: "#1D9E75"),
            tagline: "Relationships, belonging",
            exampleTags: ["connected", "lonely", "supported", "drained"]
        ),
        .init(
            id: .innerWorld,
            name: "Inner World",
            iconName: "moon.stars.fill",
            color: Color(hex: "#7F77DD"),
            tagline: "Emotions, clarity, peace",
            exampleTags: ["calm", "anxious", "clear", "turbulent"]
        ),
        .init(
            id: .creation,
            name: "Creation",
            iconName: "paintbrush.fill",
            color: Color(hex: "#D85A30"),
            tagline: "Making, expression, play",
            exampleTags: ["inspired", "stifled", "playful", "blocked"]
        ),
        .init(
            id: .foundation,
            name: "Foundation",
            iconName: "house.fill",
            color: Color(hex: "#BA7517"),
            tagline: "Stability, finances, routines",
            exampleTags: ["stable", "chaotic", "secure", "stressed"]
        ),
        .init(
            id: .growth,
            name: "Growth",
            iconName: "leaf.fill",
            color: Color(hex: "#639922"),
            tagline: "Learning, purpose, direction",
            exampleTags: ["growing", "stagnant", "curious", "purposeful"]
        )
    ]

    static func definition(for id: ZoneID) -> ZoneDefinition {
        all.first { $0.id == id } ?? all[0]
    }

    static func displayName(for id: ZoneID, preferences: UserPreferences?) -> String {
        preferences?.customZoneNames[id.rawValue] ?? definition(for: id).name
    }
}

// MARK: - Design System

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
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Anim {
        static let spring = Animation.spring(response: 0.5, dampingFraction: 0.7)
        static let sheet  = Animation.easeInOut(duration: 0.3)
        static let pulse  = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)
    }
}
