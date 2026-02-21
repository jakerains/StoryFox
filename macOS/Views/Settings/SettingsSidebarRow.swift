import SwiftUI

struct SettingsSidebarRow: View {
    let tab: SettingsTab
    let isSelected: Bool

    var body: some View {
        HStack(spacing: StoryJuicerGlassTokens.Spacing.small) {
            Image(systemName: tab.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? Color.sjCoral : .sjSecondaryText)
                .frame(width: 22)

            Text(tab.label)
                .font(StoryJuicerTypography.settingsBody)
                .foregroundStyle(isSelected ? Color.sjGlassInk : .sjSecondaryText)

            Spacer()
        }
        .padding(.horizontal, StoryJuicerGlassTokens.Spacing.medium)
        .padding(.vertical, StoryJuicerGlassTokens.Spacing.small + 2)
        .sjGlassChip(selected: isSelected, interactive: true)
        .contentShape(Rectangle())
    }
}
