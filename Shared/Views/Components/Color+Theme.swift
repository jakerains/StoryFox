import AppKit
import SwiftUI

extension Color {
    // MARK: - StoryJuicer Theme — "Warm Library at Dusk" (Dynamic)

    static func sjDynamic(light: NSColor, dark: NSColor) -> Color {
        Color(
            nsColor: NSColor(name: nil) { appearance in
                let match = appearance.bestMatch(from: [.darkAqua, .aqua])
                return match == .darkAqua ? dark : light
            }
        )
    }

    /// Rich warm parchment background
    static let sjBackground = sjDynamic(light: .sjHex(0xF6EEDF), dark: .sjHex(0x16110D))

    /// Card surface — warm white with clear distinction from background
    static let sjCard = sjDynamic(light: .sjHex(0xFFF8EE), dark: .sjHex(0x241B15))

    /// Warm terracotta accent — primary action color
    static let sjCoral = sjDynamic(light: .sjHex(0xB4543A), dark: .sjHex(0xD98A73))

    /// Soft peach for highlights and selected states
    static let sjPeach = sjDynamic(light: .sjHex(0xE8B79A), dark: .sjHex(0x8D5C46))

    /// Warm lavender for variety
    static let sjLavender = sjDynamic(light: .sjHex(0x8A78A1), dark: .sjHex(0x5E4F78))

    /// Rich amber gold for decorative elements
    static let sjGold = sjDynamic(light: .sjHex(0xB78733), dark: .sjHex(0xD0A35F))

    /// Muted teal-green for success
    static let sjMint = sjDynamic(light: .sjHex(0x4F8C72), dark: .sjHex(0x73AB90))

    /// Muted sky for info states
    static let sjSky = sjDynamic(light: .sjHex(0x567DA8), dark: .sjHex(0x87A5C6))

    /// Deep ink for primary text — high contrast on parchment
    static let sjText = sjDynamic(light: .sjHex(0x1E1510), dark: .sjHex(0xF3E7D8))

    /// Warm brown for secondary text — tuned for stronger readability on glass
    static let sjSecondaryText = sjDynamic(light: .sjHex(0x47372D), dark: .sjHex(0xC8B29B))

    /// Muted border/divider color — visible but not harsh
    static let sjBorder = sjDynamic(light: .sjHex(0xCBB9A3), dark: .sjHex(0x4D3D31))

    /// Inactive/muted element color — softened but still readable
    static let sjMuted = sjDynamic(light: .sjHex(0x6B5A4C), dark: .sjHex(0x9B8775))

    /// Top tone for editorial paper-like backgrounds
    static let sjPaperTop = sjDynamic(light: .sjHex(0xFBF4E6), dark: .sjHex(0x211913))

    /// Bottom tone for editorial paper-like backgrounds
    static let sjPaperBottom = sjDynamic(light: .sjHex(0xE9DAC7), dark: .sjHex(0x19120D))

    /// High-contrast text color intended for tinted glass surfaces
    static let sjGlassInk = sjDynamic(light: .sjHex(0x120D09), dark: .sjHex(0xF7ECDC))

    /// Soft elevated glass tint for passive surfaces
    static let sjGlassSoft = sjDynamic(light: .sjHex(0xF6EBDD), dark: .sjHex(0x31251D))

    /// Very subtle neutral glass tint for secondary surfaces
    static let sjGlassWeak = sjDynamic(light: .sjHex(0xFDF7EC), dark: .sjHex(0x281E17))

    /// More opaque warm surface tint for text-heavy cards
    static let sjReadableCard = sjDynamic(light: .sjHex(0xFCF3E7), dark: .sjHex(0x2C211A))

    /// Highlight tone for accent glows and separators
    static let sjHighlight = sjDynamic(light: .sjHex(0xF9C38D), dark: .sjHex(0xA66A3F))
}

private extension NSColor {
    static func sjHex(_ value: Int) -> NSColor {
        NSColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension ShapeStyle where Self == Color {
    static var sjBackground: Color { .sjBackground }
    static var sjCoral: Color { .sjCoral }
    static var sjCard: Color { .sjCard }
    static var sjText: Color { .sjText }
    static var sjSecondaryText: Color { .sjSecondaryText }
    static var sjGlassInk: Color { .sjGlassInk }
    static var sjReadableCard: Color { .sjReadableCard }
}
