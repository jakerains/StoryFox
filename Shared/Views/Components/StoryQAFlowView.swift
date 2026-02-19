import SwiftUI

struct StoryQAFlowView: View {
    @Bindable var viewModel: StoryQAViewModel
    let onComplete: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        SettingsPanelCard(tint: .sjGlassWeak.opacity(0.68)) {
            switch viewModel.phase {
            case .generatingQuestions:
                loadingSection
            case .awaitingAnswers:
                if let round = viewModel.currentRound {
                    answersSection(round: round)
                }
            case .failed(let message):
                errorSection(message: message)
            case .complete(let enrichedConcept):
                // Auto-trigger generation on completion
                Color.clear
                    .onAppear { onComplete(enrichedConcept) }
            default:
                EmptyView()
            }
        }
    }

    // MARK: - Loading

    private var loadingSection: some View {
        VStack(spacing: StoryJuicerGlassTokens.Spacing.medium) {
            ProgressView()
                .controlSize(.large)
                .tint(.sjCoral)

            Text("Thinking of questions...")
                .font(StoryJuicerTypography.uiBodyStrong)
                .foregroundStyle(Color.sjSecondaryText)

            Text("The AI is crafting follow-up questions to help shape your story.")
                .font(StoryJuicerTypography.uiMeta)
                .foregroundStyle(Color.sjMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, StoryJuicerGlassTokens.Spacing.xLarge)
    }

    // MARK: - Answers

    private func answersSection(round: StoryQARound) -> some View {
        VStack(spacing: StoryJuicerGlassTokens.Spacing.large) {
            // Round header
            SettingsSectionHeader(
                title: viewModel.phase.roundLabel(audience: ModelSelectionStore.load().audienceMode),
                subtitle: "Answer the questions below to add detail to your story.",
                systemImage: "bubble.left.and.text.bubble.right"
            )

            // Questions
            ForEach(round.questions) { question in
                QuestionCardView(
                    question: question,
                    onAnswerChanged: { answer in
                        viewModel.updateAnswer(questionID: question.id, answer: answer)
                    }
                )
            }

            // Divider
            roundDivider

            // Navigation buttons
            navigationButtons
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: StoryJuicerGlassTokens.Spacing.medium) {
            // Cancel
            Button {
                onCancel()
            } label: {
                Label("Cancel", systemImage: "xmark")
                    .font(StoryJuicerTypography.settingsControl)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.sjSecondaryText)

            Spacer()

            // Generate Now (after at least 1 round)
            if viewModel.canGenerateNow && !viewModel.isLastRound {
                Button {
                    viewModel.generateNow()
                } label: {
                    Label("Generate Now", systemImage: "bolt")
                        .font(StoryJuicerTypography.settingsControl)
                        .foregroundStyle(Color.sjSecondaryText)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, StoryJuicerGlassTokens.Spacing.medium)
                .padding(.vertical, StoryJuicerGlassTokens.Spacing.small)
                .sjGlassChip(selected: false, interactive: true)
            }

            // Next / Generate
            Button {
                withAnimation(StoryJuicerMotion.emphasis) {
                    viewModel.submitCurrentRound()
                }
            } label: {
                Label(
                    viewModel.isLastRound ? "Generate Story" : "Next Round",
                    systemImage: viewModel.isLastRound ? "wand.and.stars" : "arrow.right"
                )
                .font(StoryJuicerTypography.settingsControl)
                .foregroundStyle(Color.sjGlassInk)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canProceed)
            .padding(.horizontal, StoryJuicerGlassTokens.Spacing.medium)
            .padding(.vertical, StoryJuicerGlassTokens.Spacing.small)
            .sjGlassChip(selected: viewModel.canProceed, interactive: true)
            .opacity(viewModel.canProceed ? 1 : 0.5)
        }
    }

    // MARK: - Error

    private func errorSection(message: String) -> some View {
        VStack(spacing: StoryJuicerGlassTokens.Spacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(Color.sjCoral)

            Text(message)
                .font(StoryJuicerTypography.uiBody)
                .foregroundStyle(Color.sjSecondaryText)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)

            HStack(spacing: StoryJuicerGlassTokens.Spacing.medium) {
                Button("Switch to Quick") {
                    onCancel()
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.sjSecondaryText)

                Button {
                    viewModel.startQA(concept: viewModel.rounds.isEmpty
                        ? "" // Will be re-set by parent
                        : "")
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.sjCoral)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, StoryJuicerGlassTokens.Spacing.large)
    }

    // MARK: - Helpers

    private var roundDivider: some View {
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
}

// MARK: - Question Card

private struct QuestionCardView: View {
    let question: StoryQuestion
    let onAnswerChanged: (String) -> Void

    private static let optionLetters = ["A", "B", "C"]

    @State private var customText: String = ""
    @State private var selectedIndex: Int? // 0-2 = suggestion, 3 = custom
    @FocusState private var customFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Question text
            Text(question.questionText)
                .font(StoryJuicerTypography.uiTitle)
                .foregroundStyle(Color.sjGlassInk)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, StoryJuicerGlassTokens.Spacing.medium)
                .padding(.top, StoryJuicerGlassTokens.Spacing.medium + 2)
                .padding(.bottom, StoryJuicerGlassTokens.Spacing.small + 4)

            // Thin separator below question
            Rectangle()
                .fill(Color.sjBorder.opacity(0.35))
                .frame(height: 0.5)
                .padding(.horizontal, StoryJuicerGlassTokens.Spacing.small)

            // Options A, B, C
            ForEach(Array(question.suggestedAnswers.enumerated()), id: \.offset) { index, suggestion in
                optionRow(
                    letter: Self.optionLetters[index],
                    text: suggestion,
                    isSelected: selectedIndex == index
                ) {
                    withAnimation(StoryJuicerMotion.fast) {
                        selectedIndex = index
                        customText = ""
                        customFieldFocused = false
                        onAnswerChanged(suggestion)
                    }
                }

                if index < question.suggestedAnswers.count - 1 {
                    Rectangle()
                        .fill(Color.sjBorder.opacity(0.18))
                        .frame(height: 0.5)
                        .padding(.leading, 52)
                        .padding(.trailing, StoryJuicerGlassTokens.Spacing.small)
                }
            }

            // Separator before custom option
            Rectangle()
                .fill(Color.sjBorder.opacity(0.18))
                .frame(height: 0.5)
                .padding(.leading, 52)
                .padding(.trailing, StoryJuicerGlassTokens.Spacing.small)

            // Option D — custom answer
            customOptionRow
        }
        .background(Color.sjReadableCard.opacity(0.45))
        .clipShape(.rect(cornerRadius: StoryJuicerGlassTokens.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: StoryJuicerGlassTokens.Radius.card)
                .strokeBorder(
                    selectedIndex != nil
                        ? Color.sjCoral.opacity(0.35)
                        : Color.sjBorder.opacity(0.5),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Option Row

    private func optionRow(
        letter: String,
        text: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: StoryJuicerGlassTokens.Spacing.small + 2) {
                letterBadge(letter, isSelected: isSelected)

                Text(text)
                    .font(StoryJuicerTypography.settingsBody)
                    .foregroundStyle(isSelected ? Color.sjGlassInk : .sjSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 2)
            }
            .padding(.horizontal, StoryJuicerGlassTokens.Spacing.medium)
            .padding(.vertical, StoryJuicerGlassTokens.Spacing.small + 2)
            .contentShape(Rectangle())
            .background(
                isSelected
                    ? Color.sjCoral.opacity(0.08)
                    : Color.clear
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Option \(letter): \(text)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Custom Option Row (D)

    private var customOptionRow: some View {
        let isActive = selectedIndex == 3

        return HStack(alignment: .center, spacing: StoryJuicerGlassTokens.Spacing.small + 2) {
            letterBadge("D", isSelected: isActive)

            TextField("Type your own answer...", text: $customText)
                .font(StoryJuicerTypography.settingsBody)
                .foregroundStyle(Color.sjGlassInk)
                .focused($customFieldFocused)
                .textFieldStyle(.plain)
                .onChange(of: customText) { _, newValue in
                    if !newValue.isEmpty {
                        selectedIndex = 3
                        onAnswerChanged(newValue)
                    } else if selectedIndex == 3 {
                        selectedIndex = nil
                        onAnswerChanged("")
                    }
                }
        }
        .padding(.horizontal, StoryJuicerGlassTokens.Spacing.medium)
        .padding(.vertical, StoryJuicerGlassTokens.Spacing.small + 2)
        .background(isActive ? Color.sjCoral.opacity(0.08) : Color.clear)
        .clipShape(.rect(
            bottomLeadingRadius: StoryJuicerGlassTokens.Radius.card,
            bottomTrailingRadius: StoryJuicerGlassTokens.Radius.card
        ))
    }

    // MARK: - Letter Badge

    private func letterBadge(_ letter: String, isSelected: Bool) -> some View {
        Text(letter)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(isSelected ? .white : Color.sjSecondaryText)
            .frame(width: 28, height: 28)
            .background(
                Circle()
                    .fill(
                        isSelected
                            ? Color.sjCoral
                            : Color.sjBorder.opacity(0.25)
                    )
            )
            .overlay {
                Circle()
                    .strokeBorder(
                        isSelected
                            ? Color.sjCoral.opacity(0.6)
                            : Color.sjBorder.opacity(0.5),
                        lineWidth: 1
                    )
            }
    }
}
