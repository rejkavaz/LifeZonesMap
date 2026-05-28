import UIKit
import SwiftUI

/// Catalog of selectable app icon variants. The names match the
/// CFBundleAlternateIcons keys in Info.plist (driven by project.yml).
enum AppIconVariant: String, CaseIterable, Identifiable {
    case `default` = "default"
    case sage      = "AppIcon-sage"
    case clay      = "AppIcon-clay"
    case ink       = "AppIcon-ink"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: return "Cream"
        case .sage:    return "Sage Coast"
        case .clay:    return "Clay Valley"
        case .ink:     return "Twilight Ridge"
        }
    }

    var previewBackground: Color {
        switch self {
        case .default: return Color(hex: "#F2EBDC")
        case .sage:    return Color(hex: "#E8E2CE")
        case .clay:    return Color(hex: "#EDDFC8")
        case .ink:     return Color(hex: "#2C3741")
        }
    }

    var previewForeground: Color {
        switch self {
        case .default: return LZ.tealDeep
        case .sage:    return LZ.zGrowth
        case .clay:    return Color(hex: "#A8754F")
        case .ink:     return Color(hex: "#7D8FA3")
        }
    }

    /// The name to pass to UIApplication.setAlternateIconName.
    /// `nil` selects the primary AppIcon.
    var alternateName: String? {
        self == .default ? nil : rawValue
    }
}

@MainActor
enum AlternateIconService {
    static var current: AppIconVariant {
        guard let name = UIApplication.shared.alternateIconName else { return .default }
        return AppIconVariant(rawValue: name) ?? .default
    }

    static var isSupported: Bool {
        UIApplication.shared.supportsAlternateIcons
    }

    static func apply(_ variant: AppIconVariant) async throws {
        guard isSupported else { return }
        try await UIApplication.shared.setAlternateIconName(variant.alternateName)
    }
}
