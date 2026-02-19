import Foundation

protocol StoryTextGenerating: Sendable {
    var availability: StoryProviderAvailability { get async }

    func generateStory(
        concept: String,
        pageCount: Int,
        onProgress: @escaping @MainActor @Sendable (String) -> Void
    ) async throws -> StoryBook
}
