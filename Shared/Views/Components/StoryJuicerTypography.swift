import SwiftUI

enum StoryJuicerTypography {
    // Serif display hierarchy for story identity
    static let brandHero = Font.system(size: 42, weight: .bold, design: .serif)
    static let sectionHero = Font.system(size: 34, weight: .bold, design: .serif)
    static let readerTitle = Font.system(size: 40, weight: .bold, design: .serif)
    static let readerBody = Font.system(size: 24, weight: .regular, design: .serif)

    // Rounded control/content hierarchy for legibility in glass UI
    static let uiTitle = Font.system(.title3, design: .rounded).weight(.semibold)
    static let uiBody = Font.system(.body, design: .rounded)
    static let uiBodyStrong = Font.system(.body, design: .rounded).weight(.medium)
    static let uiMeta = Font.system(.callout, design: .rounded)
    static let uiMetaStrong = Font.system(.callout, design: .rounded).weight(.semibold)
    static let uiFootnoteStrong = Font.system(.footnote, design: .rounded).weight(.semibold)

    // Settings hierarchy for polished readability in dense control panels
    static let settingsHero = Font.system(size: 30, weight: .semibold, design: .serif)
    static let settingsSectionTitle = Font.system(size: 19, weight: .semibold, design: .rounded)
    static let settingsBody = Font.system(size: 15, weight: .regular, design: .rounded)
    static let settingsControl = Font.system(size: 15, weight: .medium, design: .rounded)
    static let settingsMeta = Font.system(size: 13, weight: .regular, design: .rounded)
}
