import CoreGraphics
import Foundation

protocol StoryImageGenerating: Sendable {
    var provider: StoryImageProvider { get }

    func generateImage(
        prompt: String,
        style: IllustrationStyle,
        format: BookFormat,
        settings: ModelSelectionSettings,
        onStatus: @Sendable @escaping (String) -> Void
    ) async throws -> CGImage
}
