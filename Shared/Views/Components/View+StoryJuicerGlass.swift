import SwiftUI

extension View {
    @ViewBuilder
    func sjGlassCard(
        tint: Color = .clear,
        interactive: Bool = false,
        cornerRadius: CGFloat = StoryJuicerGlassTokens.Radius.card
    ) -> some View {
        if interactive {
            self.glassEffect(
                .regular.tint(tint).interactive(),
                in: .rect(cornerRadius: cornerRadius)
            )
        } else {
            self.glassEffect(
                .regular.tint(tint),
                in: .rect(cornerRadius: cornerRadius)
            )
        }
    }

    func sjGlassChip(
        selected: Bool,
        interactive: Bool = true
    ) -> some View {
        sjGlassCard(
            tint: selected ? .sjCoral.opacity(StoryJuicerGlassTokens.Tint.emphasis) : .sjGlassWeak,
            interactive: interactive,
            cornerRadius: StoryJuicerGlassTokens.Radius.chip
        )
        .overlay {
            if selected {
                RoundedRectangle(cornerRadius: StoryJuicerGlassTokens.Radius.chip)
                    .strokeBorder(Color.sjCoral.opacity(0.5), lineWidth: 1.5)
            }
        }
    }

    @ViewBuilder
    func sjGlassToolbarItem(prominent: Bool) -> some View {
        if prominent {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.glass)
        }
    }
}
