import SwiftUI
import CoreGraphics

struct PageEditSheet: View {
    @Bindable var viewModel: BookReaderViewModel
    var dismiss: () -> Void

    @State private var editedText: String = ""
    @State private var customImagePrompt: String = ""
    @State private var hasEdited = false

    private var imageIndex: Int? {
        if viewModel.isTitlePage { return 0 }
        return viewModel.currentStoryPage?.pageNumber
    }

    private var isRegeneratingCurrentImage: Bool {
        guard let idx = imageIndex else { return false }
        return viewModel.regeneratingPages.contains(idx)
    }

    private var isRegeneratingCurrentText: Bool {
        guard let page = viewModel.currentStoryPage else { return false }
        return viewModel.regeneratingText.contains(page.pageNumber)
    }

    /// The original image prompt for the current page.
    private var originalImagePrompt: String? {
        if viewModel.isTitlePage {
            return ContentSafetyPolicy.safeCoverPrompt(
                title: viewModel.storyBook.title,
                concept: viewModel.storyBook.moral
            )
        }
        return viewModel.currentStoryPage?.imagePrompt
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(StoryJuicerGlassTokens.Spacing.large)

            Divider()
                .overlay(Color.sjBorder.opacity(0.45))

            ScrollView {
                VStack(spacing: StoryJuicerGlassTokens.Spacing.large) {
                    if viewModel.isTitlePage {
                        titlePageEditor
                    } else if viewModel.isEndPage {
                        endPageEditor
                    } else {
                        contentPageEditor
                    }
                }
                .padding(StoryJuicerGlassTokens.Spacing.large)
            }
        }
        .frame(minWidth: 420, minHeight: 340)
        .background(backgroundLayer)
        .onAppear { loadCurrentValues() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: StoryJuicerGlassTokens.Spacing.medium) {
            VStack(alignment: .leading, spacing: 4) {
                Text(headerTitle)
                    .font(StoryJuicerTypography.uiTitle)
                    .foregroundStyle(Color.sjGlassInk)

                Text(headerSubtitle)
                    .font(StoryJuicerTypography.uiMeta)
                    .foregroundStyle(Color.sjSecondaryText)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Label("Close", systemImage: "xmark")
                    .labelStyle(.iconOnly)
            }
            .sjGlassToolbarItem(prominent: false)
        }
    }

    private var headerTitle: String {
        if viewModel.isTitlePage { return "Edit Cover" }
        if viewModel.isEndPage { return "Edit Ending" }
        return "Edit Page \(viewModel.currentPage)"
    }

    private var headerSubtitle: String {
        if viewModel.isTitlePage { return "Change author & regenerate cover image" }
        if viewModel.isEndPage { return "Update the story's moral" }
        return "Edit text & regenerate illustration"
    }

    // MARK: - Title Page Editor

    private var titlePageEditor: some View {
        VStack(spacing: StoryJuicerGlassTokens.Spacing.large) {
            textEditSection(
                label: "Author Line",
                placeholder: "Written by StoryFox",
                text: $editedText,
                showRegenerate: false,
                onSave: {
                    viewModel.updateAuthorLine(editedText)
                    hasEdited = true
                }
            )

            imageSection
        }
    }

    // MARK: - Content Page Editor

    private var contentPageEditor: some View {
        VStack(spacing: StoryJuicerGlassTokens.Spacing.large) {
            textEditSection(
                label: "Page Text",
                placeholder: "Once upon a time...",
                text: $editedText,
                lineLimit: 6,
                showRegenerate: true,
                onSave: {
                    if let page = viewModel.currentStoryPage {
                        viewModel.updatePageText(pageNumber: page.pageNumber, newText: editedText)
                        hasEdited = true
                    }
                }
            )

            imageSection
        }
    }

    // MARK: - End Page Editor

    private var endPageEditor: some View {
        VStack(spacing: StoryJuicerGlassTokens.Spacing.large) {
            textEditSection(
                label: "Moral",
                placeholder: "Kindness and curiosity guide every adventure.",
                text: $editedText,
                lineLimit: 3,
                showRegenerate: false,
                onSave: {
                    viewModel.updateMoral(editedText)
                    hasEdited = true
                }
            )
        }
    }

    // MARK: - Shared Sections

    private func textEditSection(
        label: String,
        placeholder: String,
        text: Binding<String>,
        lineLimit: Int = 1,
        showRegenerate: Bool = false,
        onSave: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: StoryJuicerGlassTokens.Spacing.small) {
            Text(label)
                .font(StoryJuicerTypography.uiMetaStrong)
                .foregroundStyle(Color.sjGlassInk)

            Group {
                if lineLimit > 1 {
                    TextEditor(text: text)
                        .font(.system(.body, design: .rounded))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: CGFloat(lineLimit) * 22, maxHeight: CGFloat(lineLimit) * 30)
                } else {
                    TextField(placeholder, text: text)
                        .font(.system(.body, design: .rounded))
                        .textFieldStyle(.plain)
                }
            }
            .padding(StoryJuicerGlassTokens.Spacing.small)
            .sjGlassCard(
                tint: .sjGlassWeak,
                cornerRadius: StoryJuicerGlassTokens.Radius.chip
            )

            HStack(spacing: StoryJuicerGlassTokens.Spacing.small) {
                Button {
                    onSave()
                } label: {
                    Label("Save Changes", systemImage: "checkmark.circle.fill")
                        .font(StoryJuicerTypography.uiMetaStrong)
                }
                .buttonStyle(.glassProminent)
                .tint(Color.sjCoral)
                .controlSize(.small)

                if showRegenerate {
                    Button {
                        guard let page = viewModel.currentStoryPage else { return }
                        Task {
                            await viewModel.regeneratePageText(pageNumber: page.pageNumber)
                            // Update the editor with the new text
                            if let updated = viewModel.currentStoryPage {
                                editedText = updated.text
                                customImagePrompt = updated.imagePrompt
                            }
                        }
                    } label: {
                        Label(
                            isRegeneratingCurrentText ? "Rewriting..." : "Regenerate Text",
                            systemImage: "arrow.clockwise"
                        )
                        .font(StoryJuicerTypography.uiMetaStrong)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.small)
                    .disabled(isRegeneratingCurrentText)

                    if isRegeneratingCurrentText {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }

            if hasEdited {
                Text("Changes saved")
                    .font(StoryJuicerTypography.uiMeta)
                    .foregroundStyle(Color.sjGold)
            }

            // Show text regeneration error
            if let page = viewModel.currentStoryPage,
               let error = viewModel.textRegenerationErrors[page.pageNumber] {
                Text(error)
                    .font(StoryJuicerTypography.uiMeta)
                    .foregroundStyle(Color.sjCoral)
                    .lineLimit(3)
            }
        }
        .padding(StoryJuicerGlassTokens.Spacing.medium)
        .sjGlassCard(
            tint: .sjGlassSoft.opacity(StoryJuicerGlassTokens.Tint.standard),
            cornerRadius: StoryJuicerGlassTokens.Radius.card
        )
    }

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: StoryJuicerGlassTokens.Spacing.small) {
            Text("Illustration")
                .font(StoryJuicerTypography.uiMetaStrong)
                .foregroundStyle(Color.sjGlassInk)

            // Show the original prompt so user can see what generated the image
            if let prompt = originalImagePrompt {
                VStack(alignment: .leading, spacing: StoryJuicerGlassTokens.Spacing.xSmall) {
                    Text("Current Prompt")
                        .font(StoryJuicerTypography.uiMeta)
                        .foregroundStyle(Color.sjSecondaryText)

                    Text(prompt)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Color.sjSecondaryText)
                        .italic()
                        .lineLimit(6)
                        .textSelection(.enabled)
                }
                .padding(StoryJuicerGlassTokens.Spacing.small)
                .frame(maxWidth: .infinity, alignment: .leading)
                .sjGlassCard(
                    tint: .sjGlassWeak,
                    cornerRadius: StoryJuicerGlassTokens.Radius.chip
                )
            }

            Text("Edit the prompt below, or leave as-is to regenerate with the current prompt.")
                .font(StoryJuicerTypography.uiMeta)
                .foregroundStyle(Color.sjSecondaryText)

            TextField("Image prompt", text: $customImagePrompt)
                .font(.system(.body, design: .rounded))
                .textFieldStyle(.plain)
                .padding(StoryJuicerGlassTokens.Spacing.small)
                .sjGlassCard(
                    tint: .sjGlassWeak,
                    cornerRadius: StoryJuicerGlassTokens.Radius.chip
                )

            HStack(spacing: StoryJuicerGlassTokens.Spacing.small) {
                Button {
                    guard let idx = imageIndex else { return }
                    let prompt = customImagePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
                    Task {
                        await viewModel.regenerateImage(
                            index: idx,
                            customPrompt: prompt.isEmpty ? nil : prompt
                        )
                    }
                } label: {
                    Label(
                        isRegeneratingCurrentImage ? "Regenerating..." : "Regenerate Image",
                        systemImage: "arrow.clockwise"
                    )
                    .font(StoryJuicerTypography.uiMetaStrong)
                }
                .buttonStyle(.glassProminent)
                .tint(Color.sjCoral)
                .controlSize(.small)
                .disabled(isRegeneratingCurrentImage)

                if isRegeneratingCurrentImage {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let idx = imageIndex, let error = viewModel.regenerationErrors[idx] {
                Text(error)
                    .font(StoryJuicerTypography.uiMeta)
                    .foregroundStyle(Color.sjCoral)
                    .lineLimit(3)
            }
        }
        .padding(StoryJuicerGlassTokens.Spacing.medium)
        .sjGlassCard(
            tint: .sjGlassSoft.opacity(StoryJuicerGlassTokens.Tint.standard),
            cornerRadius: StoryJuicerGlassTokens.Radius.card
        )
    }

    // MARK: - Helpers

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [Color.sjPaperTop, Color.sjPaperBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func loadCurrentValues() {
        if viewModel.isTitlePage {
            editedText = viewModel.storyBook.authorLine
            // Pre-fill with the cover prompt
            customImagePrompt = ContentSafetyPolicy.safeCoverPrompt(
                title: viewModel.storyBook.title,
                concept: viewModel.storyBook.moral
            )
        } else if viewModel.isEndPage {
            editedText = viewModel.storyBook.moral
        } else if let page = viewModel.currentStoryPage {
            editedText = page.text
            // Pre-fill with the original image prompt so user can tweak it
            customImagePrompt = page.imagePrompt
        }
    }
}
