import AppKit
import SwiftUI

/// Helper button that opens the provider's token settings page in the browser.
/// Shown in the HuggingFace settings section to help users get their API token.
struct CloudProviderTokenHelper: View {
    let provider: CloudProvider

    var body: some View {
        HStack(spacing: StoryJuicerGlassTokens.Spacing.medium) {
            if let url = provider.tokenSettingsURL {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Label("Get \(provider.displayName) Token", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.glass)
            }

            Text("Create a token at \(provider.displayName), then paste it above.")
                .font(StoryJuicerTypography.settingsMeta)
                .foregroundStyle(Color.sjSecondaryText)
        }
    }
}
