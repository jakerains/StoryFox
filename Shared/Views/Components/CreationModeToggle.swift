import SwiftUI

struct CreationModeToggle: View {
    @Binding var selection: CreationMode

    var body: some View {
        HStack(spacing: StoryJuicerGlassTokens.Spacing.small) {
            ForEach(CreationMode.allCases) { mode in
                modeChip(mode)
            }
        }
    }

    private func modeChip(_ mode: CreationMode) -> some View {
        let isSelected = selection == mode

        return Button {
            withAnimation(StoryJuicerMotion.standard) {
                selection = mode
            }
        } label: {
            HStack(spacing: StoryJuicerGlassTokens.Spacing.xSmall) {
                Image(systemName: mode.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.sjCoral : .sjSecondaryText)

                VStack(alignment: .leading, spacing: 1) {
                    Text(mode.displayName)
                        .font(StoryJuicerTypography.uiMetaStrong)
                        .foregroundStyle(isSelected ? Color.sjGlassInk : .sjSecondaryText)

                    Text(mode.subtitle)
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.sjSecondaryText)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, StoryJuicerGlassTokens.Spacing.medium)
            .padding(.vertical, StoryJuicerGlassTokens.Spacing.small)
            .sjGlassChip(selected: isSelected, interactive: true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.displayName) creation mode")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
