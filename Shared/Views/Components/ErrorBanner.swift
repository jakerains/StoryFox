import SwiftUI

struct ErrorBanner: View {
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void

    @State private var copied = false

    var body: some View {
        HStack(alignment: .top, spacing: StoryJuicerGlassTokens.Spacing.medium) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(Color.sjCoral)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: StoryJuicerGlassTokens.Spacing.xSmall) {
                Text("Needs a quick tweak")
                    .font(StoryJuicerTypography.uiTitle)
                    .foregroundStyle(Color.sjGlassInk)

                Text(message)
                    .font(StoryJuicerTypography.uiBody)
                    .foregroundStyle(Color.sjSecondaryText)
                    .textSelection(.enabled)
            }

            Spacer(minLength: StoryJuicerGlassTokens.Spacing.small)

            VStack(spacing: StoryJuicerGlassTokens.Spacing.small) {
                HStack(spacing: StoryJuicerGlassTokens.Spacing.small) {
                    Button("Retry") {
                        onRetry()
                    }
                    .sjGlassToolbarItem(prominent: true)
                    .tint(Color.sjCoral)

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(StoryJuicerTypography.uiFootnoteStrong)
                            .frame(width: 24, height: 24)
                    }
                    .sjGlassToolbarItem(prominent: false)
                }

                Button {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(message, forType: .string)
                    #else
                    UIPasteboard.general.string = message
                    #endif
                    copied = true
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        copied = false
                    }
                } label: {
                    Label(copied ? "Copied" : "Copy Error", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11, weight: .medium))
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.sjSecondaryText)
            }
        }
        .padding(StoryJuicerGlassTokens.Spacing.medium)
        .sjGlassCard(tint: .sjCoral.opacity(StoryJuicerGlassTokens.Tint.standard))
        .overlay {
            RoundedRectangle(cornerRadius: StoryJuicerGlassTokens.Radius.card)
                .strokeBorder(Color.sjCoral.opacity(0.45), lineWidth: 1)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
