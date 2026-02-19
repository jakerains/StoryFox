import SwiftUI
#if os(macOS)
import AppKit
#endif

struct MacCreationView: View {
    @Bindable var viewModel: CreationViewModel
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground

    @State private var animateHero = false
    @State private var creationMode: CreationMode = .quick
    @State private var qaViewModel = StoryQAViewModel()

    var body: some View {
        ZStack {
            backgroundLayer
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: StoryJuicerGlassTokens.Spacing.xLarge) {
                    headerSection

                    if case .failed(let message) = viewModel.phase {
                        ErrorBanner(
                            message: message,
                            onRetry: { viewModel.squeezeStory() },
                            onDismiss: { viewModel.reset() }
                        )
                    }

                    conceptSection

                    // Q&A flow when guided mode is active and running
                    if creationMode == .guided && qaViewModel.phase != .idle {
                        StoryQAFlowView(
                            viewModel: qaViewModel,
                            onComplete: { enrichedConcept in
                                viewModel.storyConcept = enrichedConcept
                                viewModel.isEnrichedConcept = true
                                viewModel.squeezeStory()
                            },
                            onCancel: {
                                qaViewModel.cancel()
                                withAnimation(StoryJuicerMotion.standard) {
                                    creationMode = .quick
                                }
                            }
                        )
                    }

                    settingsSection

                    if creationMode == .quick {
                        SqueezeButton(isEnabled: viewModel.canGenerate) {
                            viewModel.squeezeStory()
                        }
                        .padding(.top, StoryJuicerGlassTokens.Spacing.small)
                    } else if qaViewModel.phase == .idle {
                        SqueezeButton(
                            title: "Explore Your Story",
                            subtitle: "AI will ask questions to enrich your concept",
                            icon: "sparkle.magnifyingglass",
                            isEnabled: viewModel.canGenerate
                        ) {
                            qaViewModel.startQA(concept: viewModel.storyConcept)
                        }
                        .padding(.top, StoryJuicerGlassTokens.Spacing.small)
                    }
                }
                .padding(.horizontal, StoryJuicerGlassTokens.Spacing.xLarge + 8)
                .padding(.vertical, StoryJuicerGlassTokens.Spacing.xLarge)
            }

            if let reason = viewModel.unavailabilityReason {
                UnavailableOverlay(reason: reason)
            }
        }
        .onAppear {
            withAnimation(StoryJuicerMotion.emphasis) {
                animateHero = true
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color.sjPaperTop, Color.sjBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.sjHighlight.opacity(0.24), .clear],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 560
            )

            LinearGradient(
                colors: [.clear, Color.sjPeach.opacity(0.14)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: StoryJuicerGlassTokens.Spacing.large) {
            heroBrandIcon
            .frame(width: 66, height: 66)
            .clipShape(.rect(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.16), radius: 10, y: 5)
            .scaleEffect(animateHero ? 1 : 0.94)

            VStack(alignment: .leading, spacing: StoryJuicerGlassTokens.Spacing.xSmall) {
                Text("StoryJuicer")
                    .font(StoryJuicerTypography.brandHero)
                    .foregroundStyle(Color.sjGlassInk)

                Text("Create editorial-quality illustrated books with on-device Apple intelligence.")
                    .font(StoryJuicerTypography.uiBodyStrong)
                    .foregroundStyle(Color.sjSecondaryText)

                Text("No cloud calls. No API keys. Just your idea and your Mac.")
                    .font(StoryJuicerTypography.uiMeta)
                    .foregroundStyle(Color.sjSecondaryText)
            }

            Spacer(minLength: 0)
        }
        .padding(StoryJuicerGlassTokens.Spacing.large)
        .sjGlassCard(
            tint: .sjGlassSoft.opacity(StoryJuicerGlassTokens.Tint.standard),
            cornerRadius: StoryJuicerGlassTokens.Radius.hero
        )
        .overlay {
            RoundedRectangle(cornerRadius: StoryJuicerGlassTokens.Radius.hero)
                .strokeBorder(Color.sjBorder.opacity(0.65), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var heroBrandIcon: some View {
#if os(macOS)
        if let appIcon = NSImage(named: NSImage.applicationIconName) {
            Image(nsImage: appIcon)
                .resizable()
                .scaledToFill()
        } else {
            fallbackHeroSymbol
        }
#else
        fallbackHeroSymbol
#endif
    }

    private var fallbackHeroSymbol: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.sjCoral.opacity(0.9), Color.sjGold.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "book.fill")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
        }
    }

    private var conceptSection: some View {
        VStack(alignment: .leading, spacing: StoryJuicerGlassTokens.Spacing.small) {
            Label("Story Concept", systemImage: "sparkles")
                .font(StoryJuicerTypography.uiTitle)
                .foregroundStyle(Color.sjGlassInk)

            TextEditor(text: $viewModel.storyConcept)
                .font(StoryJuicerTypography.uiBody)
                .foregroundStyle(Color.sjText)
                .frame(minHeight: 120, maxHeight: 190)
                .padding(StoryJuicerGlassTokens.Spacing.small)
                .scrollContentBackground(.hidden)
                .background(Color.sjReadableCard.opacity(0.9))
                .clipShape(.rect(cornerRadius: StoryJuicerGlassTokens.Radius.input))
                .overlay {
                    RoundedRectangle(cornerRadius: StoryJuicerGlassTokens.Radius.input)
                        .strokeBorder(Color.sjBorder.opacity(0.75), lineWidth: 1)
                }
                .overlay(alignment: .topLeading) {
                    if viewModel.storyConcept.isEmpty {
                        Text("Describe your story idea... e.g. a curious fox building a moonlight library in the forest")
                            .font(StoryJuicerTypography.uiBody)
                            .foregroundStyle(Color.sjSecondaryText)
                            .padding(StoryJuicerGlassTokens.Spacing.medium)
                            .allowsHitTesting(false)
                    }
                }
                .disabled(qaViewModel.phase != .idle && creationMode == .guided)

            CreationModeToggle(selection: $creationMode)
        }
        .padding(StoryJuicerGlassTokens.Spacing.large)
        .sjGlassCard(
            tint: .sjGlassSoft.opacity(StoryJuicerGlassTokens.Tint.subtle),
            cornerRadius: StoryJuicerGlassTokens.Radius.hero
        )
    }

    private var settingsSection: some View {
        SettingsPanelCard(tint: .sjGlassWeak.opacity(0.68)) {
            SettingsSectionHeader(
                title: "Book Setup",
                subtitle: "Tune page count, layout, and illustration style before generating.",
                systemImage: "wand.and.stars"
            )

            pageCountRow
            panelDivider
            formatPickerSection
            panelDivider
            stylePickerSection
        }
    }

    private var panelDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.sjBorder.opacity(0.2), Color.sjBorder.opacity(0.85), Color.sjBorder.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }

    private var pageCountRow: some View {
        SettingsControlRow(
            title: "Page Count",
            description: "Choose an even value from \(GenerationConfig.minPages) to \(GenerationConfig.maxPages)."
        ) {
            Stepper(
                value: $viewModel.pageCount,
                in: GenerationConfig.minPages...GenerationConfig.maxPages,
                step: 2
            ) {
                Text("\(viewModel.pageCount) pages")
                    .font(StoryJuicerTypography.settingsControl)
                    .foregroundStyle(Color.sjText)
            }
            .frame(width: 210)
            .padding(.horizontal, StoryJuicerGlassTokens.Spacing.small)
            .padding(.vertical, StoryJuicerGlassTokens.Spacing.xSmall + 2)
            .background(Color.sjReadableCard.opacity(0.85), in: .rect(cornerRadius: StoryJuicerGlassTokens.Radius.input))
            .overlay {
                RoundedRectangle(cornerRadius: StoryJuicerGlassTokens.Radius.input)
                    .strokeBorder(Color.sjBorder.opacity(0.8), lineWidth: 1)
            }
            .tint(.sjCoral)
        }
    }

    private var formatPickerSection: some View {
        VStack(alignment: .leading, spacing: StoryJuicerGlassTokens.Spacing.medium) {
            SettingsSectionHeader(
                title: "Book Format",
                subtitle: "Pick page proportions for reading and PDF export.",
                systemImage: "rectangle.portrait.on.rectangle.portrait"
            )

            GlassEffectContainer(spacing: StoryJuicerGlassTokens.Spacing.small) {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 145, maximum: 220), spacing: StoryJuicerGlassTokens.Spacing.small)],
                    spacing: StoryJuicerGlassTokens.Spacing.small
                ) {
                    ForEach(BookFormat.allCases) { format in
                        Button {
                            withAnimation(StoryJuicerMotion.standard) {
                                viewModel.selectedFormat = format
                            }
                        } label: {
                            FormatPreviewCard(
                                format: format,
                                isSelected: viewModel.selectedFormat == format
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Book format \(format.displayName)")
                    }
                }
            }
        }
    }

    private var stylePickerSection: some View {
        VStack(alignment: .leading, spacing: StoryJuicerGlassTokens.Spacing.medium) {
            SettingsSectionHeader(
                title: "Illustration Style",
                subtitle: "Choose the visual treatment for every generated page.",
                systemImage: "paintbrush.fill"
            )

            if !supportsImagePlayground && ModelSelectionStore.load().imageProvider == .imagePlayground {
                warningCallout(
                    "Image Playground is not available on this device.",
                    systemImage: "exclamationmark.triangle"
                )
            }

            GlassEffectContainer(spacing: StoryJuicerGlassTokens.Spacing.medium) {
                HStack(spacing: StoryJuicerGlassTokens.Spacing.medium) {
                    ForEach(IllustrationStyle.allCases) { style in
                        Button {
                            withAnimation(StoryJuicerMotion.standard) {
                                viewModel.selectedStyle = style
                            }
                        } label: {
                            StylePickerItem(
                                style: style,
                                isSelected: viewModel.selectedStyle == style
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Illustration style \(style.displayName)")
                    }
                }
            }
        }
    }

    private func warningCallout(_ message: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: StoryJuicerGlassTokens.Spacing.small) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.sjCoral)

            Text(message)
                .font(StoryJuicerTypography.settingsMeta)
                .foregroundStyle(Color.sjSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(StoryJuicerGlassTokens.Spacing.small)
        .background(Color.sjCoral.opacity(0.12), in: .rect(cornerRadius: StoryJuicerGlassTokens.Radius.input))
        .overlay {
            RoundedRectangle(cornerRadius: StoryJuicerGlassTokens.Radius.input)
                .strokeBorder(Color.sjCoral.opacity(0.38), lineWidth: 1)
        }
    }
}
