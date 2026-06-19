//
//  Theme.swift
//  HomeMeasure
//
//  Central design system: adaptive color palette, gradients and typography.
//  The palette is a "premium utility / blueprint" look — deep navy blueprint
//  backgrounds, faint cyan grid lines and contrasting safety-orange action
//  buttons. All colors are dynamic so they respond instantly to the
//  preferredColorScheme driven by AppSettings.
//

import SwiftUI

// MARK: - Color helpers

extension Color {
    /// Build a Color from a hex string ("#RRGGBB" or "RRGGBB" or with alpha "RRGGBBAA").
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r, g, b, a: Double
        switch cleaned.count {
        case 8:
            r = Double((value & 0xFF000000) >> 24) / 255.0
            g = Double((value & 0x00FF0000) >> 16) / 255.0
            b = Double((value & 0x0000FF00) >> 8) / 255.0
            a = Double(value & 0x000000FF) / 255.0
        default:
            r = Double((value & 0xFF0000) >> 16) / 255.0
            g = Double((value & 0x00FF00) >> 8) / 255.0
            b = Double(value & 0x0000FF) / 255.0
            a = 1.0
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// A color that adapts between light and dark appearance automatically.
    static func adaptive(light: String, dark: String) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
    }
}

// MARK: - Theme

/// Namespace for all design tokens used across the app.
enum Theme {

    // Backgrounds --------------------------------------------------------
    /// App canvas (the blueprint base).
    static let bg = Color.adaptive(light: "EAF1F8", dark: "081826")
    /// Slightly deeper canvas used behind scroll content.
    static let bgDeep = Color.adaptive(light: "DCE7F2", dark: "06121E")
    /// Elevated card / sheet surface.
    static let surface = Color.adaptive(light: "FFFFFF", dark: "10273C")
    /// Surface used for nested rows / inputs.
    static let surfaceAlt = Color.adaptive(light: "F2F6FB", dark: "16314A")

    // Blueprint lines ----------------------------------------------------
    static let blueprintLine = Color.adaptive(light: "9CB8D6", dark: "1E4A6E")
    static let blueprintLineStrong = Color.adaptive(light: "6E96BE", dark: "2C699B")

    // Text ---------------------------------------------------------------
    static let textPrimary = Color.adaptive(light: "0F2740", dark: "EAF3FB")
    static let textSecondary = Color.adaptive(light: "557089", dark: "9FBBD4")
    static let textMuted = Color.adaptive(light: "8AA1B8", dark: "6E8BA6")

    // Strokes / dividers -------------------------------------------------
    static let stroke = Color.adaptive(light: "D5E1EE", dark: "1C3A56")
    static let strokeStrong = Color.adaptive(light: "B9CCE0", dark: "2A4D6E")

    // Brand accents ------------------------------------------------------
    /// Primary action — safety orange.
    static let accent = Color(hex: "FF7A1A")
    static let accentDeep = Color(hex: "F2570B")
    /// Secondary accent — blueprint teal/blue.
    static let teal = Color(hex: "16C0C8")
    static let blue = Color(hex: "2E8BE6")

    // Status colors ------------------------------------------------------
    static let success = Color(hex: "29C281")
    static let warning = Color(hex: "F7B500")
    static let danger = Color(hex: "F5455C")
    static let info = Color(hex: "3DA0FF")
    static let purple = Color(hex: "8A6CF0")

    // Gradients ----------------------------------------------------------
    static let actionGradient = LinearGradient(
        colors: [Color(hex: "FF9A3D"), Color(hex: "F2570B")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let accentGradient = LinearGradient(
        colors: [Color(hex: "29D3DA"), Color(hex: "2E8BE6")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let blueprintGradient = LinearGradient(
        colors: [Color(hex: "0B2238"), Color(hex: "081826")],
        startPoint: .top, endPoint: .bottom)

    static func gradient(_ a: String, _ b: String) -> LinearGradient {
        LinearGradient(colors: [Color(hex: a), Color(hex: b)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Typography

extension Font {
    static func appTitle(_ size: CGFloat = 28) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func appHeadline(_ size: CGFloat = 18) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func appBody(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func appNumber(_ size: CGFloat = 22) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static func appCaption(_ size: CGFloat = 12) -> Font { .system(size: size, weight: .medium, design: .rounded) }
}

// MARK: - Spacing / radius tokens

enum Metrics {
    static let radius: CGFloat = 18
    static let radiusSmall: CGFloat = 12
    static let pad: CGFloat = 16
}
