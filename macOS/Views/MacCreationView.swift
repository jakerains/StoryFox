import SwiftUI
#if os(macOS)
import AppKit
#endif

struct MacCreationView: View {
    @Bindable var viewModel: CreationViewModel
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground

    @State private var animateTitle = false
    @State private var creationMode: CreationMode = .quick
    @State private var qaViewModel = StoryQAViewModel()
    @State private var showBookSetupPopover = false

    var body: some View {
        ZStack {
            backgroundLayer
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    heroImage
                        .padding(.bottom, StoryJuicerGlassTokens.Spacing.large)

                    titleLine

                    if case .failed(let message) = viewModel.phase {
                        ErrorBanner(
                            message: message,
                            onRetry: { viewModel.squeezeStory() },
                            onDismiss: { viewModel.reset() }
                        )
                        .padding(.top, StoryJuicerGlassTokens.Spacing.large)
                    }

                    conceptSection
                        .padding(.top, StoryJuicerGlassTokens.Spacing.xLarge)

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
                        .padding(.top, StoryJuicerGlassTokens.Spacing.large)
                    }

                    if creationMode == .quick {
                        SqueezeButton(isEnabled: viewModel.canGenerate) {
                            viewModel.squeezeStory()
                        }
                        .padding(.top, StoryJuicerGlassTokens.Spacing.large)
                    } else if qaViewModel.phase == .idle {
                        SqueezeButton(
                            title: "Explore Your Story",
                            subtitle: "AI will ask questions to enrich your concept",
                            icon: "sparkle.magnifyingglass",
                            isEnabled: viewModel.canGenerate
                        ) {
                            qaViewModel.startQA(concept: viewModel.storyConcept)
                        }
                        .padding(.top, StoryJuicerGlassTokens.Spacing.large)
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
                animateTitle = true
            }
        }
    }

    // MARK: - Background

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

    // MARK: - Hero Image

    private var heroImage: some View {
        Image("StoryFoxHero")
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 220)
            .opacity(animateTitle ? 0.85 : 0)
            .scaleEffect(animateTitle ? 1 : 0.96)
    }

    // MARK: - Title

    private var titleLine: some View {
        Text("What story shall we create?")
            .font(StoryJuicerTypography.sectionHero)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.sjCoral, Color.sjGold, Color.sjHighlight, Color.sjCoral],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(alignment: .topTrailing) {
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.sjGold.opacity(0.8))
                    .symbolEffect(.breathe.pulse, options: .repeating.speed(0.5))
                    .offset(x: 8, y: -6)
            }
            .overlay(alignment: .bottomLeading) {
                Image(systemName: "sparkle")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.sjGold.opacity(0.6))
                    .symbolEffect(.breathe.pulse, options: .repeating.speed(0.4))
                    .offset(x: -6, y: 4)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(animateTitle ? 1 : 0)
            .offset(y: animateTitle ? 0 : 8)
    }

    // MARK: - Concept Input

    private var conceptSection: some View {
        VStack(alignment: .leading, spacing: StoryJuicerGlassTokens.Spacing.small) {
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

            HStack {
                CreationModeToggle(selection: $creationMode)

                Spacer(minLength: StoryJuicerGlassTokens.Spacing.medium)

                bookSetupRow
                    .fixedSize()
            }
        }
    }

    // MARK: - Book Setup Chip + Popover

    private var bookSetupRow: some View {
        Button {
            showBookSetupPopover.toggle()
        } label: {
            HStack(spacing: StoryJuicerGlassTokens.Spacing.small) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.sjCoral)

                Text("\(viewModel.pageCount) pages · \(viewModel.selectedFormat.displayName) · \(viewModel.selectedStyle.displayName)")
                    .font(StoryJuicerTypography.uiMetaStrong)
                    .foregroundStyle(Color.sjGlassInk)

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.sjSecondaryText)
                    .rotationEffect(.degrees(showBookSetupPopover ? 180 : 0))
                    .animation(StoryJuicerMotion.fast, value: showBookSetupPopover)
            }
            .padding(.horizontal, StoryJuicerGlassTokens.Spacing.medium)
            .padding(.vertical, StoryJuicerGlassTokens.Spacing.small + 2)
            .contentShape(Rectangle())
            .sjGlassChip(selected: false, interactive: true)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showBookSetupPopover, arrowEdge: .bottom) {
            bookSetupPopoverContent
        }
    }

    private var bookSetupPopoverContent: some View {
        VStack(alignment: .leading, spacing: StoryJuicerGlassTokens.Spacing.medium) {
            SettingsSectionHeader(
                title: "Book Setup",
                subtitle: "Configure pages, format, and illustration style.",
                systemImage: "wand.and.stars"
            )

            panelDivider

            pageCountRow

            panelDivider

            formatPickerSection

            panelDivider

            stylePickerSection
        }
        .padding(StoryJuicerGlassTokens.Spacing.large)
        .frame(width: 420)
    }

    // MARK: - Settings Content (reused in popover)

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
