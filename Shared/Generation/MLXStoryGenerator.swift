import Foundation
import Hub
import MLXLLM
import MLXLMCommon

enum MLXStoryGeneratorError: LocalizedError {
    case missingModelID
    case emptyModelResponse

    var errorDescription: String? {
        switch self {
        case .missingModelID:
            return "No MLX model ID is configured."
        case .emptyModelResponse:
            return "MLX model returned an empty response."
        }
    }
}

private actor MLXStoryRuntime {
    static let shared = MLXStoryRuntime()

    private var cachedModelID: String?
    private var cachedContainer: ModelContainer?

    func loadContainer(
        modelID: String,
        hub: HubApi,
        progressHandler: @Sendable @escaping (Progress) -> Void
    ) async throws -> ModelContainer {
        if cachedModelID == modelID, let cachedContainer {
            return cachedContainer
        }

        let configuration = ModelConfiguration(id: modelID)
        let container = try await LLMModelFactory.shared.loadContainer(
            hub: hub,
            configuration: configuration,
            progressHandler: progressHandler
        )

        cachedModelID = modelID
        cachedContainer = container
        return container
    }
}

struct MLXStoryGenerator: StoryTextGenerating, Sendable {
    private let runtime = MLXStoryRuntime.shared
    private let settingsProvider: @Sendable () -> ModelSelectionSettings

    init(
        settingsProvider: @escaping @Sendable () -> ModelSelectionSettings = { ModelSelectionStore.load() }
    ) {
        self.settingsProvider = settingsProvider
    }

    var availability: StoryProviderAvailability {
        get async {
            let settings = settingsProvider()
            let modelID = settings.mlxModelID.trimmingCharacters(in: .whitespacesAndNewlines)
            if modelID.isEmpty {
                return .unavailable(reason: "Set an MLX model ID in Settings first.")
            }
            return .available
        }
    }

    func prewarmModel(
        onProgress: @escaping @Sendable (String) -> Void = { _ in }
    ) async throws {
        let settings = settingsProvider()
        let modelID = try resolvedModelID(from: settings)
        let hub = makeHubAPI(settings: settings)

        _ = try await runtime.loadContainer(
            modelID: modelID,
            hub: hub
        ) { progress in
            onProgress("Downloading MLX model… \(Int(progress.fractionCompleted * 100))%")
        }
    }

    func generateStory(
        concept: String,
        pageCount: Int,
        onProgress: @escaping @MainActor @Sendable (String) -> Void = { _ in }
    ) async throws -> StoryBook {
        let settings = settingsProvider()
        let modelID = try resolvedModelID(from: settings)
        let safeConcept = ContentSafetyPolicy.sanitizeConcept(concept)
        let hub = makeHubAPI(settings: settings)

        let container = try await runtime.loadContainer(
            modelID: modelID,
            hub: hub
        ) { progress in
            let message = "Downloading MLX model… \(Int(progress.fractionCompleted * 100))%"
            Task { @MainActor in
                onProgress(message)
            }
        }

        await onProgress("MLX model loaded. Drafting story…")

        let userInput = UserInput(
            chat: [
                .system(StoryPromptTemplates.jsonModeSystemInstructions),
                .user(StoryPromptTemplates.userPrompt(concept: safeConcept, pageCount: pageCount))
            ]
        )

        let lmInput = try await container.prepare(input: userInput)
        let parameters = GenerateParameters(
            maxTokens: GenerationConfig.maximumResponseTokens(for: pageCount),
            temperature: Float(GenerationConfig.defaultTemperature)
        )
        let stream = try await container.generate(
            input: lmInput,
            parameters: parameters
        )

        var fullText = ""
        var hasReportedDraftingState = false
        var iterator = stream.makeAsyncIterator()
        while let generation = await iterator.next() {
            if Task.isCancelled {
                throw CancellationError()
            }
            if let chunk = generation.chunk, !chunk.isEmpty {
                fullText += chunk
                if !hasReportedDraftingState {
                    hasReportedDraftingState = true
                    await onProgress("Drafting pages and illustration prompts...")
                }
            }
        }

        let trimmed = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw MLXStoryGeneratorError.emptyModelResponse
        }

        let dto = try StoryDecoding.decodeStoryDTO(from: trimmed)
        let story = dto.toStoryBook(
            pageCount: pageCount,
            fallbackConcept: safeConcept
        )
        guard !story.pages.isEmpty else {
            throw StoryDecodingError.contentRejected
        }
        return story
    }

    private func resolvedModelID(from settings: ModelSelectionSettings) throws -> String {
        let modelID = settings.mlxModelID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !modelID.isEmpty else {
            throw MLXStoryGeneratorError.missingModelID
        }
        return modelID
    }

    private func makeHubAPI(settings: ModelSelectionSettings) -> HubApi {
        if let token = HFTokenStore.loadToken(alias: settings.resolvedHFTokenAlias),
           !token.isEmpty {
            setenv("HF_TOKEN", token, 1)
            setenv("HUGGING_FACE_HUB_TOKEN", token, 1)
        }

        let downloadBase = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first
        return HubApi(downloadBase: downloadBase)
    }

    // Prompt templates are centralized in StoryPromptTemplates — no local copies.
}
