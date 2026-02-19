import SwiftUI

struct FormatPreviewCard: View {
    let format: BookFormat
    let isSelected: Bool

    var body: some View {
        VStack(spacing: StoryJuicerGlassTokens.Spacing.small) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(previewGradient)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(previewBorder, lineWidth: isSelected ? 1.6 : 1)
                    }

                Image(systemName: format.iconName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? Color.sjCoral : Color.sjSecondaryText)
            }
            .aspectRatio(format.aspectRatio, contentMode: .fit)
            .frame(height: 64)

            Text(format.displayName)
                .font(StoryJuicerTypography.settingsControl)
                .foregroundStyle(isSelected ? Color.sjCoral : Color.sjText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(11)
        .sjGlassChip(selected: isSelected, interactive: true)
        .overlay {
            RoundedRectangle(cornerRadius: StoryJuicerGlassTokens.Radius.chip)
                .strokeBorder(
                    isSelected ? Color.sjCoral.opacity(0.9) : Color.sjBorder.opacity(0.62),
                    lineWidth: isSelected ? 1.7 : 1
                )
        }
        .shadow(color: isSelected ? Color.sjCoral.opacity(0.18) : .clear, radius: 8, y: 4)
        .animation(StoryJuicerMotion.standard, value: isSelected)
    }

    private var previewGradient: LinearGradient {
        if isSelected {
            return LinearGradient(
                colors: [
                    Color.sjCoral.opacity(0.22),
                    Color.sjHighlight.opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color.sjReadableCard.opacity(0.92),
                Color.sjCard.opacity(0.72)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var previewBorder: Color {
        isSelected ? Color.sjCoral.opacity(0.75) : Color.sjBorder.opacity(0.72)
    }
}
