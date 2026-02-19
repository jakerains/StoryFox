import SwiftUI

struct StylePickerItem: View {
    let style: IllustrationStyle
    let isSelected: Bool

    var body: some View {
        VStack(spacing: StoryJuicerGlassTokens.Spacing.xSmall) {
            Image(systemName: style.iconName)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? Color.sjCoral : Color.sjSecondaryText)
                .frame(width: 48, height: 48)
                .background(iconBackground, in: .rect(cornerRadius: StoryJuicerGlassTokens.Radius.chip))
                .overlay {
                    RoundedRectangle(cornerRadius: StoryJuicerGlassTokens.Radius.chip)
                        .strokeBorder(
                            isSelected ? Color.sjCoral.opacity(0.82) : Color.sjBorder.opacity(0.62),
                            lineWidth: isSelected ? 1.6 : 1
                        )
                }

            Text(style.displayName)
                .font(StoryJuicerTypography.settingsMeta.weight(isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? Color.sjCoral : Color.sjText)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
        .shadow(color: isSelected ? Color.sjCoral.opacity(0.15) : .clear, radius: 6, y: 3)
        .animation(StoryJuicerMotion.standard, value: isSelected)
    }

    private var iconBackground: LinearGradient {
        if isSelected {
            return LinearGradient(
                colors: [
                    Color.sjCoral.opacity(0.2),
                    Color.sjHighlight.opacity(0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color.sjReadableCard.opacity(0.88),
                Color.sjCard.opacity(0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
