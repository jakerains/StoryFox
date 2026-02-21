import Foundation
import FoundationModels

enum StoryGenerationState: Sendable {
    case idle
    case generating(partialText: String)
    case complete(StoryBook)
    case failed(Error)

    var isGenerating: Bool {
        if case .generating = self { return true }
        return false
    }
}

@Observable
@MainActor
final class StoryGenerator {

    private(set) var state: StoryGenerationState = .idle
    private var generationTask: Task<Void, Never>?

    /// Check if the on-device language model is available.
    var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    /// The reason the model is unavailable, if applicable.
    var unavailabilityReason: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
#if os(macOS)
                return "This Mac doesn't support Apple Intelligence. An Apple Silicon Mac is required."
#else
                return "This device doesn't support Apple Intelligence. A compatible iPhone or iPad is required."
#endif
            case .appleIntelligenceNotEnabled:
                return "Apple Intelligence is not enabled. Please enable it in System Settings."
            case .modelNotReady:
                return "The language model is still downloading. Please try again shortly."
            @unknown default:
                return "The on-device language model is currently unavailable."
            }
        @unknown default:
            return "The on-device language model is currently unavailable."
        }
    }

    /// Generate a storybook from a concept using the on-device LLM.
    /// Retries automatically on guardrail false positives.
    func generateStory(
        concept: String,
        pageCount: Int,
        onProgress: @escaping @MainActor @Sendable (String) -> Void = { _ in }
    ) async throws -> StoryBook {
        state = .generating(partialText: "")
        onProgress("")

        var lastError: Error?

        for attempt in 0...GenerationConfig.guardrailRetryAttempts {
            do {
                let book = try await attemptGeneration(
                    concept: concept,
                    pageCount: pageCount,
                    onProgress: onProgress
                )
                state = .complete(book)
                return book
            } catch let error as LanguageModelSession.GenerationError {
                if case .guardrailViolation = error,
                   attempt < GenerationConfig.guardrailRetryAttempts {
                    // Guardrail false positive — retry with a fresh session
                    lastError = error
                    state = .generating(partialText: "Safety filter triggered, retrying...")
                    onProgress("Safety filter triggered, retrying...")
                    try await Task.sleep(for: .milliseconds(500))
                    continue
                }
                throw error
            }
        }

        // Should not reach here, but just in case
        throw lastError ?? StoryGeneratorError.emptyResponse
    }

    /// Single generation attempt with streaming progress.
    private func attemptGeneration(
        concept: String,
        pageCount: Int,
        onProgress: @escaping @MainActor @Sendable (String) -> Void
    ) async throws -> StoryBook {
        let session = LanguageModelSession(
            instructions: StoryPromptTemplates.systemInstructions
        )

        let safeConcept = ContentSafetyPolicy.sanitizeConcept(concept)
        let prompt = StoryPromptTemplates.structuredOutputPrompt(
            concept: safeConcept,
            pageCount: pageCount
        )

        let options = GenerationOptions(
            temperature: Double(GenerationConfig.defaultTemperature),
            maximumResponseTokens: GenerationConfig.maximumResponseTokens(for: pageCount)
        )

        let stream = session.streamResponse(
            to: prompt,
            generating: StoryBook.self,
            options: options
        )

        // Stream partial results to show progress
        for try await snapshot in stream {
            let partial = snapshot.content
            let pages = partial.pages ?? []
            let previewText = pages.compactMap(\.text).joined(separator: "\n\n")
            state = .generating(partialText: previewText)
            onProgress(previewText)
        }

        let response = try await stream.collect()
        return response.content
    }

    /// Cancel any in-progress generation.
    func cancel() {
        generationTask?.cancel()
        generationTask = nil
        state = .idle
    }

    func reset() {
        cancel()
        state = .idle
    }
}

enum StoryGeneratorError: LocalizedError {
    case emptyResponse
    case modelUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            "The story generator returned an empty response. Please try again."
        case .modelUnavailable(let reason):
            reason
        }
    }
}
