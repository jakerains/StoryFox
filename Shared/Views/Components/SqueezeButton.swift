import SwiftUI

struct SqueezeButton: View {
    var title: String = "Squeeze a Story"
    var subtitle: String = "Generate text + illustrations"
    var icon: String = "wand.and.stars"
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: StoryJuicerGlassTokens.Spacing.small) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(StoryJuicerTypography.uiTitle)
                    Text(subtitle)
                        .font(StoryJuicerTypography.uiMeta)
                        .foregroundStyle(Color.sjSecondaryText)
                }

                Spacer(minLength: StoryJuicerGlassTokens.Spacing.small)

                Image(systemName: "arrow.right")
                    .font(.body.weight(.bold))
                    .foregroundStyle(Color.sjCoral)
            }
            .foregroundStyle(isEnabled ? Color.sjGlassInk : Color.sjMuted)
            .padding(.horizontal, StoryJuicerGlassTokens.Spacing.large)
            .padding(.vertical, StoryJuicerGlassTokens.Spacing.medium)
            .sjGlassCard(
                tint: isEnabled
                    ? .sjCoral.opacity(StoryJuicerGlassTokens.Tint.standard)
                    : .sjGlassWeak,
                interactive: true,
                cornerRadius: 999
            )
            .overlay {
                Capsule()
                    .strokeBorder(
                        isEnabled ? Color.sjHighlight.opacity(0.7) : Color.sjBorder.opacity(0.7),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: StoryJuicerGlassTokens.Shadow.color,
                radius: StoryJuicerGlassTokens.Shadow.radius,
                y: StoryJuicerGlassTokens.Shadow.y
            )
            .contentShape(Capsule())
            .scaleEffect(isEnabled ? 1 : 0.985)
            .animation(StoryJuicerMotion.fast, value: isEnabled)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityHint("Generates the story and its illustrations")
    }
}
