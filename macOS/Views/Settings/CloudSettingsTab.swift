import SwiftUI

struct CloudSettingsTab: View {
    @Binding var settings: ModelSelectionSettings
    @Bindable var modelCache: CloudModelListCache
    @State private var isOpenRouterExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: StoryJuicerGlassTokens.Spacing.xLarge) {
            huggingFaceCallout

            CloudProviderSettingsSection(
                provider: .huggingFace,
                settings: $settings,
                modelCache: modelCache
            )

            // OpenRouter (Advanced — collapsed by default)
            SettingsPanelCard {
                Button {
                    withAnimation(StoryJuicerMotion.fast) {
                        isOpenRouterExpanded.toggle()
                    }
                } label: {
                    HStack(alignment: .top, spacing: StoryJuicerGlassTokens.Spacing.small) {
                        SettingsSectionHeader(
                            title: "OpenRouter",
                            subtitle: "Advanced — bring your own API key for access to hundreds of models.",
                            customImage: "OpenRouterLogo"
                        )

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.sjMuted)
                            .rotationEffect(.degrees(isOpenRouterExpanded ? 90 : 0))
                            .padding(.top, 6)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isOpenRouterExpanded {
                    CloudProviderSettingsSection(
                        provider: .openRouter,
                        settings: $settings,
                        modelCache: modelCache,
                        bare: true
                    )
                    .padding(.top, StoryJuicerGlassTokens.Spacing.small)
                }
            }
        }
    }

    // MARK: - Hugging Face Callout

    private var huggingFaceCallout: some View {
        HStack(alignment: .top, spacing: StoryJuicerGlassTokens.Spacing.medium) {
            Image(systemName: "gift.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.sjCoral)
                .frame(width: 36, height: 36)
                .background(Color.sjCoral.opacity(0.12), in: .rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text("Hugging Face — Free Cloud AI")
                    .font(StoryJuicerTypography.settingsBody.weight(.semibold))
                    .foregroundStyle(Color.sjText)

                Text("Create a free Hugging Face account to generate stories and illustrations in the cloud — no credit card needed. Sign in below or paste an API token.")
                    .font(StoryJuicerTypography.settingsMeta)
                    .foregroundStyle(Color.sjSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Link(destination: URL(string: "https://huggingface.co/join")!) {
                    HStack(spacing: 4) {
                        Text("Create a free account")
                            .font(StoryJuicerTypography.settingsMeta.weight(.medium))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(Color.sjCoral)
                }
            }
        }
        .padding(StoryJuicerGlassTokens.Spacing.medium)
        .background(Color.sjCoral.opacity(0.06), in: .rect(cornerRadius: StoryJuicerGlassTokens.Radius.hero))
        .overlay {
            RoundedRectangle(cornerRadius: StoryJuicerGlassTokens.Radius.hero)
                .strokeBorder(Color.sjCoral.opacity(0.25), lineWidth: 1)
        }
    }
}
