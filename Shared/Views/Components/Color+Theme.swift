import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Color {
    // MARK: - StoryJuicer Theme — "Warm Library at Dusk" (Dynamic)

    static func sjDynamic(light: Int, dark: Int) -> Color {
#if os(macOS)
        Color(
            nsColor: NSColor(name: nil) { appearance in
                let match = appearance.bestMatch(from: [.darkAqua, .aqua])
                return match == .darkAqua ? NSColor.sjHex(dark) : NSColor.sjHex(light)
            }
        )
#else
        Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? UIColor.sjHex(dark) : UIColor.sjHex(light)
            }
        )
#endif
    }

    /// Rich warm parchment background
    static let sjBackground = sjDynamic(light: 0xF6EEDF, dark: 0x16110D)

    /// Card surface — warm white with clear distinction from background
    static let sjCard = sjDynamic(light: 0xFFF8EE, dark: 0x241B15)

    /// Warm terracotta accent — primary action color
    static let sjCoral = sjDynamic(light: 0xB4543A, dark: 0xD98A73)

    /// Soft peach for highlights and selected states
    static let sjPeach = sjDynamic(light: 0xE8B79A, dark: 0x8D5C46)

    /// Warm lavender for variety
    static let sjLavender = sjDynamic(light: 0x8A78A1, dark: 0x5E4F78)

    /// Rich amber gold for decorative elements
    static let sjGold = sjDynamic(light: 0xB78733, dark: 0xD0A35F)

    /// Muted teal-green for success
    static let sjMint = sjDynamic(light: 0x4F8C72, dark: 0x73AB90)

    /// Muted sky for info states
    static let sjSky = sjDynamic(light: 0x567DA8, dark: 0x87A5C6)

    /// Deep ink for primary text — high contrast on parchment
    static let sjText = sjDynamic(light: 0x1E1510, dark: 0xF3E7D8)

    /// Warm brown for secondary text — tuned for stronger readability on glass
    static let sjSecondaryText = sjDynamic(light: 0x47372D, dark: 0xC8B29B)

    /// Muted border/divider color — visible but not harsh
    static let sjBorder = sjDynamic(light: 0xCBB9A3, dark: 0x4D3D31)

    /// Inactive/muted element color — softened but still readable
    static let sjMuted = sjDynamic(light: 0x6B5A4C, dark: 0x9B8775)

    /// Top tone for editorial paper-like backgrounds
    static let sjPaperTop = sjDynamic(light: 0xFBF4E6, dark: 0x211913)

    /// Bottom tone for editorial paper-like backgrounds
    static let sjPaperBottom = sjDynamic(light: 0xE9DAC7, dark: 0x19120D)

    /// High-contrast text color intended for tinted glass surfaces
    static let sjGlassInk = sjDynamic(light: 0x120D09, dark: 0xF7ECDC)

    /// Soft elevated glass tint for passive surfaces
    static let sjGlassSoft = sjDynamic(light: 0xF6EBDD, dark: 0x31251D)

    /// Very subtle neutral glass tint for secondary surfaces
    static let sjGlassWeak = sjDynamic(light: 0xFDF7EC, dark: 0x281E17)

    /// More opaque warm surface tint for text-heavy cards
    static let sjReadableCard = sjDynamic(light: 0xFCF3E7, dark: 0x2C211A)

    /// Highlight tone for accent glows and separators
    static let sjHighlight = sjDynamic(light: 0xF9C38D, dark: 0xA66A3F)
}

#if os(macOS)
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
#else
private extension UIColor {
    static func sjHex(_ value: Int) -> UIColor {
        UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}
#endif

extension ShapeStyle where Self == Color {
    static var sjBackground: Color { .sjBackground }
    static var sjCoral: Color { .sjCoral }
    static var sjCard: Color { .sjCard }
    static var sjText: Color { .sjText }
    static var sjSecondaryText: Color { .sjSecondaryText }
    static var sjGlassInk: Color { .sjGlassInk }
    static var sjReadableCard: Color { .sjReadableCard }
}
