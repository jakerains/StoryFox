import SwiftUI

struct SettingsPanelCard<Content: View>: View {
    private let tint: Color
    private let content: Content

    init(
        tint: Color = .sjGlassSoft.opacity(StoryJuicerGlassTokens.Tint.subtle),
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StoryJuicerGlassTokens.Spacing.medium) {
            content
        }
        .padding(StoryJuicerGlassTokens.Spacing.large)
        .sjGlassCard(
            tint: tint,
            cornerRadius: StoryJuicerGlassTokens.Radius.hero
        )
        .overlay {
            RoundedRectangle(cornerRadius: StoryJuicerGlassTokens.Radius.hero)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.sjBorder.opacity(0.95),
                            Color.sjHighlight.opacity(0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 6)
    }
}

struct SettingsSectionHeader: View {
    let title: String
    let subtitle: String?
    let systemImage: String?

    init(title: String, subtitle: String? = nil, systemImage: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(alignment: .top, spacing: StoryJuicerGlassTokens.Spacing.small) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.sjCoral)
                    .frame(width: 26, height: 26)
                    .background(Color.sjCoral.opacity(0.12), in: .circle)
                    .overlay {
                        Circle()
                            .strokeBorder(Color.sjCoral.opacity(0.35), lineWidth: 1)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(StoryJuicerTypography.settingsSectionTitle)
                    .foregroundStyle(Color.sjGlassInk)

                if let subtitle {
                    Text(subtitle)
                        .font(StoryJuicerTypography.settingsMeta)
                        .foregroundStyle(Color.sjSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct SettingsControlRow<Control: View>: View {
    let title: String
    let description: String?
    private let control: () -> Control

    init(
        title: String,
        description: String? = nil,
        @ViewBuilder control: @escaping () -> Control
    ) {
        self.title = title
        self.description = description
        self.control = control
    }

    var body: some View {
        HStack(alignment: .top, spacing: StoryJuicerGlassTokens.Spacing.medium) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(StoryJuicerTypography.settingsBody.weight(.semibold))
                    .foregroundStyle(Color.sjText)

                if let description {
                    Text(description)
                        .font(StoryJuicerTypography.settingsMeta)
                        .foregroundStyle(Color.sjSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: StoryJuicerGlassTokens.Spacing.medium)

            control()
                .font(StoryJuicerTypography.settingsControl)
                .foregroundStyle(Color.sjText)
        }
        .padding(.vertical, StoryJuicerGlassTokens.Spacing.xSmall)
    }
}

private struct SettingsFieldChromeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(StoryJuicerTypography.settingsControl)
            .foregroundStyle(Color.sjText)
            .padding(.horizontal, StoryJuicerGlassTokens.Spacing.small + 2)
            .padding(.vertical, StoryJuicerGlassTokens.Spacing.xSmall + 2)
            .background(
                RoundedRectangle(cornerRadius: StoryJuicerGlassTokens.Radius.input)
                    .fill(Color.sjReadableCard.opacity(0.88))
            )
            .overlay {
                RoundedRectangle(cornerRadius: StoryJuicerGlassTokens.Radius.input)
                    .strokeBorder(Color.sjBorder.opacity(0.8), lineWidth: 1)
            }
            .tint(.sjCoral)
    }
}

extension View {
    func settingsFieldChrome() -> some View {
        modifier(SettingsFieldChromeModifier())
    }
}
