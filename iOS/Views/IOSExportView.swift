import SwiftUI
import CoreGraphics

/// Handles PDF export on iOS by rendering to a temporary file and returning a URL
/// suitable for use with SwiftUI's `ShareLink`.
struct IOSExportView {
    /// Render the storybook to a temporary PDF file and return its URL.
    @MainActor
    static func renderPDFToFile(
        storybook: StoryBook,
        images: [Int: CGImage],
        format: BookFormat,
        renderer: PDFRendering
    ) -> URL {
        let pdfData = renderer.render(storybook: storybook, images: images, format: format)

        let sanitizedTitle = storybook.title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let filename = "\(sanitizedTitle).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        try? pdfData.write(to: tempURL)

        return tempURL
    }
}
