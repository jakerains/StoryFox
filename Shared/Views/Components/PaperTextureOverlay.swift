import SwiftUI

/// A subtle tiling paper texture overlay that blends over gradient backgrounds
/// using multiply blend mode. Mimics real parchment paper grain.
///
/// Usage: Layer on top of a gradient background inside a ZStack:
/// ```
/// ZStack {
///     LinearGradient(...)
///     PaperTextureOverlay()
/// }
/// ```
struct PaperTextureOverlay: View {
    var opacity: Double = 0.40

    var body: some View {
#if os(macOS)
        tiledTexture
            .opacity(opacity)
            .blendMode(.multiply)
            .allowsHitTesting(false)
#else
        tiledTexture
            .opacity(opacity)
            .blendMode(.multiply)
            .allowsHitTesting(false)
#endif
    }

    @ViewBuilder
    private var tiledTexture: some View {
#if os(macOS)
        if let nsImage = NSImage(named: "PaperTexture") {
            Color(nsColor: NSColor(patternImage: scaled(nsImage, to: 512)))
        }
#else
        if let uiImage = UIImage(named: "PaperTexture") {
            Color(uiColor: UIColor(patternImage: scaled(uiImage, to: 512)))
        }
#endif
    }

#if os(macOS)
    private func scaled(_ image: NSImage, to size: CGFloat) -> NSImage {
        let targetSize = NSSize(width: size, height: size)
        let resized = NSImage(size: targetSize)
        resized.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: targetSize),
                   from: .zero, operation: .copy, fraction: 1.0)
        resized.unlockFocus()
        return resized
    }
#else
    private func scaled(_ image: UIImage, to size: CGFloat) -> UIImage {
        let targetSize = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
#endif
}
