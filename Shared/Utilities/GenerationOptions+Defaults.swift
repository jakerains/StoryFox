import Foundation

struct GenerationConfig: Sendable {
    #if os(macOS)
    // Image Playground is most reliable when requests are serialized.
    static let maxConcurrentImages = 1
    #else
    static let maxConcurrentImages = 1
    #endif

    static let defaultTemperature: Float = 1.2

    /// Estimate token budget based on page count.
    /// Each page needs ~100-150 tokens for text + imagePrompt, plus overhead for title/moral/structure.
    static func maximumResponseTokens(for pageCount: Int) -> Int {
        let perPageTokens = 150
        let overhead = 200
        return (perPageTokens * pageCount) + overhead
    }

    static let minPages = 4
    static let maxPages = 16
    static let defaultPages = 8

    /// Max retry attempts when a guardrail false positive is detected.
    static let guardrailRetryAttempts = 1

    /// Timeout for one Image Playground request before moving to the next prompt variant.
    static let imagePlaygroundGenerationTimeoutSeconds: TimeInterval = 45

    /// Number of sequential recovery rounds for pages that failed in the parallel pass.
    static let imageRecoveryPasses = 3

    /// Timeout for a single local Diffusers image generation call.
    static let diffusersGenerationTimeoutSeconds: TimeInterval = 240

    /// Timeout for a single cloud text generation call.
    static let cloudTextGenerationTimeoutSeconds: TimeInterval = 120

    /// Timeout for a single cloud image generation call.
    static let cloudImageGenerationTimeoutSeconds: TimeInterval = 180
}
