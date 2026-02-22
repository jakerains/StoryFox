import Foundation
import CoreGraphics
import FoundationModels

enum GenerationPhase: Sendable, Equatable {
    case idle
    case generatingText(partialText: String)
    case generatingImages(completedCount: Int, totalCount: Int)
    case complete
    case failed(String)

    var isWorking: Bool {
        switch self {
        case .generatingText, .generatingImages: true
        default: false
        }
    }

    var errorMessage: String? {
        if case .failed(let message) = self { return message }
        return nil
    }
}

@Observable
@MainActor
final class CreationViewModel {
    // MARK: - User Inputs
    var storyConcept: String = ""
    var pageCount: Int = GenerationConfig.defaultPages
    var selectedFormat: BookFormat = .standard
    var selectedStyle: IllustrationStyle = .illustration
    var isEnrichedConcept: Bool = false

    // MARK: - Prompt Suggestions (typewriter cycle)
    private var promptSuggestions: [String] = []
    private var suggestionsGenerated = false
    private var suggestionsTask: Task<Void, Never>?
    private var suggestionCycleTask: Task<Void, Never>?
    private var suggestionRestartTask: Task<Void, Never>?
    private var currentSuggestionIndex: Int = 0

    /// The portion of the suggestion typed out so far (for display as placeholder).
    private(set) var suggestionDisplayText: String = ""
    /// The full text of the currently active suggestion (nil when idle).
    private(set) var activeSuggestion: String? = nil
    /// Opacity for fade-in/out of the typewriter text.
    private(set) var suggestionOpacity: Double = 0
    /// Whether the suggestion cycle is actively running (stable across inter-suggestion gaps).
    private(set) var isSuggestionCycleActive = false

    // MARK: - Author Mode Inputs
    var authorTitle: String = ""
    var authorCharacterDescriptions: String = ""
    var authorPages: [String] = ["", "", "", ""]

    // MARK: - Generation State
    private(set) var phase: GenerationPhase = .idle
    private(set) var storyBook: StoryBook?
    private(set) var generatedImages: [Int: CGImage] = [:]
    /// Pre-parsed character entries from Foundation Model (Upgrade 1).
    /// Set during `squeezeStory()`, passed to `BookReaderViewModel` for regeneration.
    private(set) var parsedCharacters: [ImagePromptEnricher.CharacterEntry] = []

    // MARK: - Generators
    let storyGenerator = StoryGenerator()
    let remoteStoryGenerator = RemoteStoryGenerator()
    let mlxStoryGenerator = MLXStoryGenerator()
    let illustrationGenerator = IllustrationGenerator()

    private var generationTask: Task<Void, Never>?

    var canGenerate: Bool {
        let hasConcept = !storyConcept.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || activeSuggestion != nil
        return hasConcept && !phase.isWorking
    }

    /// Whether Author Mode has enough content to generate illustrations.
    var canIllustrateAuthorStory: Bool {
        !authorTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && authorPages.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            && !phase.isWorking
    }

    var isAvailable: Bool {
        let settings = ModelSelectionStore.load()
        switch settings.textProvider {
        case .appleFoundation:
            return remoteStoryGenerator.isConfigured || storyGenerator.isAvailable
        case .mlxSwift:
            return true
        case .openRouter:
            return CloudCredentialStore.isAuthenticated(for: .openRouter)
        case .togetherAI:
            return CloudCredentialStore.isAuthenticated(for: .togetherAI)
        case .huggingFace:
            return CloudCredentialStore.isAuthenticated(for: .huggingFace)
        }
    }

    var unavailabilityReason: String? {
        let settings = ModelSelectionStore.load()
        switch settings.textProvider {
        case .appleFoundation:
            if remoteStoryGenerator.isConfigured || storyGenerator.isAvailable {
                return nil
            }
            return storyGenerator.unavailabilityReason
        case .mlxSwift:
            return nil
        case .openRouter:
            return CloudCredentialStore.isAuthenticated(for: .openRouter)
                ? nil : "OpenRouter API key not configured. Add it in Settings."
        case .togetherAI:
            return CloudCredentialStore.isAuthenticated(for: .togetherAI)
                ? nil : "Together AI API key not configured. Add it in Settings."
        case .huggingFace:
            return CloudCredentialStore.isAuthenticated(for: .huggingFace)
                ? nil : "Hugging Face not authenticated. Log in via Settings."
        }
    }

    // MARK: - Generation

    func squeezeStory() {
        // If concept is empty but a suggestion is active, use the full suggestion
        if storyConcept.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let suggestion = activeSuggestion {
            storyConcept = suggestion
            stopSuggestionCycle()
        }

        guard canGenerate else { return }
        stopSuggestionCycle()

        // Enriched concepts from Q&A are longer — use a higher sanitization limit
        let maxLength = isEnrichedConcept ? 1500 : 220
        let conceptCheck = ContentSafetyPolicy.validateConcept(storyConcept, maxLength: maxLength)
        guard case .allowed(let safeConcept) = conceptCheck else {
            if case .blocked(let reason) = conceptCheck {
                phase = .failed(reason)
            }
            return
        }

        let settings = ModelSelectionStore.load()
        let useCloudTextPath = settings.textProvider.isCloud

        generationTask = Task {
            do {
                // Phase 1: Generate text
                phase = .generatingText(partialText: "")

                let rawBook = try await generateStoryWithRouting(
                    concept: safeConcept,
                    pageCount: pageCount
                )

                let book: StoryBook
                let analyses: [Int: PromptAnalysis]
                let parsedCharacters: [ImagePromptEnricher.CharacterEntry]

                if useCloudTextPath {
                    // Cloud LLMs produce good text and image prompts — skip all
                    // Foundation Model post-processing (repair, parse, analyze).
                    book = rawBook
                    analyses = [:]
                    parsedCharacters = ImagePromptEnricher.parseCharacterDescriptions(
                        rawBook.characterDescriptions
                    )
                    self.parsedCharacters = parsedCharacters
                } else {
                    // On-device / MLX path: run Foundation Model enrichment pipeline.

                    // Phase 1.2: Validate/repair character descriptions with Foundation Model
                    let repairedDescriptions = await CharacterDescriptionValidator.validateAsync(
                        descriptions: rawBook.characterDescriptions,
                        pages: rawBook.pages,
                        title: rawBook.title
                    )
                    let descriptionRepairedBook = StoryBook(
                        title: rawBook.title,
                        authorLine: rawBook.authorLine,
                        moral: rawBook.moral,
                        characterDescriptions: repairedDescriptions,
                        pages: rawBook.pages
                    )

                    // Phase 1.3: Parse character descriptions with Foundation Model
                    self.parsedCharacters = await ImagePromptEnricher.parseCharacterDescriptionsAsync(
                        descriptionRepairedBook.characterDescriptions
                    )
                    parsedCharacters = self.parsedCharacters

                    // Phase 1.5: Analyze image prompts with Foundation Model
                    let promptsToAnalyze = [(index: 0, prompt: ContentSafetyPolicy.safeCoverPrompt(
                        title: descriptionRepairedBook.title, concept: safeConcept
                    ))] + descriptionRepairedBook.pages.map { (index: $0.pageNumber, prompt: $0.imagePrompt) }
                    analyses = await PromptAnalysisEngine.analyzePrompts(promptsToAnalyze)

                    book = ImagePromptEnricher.enrichImagePrompts(
                        in: descriptionRepairedBook,
                        analyses: analyses,
                        parsedCharacters: parsedCharacters
                    )
                }

                storyBook = book

                // Phase 2: Generate illustrations
                let totalImages = book.pages.count + 1
                phase = .generatingImages(completedCount: 0, totalCount: totalImages)
                generatedImages = [:]

                let coverPrompt = ContentSafetyPolicy.safeCoverPrompt(
                    title: book.title,
                    concept: safeConcept
                )

                try await illustrationGenerator.generateIllustrations(
                    for: book.pages,
                    coverPrompt: coverPrompt,
                    characterDescriptions: book.characterDescriptions,
                    style: selectedStyle,
                    format: selectedFormat,
                    analyses: analyses,
                    parsedCharacters: parsedCharacters
                ) { [weak self] index, image in
                    guard let self else { return }
                    self.generatedImages[index] = image
                    let completed = self.generatedImages.count
                    self.phase = .generatingImages(completedCount: completed, totalCount: totalImages)
                }

                generatedImages = illustrationGenerator.generatedImages
                phase = .complete

            } catch is CancellationError {
                phase = .idle
            } catch let error as LanguageModelSession.GenerationError {
                if case .guardrailViolation = error {
                    phase = .failed(
                        "Apple's safety filter blocked this request. "
                        + "Please rephrase with gentler, child-friendly wording and try again."
                    )
                } else {
                    phase = .failed(error.localizedDescription)
                }
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    // MARK: - Author Mode Generation

    /// Assemble a StoryBook from author-written text, generate image prompts,
    /// run the full enrichment + illustration pipeline.
    func illustrateAuthorStory() {
        guard canIllustrateAuthorStory else { return }

        generationTask = Task {
            do {
                phase = .generatingText(partialText: "Preparing your story...")

                // Build pages from author input, filtering out empty pages
                let filledPages = authorPages.enumerated().compactMap { offset, text -> (pageNumber: Int, text: String)? in
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return nil }
                    return (pageNumber: offset + 1, text: trimmed)
                }

                guard !filledPages.isEmpty else {
                    phase = .failed("Please write text for at least one page.")
                    return
                }

                let safeTitle = authorTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                let charDescriptions = authorCharacterDescriptions.trimmingCharacters(in: .whitespacesAndNewlines)

                // Generate image prompts via Foundation Models (or heuristic fallback)
                let promptSheet = try await AuthorImagePromptGenerator.generateImagePrompts(
                    characterDescriptions: charDescriptions,
                    pages: filledPages,
                    onProgress: { [weak self] text in
                        guard let self else { return }
                        self.phase = .generatingText(partialText: text)
                    }
                )

                // Merge author text + generated prompts into a StoryBook
                let promptsByPage = Dictionary(
                    promptSheet.prompts.map { ($0.pageNumber, $0.imagePrompt) },
                    uniquingKeysWith: { _, last in last }
                )

                let storyPages = filledPages.enumerated().map { offset, page -> StoryPage in
                    let pageNumber = offset + 1
                    let prompt = promptsByPage[page.pageNumber]?
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let fallbackPrompt = ContentSafetyPolicy.safeIllustrationPrompt(
                        "A gentle children's book illustration for a story page"
                    )
                    return StoryPage(
                        pageNumber: pageNumber,
                        text: page.text,
                        imagePrompt: prompt.isEmpty ? fallbackPrompt : prompt
                    )
                }

                let rawBook = StoryBook(
                    title: safeTitle,
                    authorLine: "Written by You",
                    moral: "",
                    characterDescriptions: charDescriptions,
                    pages: storyPages
                )

                // Run the same enrichment pipeline as squeezeStory()
                let repairedDescriptions = await CharacterDescriptionValidator.validateAsync(
                    descriptions: rawBook.characterDescriptions,
                    pages: rawBook.pages,
                    title: rawBook.title
                )
                let descriptionRepairedBook = StoryBook(
                    title: rawBook.title,
                    authorLine: rawBook.authorLine,
                    moral: rawBook.moral,
                    characterDescriptions: repairedDescriptions,
                    pages: rawBook.pages
                )

                self.parsedCharacters = await ImagePromptEnricher.parseCharacterDescriptionsAsync(
                    descriptionRepairedBook.characterDescriptions
                )
                let parsedCharacters = self.parsedCharacters

                let coverPrompt = AuthorImagePromptGenerator.coverPrompt(title: safeTitle)
                let promptsToAnalyze = [(index: 0, prompt: coverPrompt)]
                    + descriptionRepairedBook.pages.map { (index: $0.pageNumber, prompt: $0.imagePrompt) }
                let analyses = await PromptAnalysisEngine.analyzePrompts(promptsToAnalyze)

                let book = ImagePromptEnricher.enrichImagePrompts(
                    in: descriptionRepairedBook,
                    analyses: analyses,
                    parsedCharacters: parsedCharacters
                )
                storyBook = book

                // Generate illustrations
                let totalImages = book.pages.count + 1
                phase = .generatingImages(completedCount: 0, totalCount: totalImages)
                generatedImages = [:]

                try await illustrationGenerator.generateIllustrations(
                    for: book.pages,
                    coverPrompt: coverPrompt,
                    characterDescriptions: book.characterDescriptions,
                    style: selectedStyle,
                    format: selectedFormat,
                    analyses: analyses,
                    parsedCharacters: parsedCharacters
                ) { [weak self] index, image in
                    guard let self else { return }
                    self.generatedImages[index] = image
                    let completed = self.generatedImages.count
                    self.phase = .generatingImages(completedCount: completed, totalCount: totalImages)
                }

                generatedImages = illustrationGenerator.generatedImages
                phase = .complete

            } catch is CancellationError {
                phase = .idle
            } catch let error as LanguageModelSession.GenerationError {
                if case .guardrailViolation = error {
                    phase = .failed(
                        "Apple's safety filter blocked this request. "
                        + "Please rephrase with gentler, child-friendly wording and try again."
                    )
                } else {
                    phase = .failed(error.localizedDescription)
                }
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    // MARK: - Prompt Suggestions

    func generateSuggestions() {
        guard !suggestionsGenerated else { return }
        suggestionsGenerated = true

        suggestionsTask = Task {
            let concepts = await SuggestionGenerator.generate()
            promptSuggestions = concepts ?? SuggestionGenerator.randomFallback()
            startSuggestionCycle()
        }
    }

    func stopSuggestionCycle() {
        suggestionRestartTask?.cancel()
        suggestionRestartTask = nil
        suggestionCycleTask?.cancel()
        suggestionCycleTask = nil
        suggestionDisplayText = ""
        activeSuggestion = nil
        suggestionOpacity = 0
        isSuggestionCycleActive = false
    }

    /// Restart the suggestion cycle after a brief delay (e.g. when the user clears the text).
    func restartSuggestionCycleAfterDelay() {
        suggestionRestartTask?.cancel()
        suggestionRestartTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            guard storyConcept.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            startSuggestionCycle()
        }
    }

    private func startSuggestionCycle() {
        guard !promptSuggestions.isEmpty else { return }
        stopSuggestionCycle()
        isSuggestionCycleActive = true

        suggestionCycleTask = Task {
            while !Task.isCancelled {
                let suggestion = promptSuggestions[currentSuggestionIndex % promptSuggestions.count]
                activeSuggestion = suggestion

                // Type out character by character
                suggestionOpacity = 1.0
                for i in 1...suggestion.count {
                    guard !Task.isCancelled else { return }
                    suggestionDisplayText = String(suggestion.prefix(i))
                    try? await Task.sleep(for: .milliseconds(30))
                }

                // Hold for a few seconds so the user can read it
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .seconds(3))

                // Fade out
                guard !Task.isCancelled else { return }
                suggestionOpacity = 0
                try? await Task.sleep(for: .milliseconds(600))

                // Clear and advance to the next suggestion
                guard !Task.isCancelled else { return }
                suggestionDisplayText = ""
                activeSuggestion = nil
                currentSuggestionIndex += 1

                // Brief pause before next
                try? await Task.sleep(for: .milliseconds(400))
            }
        }
    }

    // MARK: - Cancellation & Reset

    func cancel() {
        generationTask?.cancel()
        generationTask = nil
        suggestionsTask?.cancel()
        stopSuggestionCycle()
        storyGenerator.cancel()
        phase = .idle
    }

    func reset() {
        cancel()
        storyBook = nil
        generatedImages = [:]
        parsedCharacters = []
        authorTitle = ""
        authorCharacterDescriptions = ""
        authorPages = ["", "", "", ""]
        suggestionsGenerated = false
        currentSuggestionIndex = 0
        phase = .idle
    }

    /// Observe the story generator state to relay partial text to our phase.
    func syncTextProgress() {
        if case .generating(let partialText) = storyGenerator.state {
            phase = .generatingText(partialText: partialText)
        }
    }

    private func generateStoryWithRouting(
        concept: String,
        pageCount: Int
    ) async throws -> StoryBook {
        let settings = ModelSelectionStore.load()
        switch settings.textProvider {
        case .appleFoundation:
            return try await generateFoundationRoutedStory(
                concept: concept,
                pageCount: pageCount
            )

        case .mlxSwift:
            phase = .generatingText(partialText: "Using MLX model for story drafting...")
            do {
                return try await mlxStoryGenerator.generateStory(
                    concept: concept,
                    pageCount: pageCount,
                    onProgress: { [weak self] partialText in
                        guard let self else { return }
                        self.phase = .generatingText(partialText: partialText)
                    }
                )
            } catch {
                if settings.enableFoundationFallback {
                    phase = .generatingText(partialText: "MLX model unavailable, switching to Apple Foundation path...")
                    return try await generateFoundationRoutedStory(
                        concept: concept,
                        pageCount: pageCount
                    )
                } else {
                    throw error
                }
            }

        case .openRouter, .togetherAI, .huggingFace:
            return try await generateCloudStory(
                concept: concept,
                pageCount: pageCount,
                provider: settings.textProvider.cloudProvider!,
                enableFallback: settings.enableFoundationFallback
            )
        }
    }

    private func generateCloudStory(
        concept: String,
        pageCount: Int,
        provider: CloudProvider,
        enableFallback: Bool
    ) async throws -> StoryBook {
        let generator = CloudTextGenerator(cloudProvider: provider)
        phase = .generatingText(partialText: "Using \(provider.displayName) for story drafting...")
        return try await generator.generateStory(
            concept: concept,
            pageCount: pageCount,
            onProgress: { [weak self] partialText in
                guard let self else { return }
                self.phase = .generatingText(partialText: partialText)
            }
        )
    }

    private func generateFoundationRoutedStory(
        concept: String,
        pageCount: Int
    ) async throws -> StoryBook {
        if remoteStoryGenerator.isConfigured {
            phase = .generatingText(partialText: "Using larger model for story drafting...")
            do {
                return try await remoteStoryGenerator.generateStory(
                    concept: concept,
                    pageCount: pageCount
                )
            } catch {
                if storyGenerator.isAvailable {
                    phase = .generatingText(partialText: "Large model unavailable, switching to on-device model...")
                } else {
                    throw error
                }
            }
        }

        return try await storyGenerator.generateStory(
            concept: concept,
            pageCount: pageCount
        ) { [weak self] partialText in
            guard let self else { return }
            self.phase = .generatingText(partialText: partialText)
        }
    }
}
