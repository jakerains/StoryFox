import Foundation
import HuggingFace
import os

/// Cloud-based text generator that implements `StoryTextGenerating`.
/// Uses `InferenceClient` for HuggingFace, `OpenAICompatibleClient` for others.
struct CloudTextGenerator: StoryTextGenerating {
    private static let logger = Logger(subsystem: "com.storyfox.app", category: "CloudText")

    let cloudProvider: CloudProvider
    private let client: OpenAICompatibleClient
    private let settingsProvider: @Sendable () -> ModelSelectionSettings

    init(
        cloudProvider: CloudProvider,
        client: OpenAICompatibleClient = OpenAICompatibleClient(),
        settingsProvider: @escaping @Sendable () -> ModelSelectionSettings = { ModelSelectionStore.load() }
    ) {
        self.cloudProvider = cloudProvider
        self.client = client
        self.settingsProvider = settingsProvider
    }

    var availability: StoryProviderAvailability {
        get async {
            guard CloudCredentialStore.isAuthenticated(for: cloudProvider) else {
                return .unavailable(reason: "\(cloudProvider.displayName) is not configured. Add an API key in Settings.")
            }
            return .available
        }
    }

    func generateStory(
        concept: String,
        pageCount: Int,
        onProgress: @escaping @MainActor @Sendable (String) -> Void
    ) async throws -> StoryBook {
        guard let apiKey = CloudCredentialStore.bearerToken(for: cloudProvider) else {
            throw CloudProviderError.noAPIKey(cloudProvider)
        }

        let settings = settingsProvider()
        let modelID = textModelID(from: settings)
        let safeConcept = ContentSafetyPolicy.sanitizeConcept(concept)

        await onProgress("Generating story with \(cloudProvider.displayName)...")

        Self.logger.info("Starting cloud text generation: provider=\(cloudProvider.rawValue, privacy: .public) model=\(modelID, privacy: .public)")

        let responseText: String

        if cloudProvider == .huggingFace {
            // Use official HuggingFace SDK
            responseText = try await generateWithHFSDK(
                apiKey: apiKey,
                model: modelID,
                concept: safeConcept,
                pageCount: pageCount
            )
        } else {
            // Use OpenAI-compatible client for OpenRouter / Together AI
            let data = try await client.chatCompletion(
                url: cloudProvider.chatCompletionURL,
                apiKey: apiKey,
                model: modelID,
                systemPrompt: StoryPromptTemplates.systemInstructions,
                userPrompt: StoryPromptTemplates.userPrompt(concept: safeConcept, pageCount: pageCount),
                temperature: 0.7,
                maxTokens: GenerationConfig.maximumResponseTokens(for: pageCount) * 2,
                extraHeaders: cloudProvider.extraHeaders
            )
            // Extract text content from OpenAI-compatible response
            if let text = StoryDecoding.extractTextContent(from: data) {
                responseText = text
            } else if let rawText = String(data: data, encoding: .utf8) {
                responseText = rawText
            } else {
                throw CloudProviderError.unparsableResponse
            }
        }

        await onProgress("Parsing story response...")

        let dto = try StoryDecoding.decodeStoryDTO(from: responseText)
        let story = dto.toStoryBook(
            pageCount: pageCount,
            fallbackConcept: safeConcept
        )

        guard !story.pages.isEmpty else {
            throw StoryDecodingError.contentRejected
        }

        Self.logger.info("Cloud text generation complete: \(story.pages.count) pages")
        return story
    }

    // MARK: - HuggingFace SDK Path

    private func generateWithHFSDK(
        apiKey: String,
        model: String,
        concept: String,
        pageCount: Int
    ) async throws -> String {
        let hfClient = InferenceClient(host: InferenceClient.defaultHost, bearerToken: apiKey)

        let messages: [ChatCompletion.Message] = [
            .init(role: .system, content: .text(StoryPromptTemplates.systemInstructions)),
            .init(role: .user, content: .text(StoryPromptTemplates.userPrompt(concept: concept, pageCount: pageCount)))
        ]

        let response = try await hfClient.chatCompletion(
            model: model,
            messages: messages,
            temperature: 0.7,
            maxTokens: GenerationConfig.maximumResponseTokens(for: pageCount) * 2
        )

        // Extract text from the first choice
        guard let choice = response.choices.first else {
            throw CloudProviderError.unparsableResponse
        }

        switch choice.message.content {
        case .text(let text):
            return text
        case .mixed(let items):
            let textParts = items.compactMap { item -> String? in
                if case .text(let text) = item { return text }
                return nil
            }
            return textParts.joined(separator: "\n")
        case .none:
            throw CloudProviderError.unparsableResponse
        }
    }

    // MARK: - Helpers

    private func textModelID(from settings: ModelSelectionSettings) -> String {
        let modelID: String
        switch cloudProvider {
        case .openRouter:  modelID = settings.openRouterTextModelID
        case .togetherAI:  modelID = settings.togetherTextModelID
        case .huggingFace: modelID = settings.huggingFaceTextModelID
        }
        return modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? cloudProvider.defaultTextModelID
            : modelID
    }
}
