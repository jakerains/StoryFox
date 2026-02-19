import Foundation
import CoreGraphics
import AppKit
import PDFKit
import SwiftUI

struct MacPDFRenderer: PDFRendering {

    // MARK: - PDF Colors (static — no light/dark mode in printed documents)

    /// Warm cream background matching "Warm Library at Dusk" theme (#F6EEDF)
    private let creamBg = CGColor(red: 0.965, green: 0.933, blue: 0.875, alpha: 1.0)
    /// Primary text — dark warm brown (#1E1510)
    private let darkText = CGColor(red: 0.118, green: 0.082, blue: 0.063, alpha: 1.0)
    /// Secondary/muted text — medium brown (#6B5A4C)
    private let mutedText = CGColor(red: 0.420, green: 0.353, blue: 0.298, alpha: 1.0)
    /// Accent coral for dividers and ornaments (#B4543A)
    private let accentCoral = CGColor(red: 0.706, green: 0.329, blue: 0.227, alpha: 1.0)

    /// Margin in points (0.75 inches × 72 pts/inch)
    private let margin: CGFloat = 54
    /// Corner radius for image clipping
    private let imageCornerRadius: CGFloat = 8

    // MARK: - Public

    func render(storybook: StoryBook, images: [Int: CGImage], format: BookFormat) -> Data {
        // Use 72 DPI points (not 300 DPI pixels) — images render at native resolution automatically
        let pageSize = format.dimensions
        let contentRect = CGRect(
            x: margin,
            y: margin,
            width: pageSize.width - (margin * 2),
            height: pageSize.height - (margin * 2)
        )

        let pdfData = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let consumer = CGDataConsumer(data: pdfData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }

        renderTitlePage(context: context, storybook: storybook, coverImage: images[0],
                       pageSize: pageSize, contentRect: contentRect)

        for page in storybook.pages {
            renderContentPage(context: context, page: page, image: images[page.pageNumber],
                            pageSize: pageSize, contentRect: contentRect,
                            pageNumber: page.pageNumber, totalPages: storybook.pages.count)
        }

        renderEndPage(context: context, storybook: storybook,
                     pageSize: pageSize, contentRect: contentRect)

        context.closePDF()

        return pdfData as Data
    }

    // MARK: - Title Page

    private func renderTitlePage(context: CGContext, storybook: StoryBook,
                                  coverImage: CGImage?, pageSize: CGSize,
                                  contentRect: CGRect) {
        context.beginPDFPage(nil)
        fillBackground(context: context, pageSize: pageSize)

        // Cover illustration — top 55% of content area
        if let cover = coverImage {
            let imageHeight = contentRect.height * 0.55
            let imageRect = CGRect(
                x: contentRect.minX,
                y: contentRect.maxY - imageHeight,
                width: contentRect.width,
                height: imageHeight
            )
            drawRoundedImage(cover, in: imageRect, context: context)
        }

        // Decorative divider between image and title
        let dividerY = contentRect.minY + contentRect.height * 0.38
        drawDivider(context: context, y: dividerY, contentRect: contentRect)

        // Title — centered below divider
        let titleFont = CTFontCreateWithName("Georgia-Bold" as CFString, 30, nil)
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .center
        titleParagraphStyle.lineSpacing = 4
        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: darkText,
            .paragraphStyle: titleParagraphStyle
        ]
        let titleString = NSAttributedString(string: storybook.title, attributes: titleAttr)
        let titleFramesetter = CTFramesetterCreateWithAttributedString(titleString)
        let titleRect = CGRect(
            x: contentRect.minX + 20,
            y: contentRect.minY + contentRect.height * 0.12,
            width: contentRect.width - 40,
            height: contentRect.height * 0.24
        )
        let titlePath = CGPath(rect: titleRect, transform: nil)
        let titleFrame = CTFramesetterCreateFrame(titleFramesetter, CFRangeMake(0, 0), titlePath, nil)
        CTFrameDraw(titleFrame, context)

        // Author line — below title
        let authorFont = CTFontCreateWithName("Georgia-Italic" as CFString, 14, nil)
        let authorParagraphStyle = NSMutableParagraphStyle()
        authorParagraphStyle.alignment = .center
        let authorAttr: [NSAttributedString.Key: Any] = [
            .font: authorFont,
            .foregroundColor: mutedText,
            .paragraphStyle: authorParagraphStyle
        ]
        let authorString = NSAttributedString(string: storybook.authorLine, attributes: authorAttr)
        let authorFramesetter = CTFramesetterCreateWithAttributedString(authorString)
        let authorRect = CGRect(
            x: contentRect.minX,
            y: contentRect.minY,
            width: contentRect.width,
            height: contentRect.height * 0.1
        )
        let authorPath = CGPath(rect: authorRect, transform: nil)
        let authorFrame = CTFramesetterCreateFrame(authorFramesetter, CFRangeMake(0, 0), authorPath, nil)
        CTFrameDraw(authorFrame, context)

        context.endPDFPage()
    }

    // MARK: - Content Page

    private func renderContentPage(context: CGContext, page: StoryPage,
                                    image: CGImage?, pageSize: CGSize,
                                    contentRect: CGRect, pageNumber: Int, totalPages: Int) {
        context.beginPDFPage(nil)
        fillBackground(context: context, pageSize: pageSize)

        // Illustration — top 55% of content
        if let img = image {
            let imageHeight = contentRect.height * 0.55
            let imageRect = CGRect(
                x: contentRect.minX,
                y: contentRect.maxY - imageHeight,
                width: contentRect.width,
                height: imageHeight
            )
            drawRoundedImage(img, in: imageRect, context: context)
        }

        // Thin decorative divider
        let dividerY = contentRect.minY + contentRect.height * 0.38
        drawDivider(context: context, y: dividerY, contentRect: contentRect)

        // Story text — below divider
        let textFont = CTFontCreateWithName("Georgia" as CFString, 17, nil)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 6
        let textAttr: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: darkText,
            .paragraphStyle: paragraphStyle
        ]
        let textString = NSAttributedString(string: page.text, attributes: textAttr)
        let textFramesetter = CTFramesetterCreateWithAttributedString(textString)
        let textRect = CGRect(
            x: contentRect.minX + 16,
            y: contentRect.minY + contentRect.height * 0.06,
            width: contentRect.width - 32,
            height: contentRect.height * 0.30
        )
        let textPath = CGPath(rect: textRect, transform: nil)
        let textFrame = CTFramesetterCreateFrame(textFramesetter, CFRangeMake(0, 0), textPath, nil)
        CTFrameDraw(textFrame, context)

        // Page number — bottom center
        let pageNumFont = CTFontCreateWithName("Georgia" as CFString, 10, nil)
        let pageNumAttr: [NSAttributedString.Key: Any] = [
            .font: pageNumFont,
            .foregroundColor: mutedText
        ]
        let pageNumStr = NSAttributedString(string: "\(pageNumber)", attributes: pageNumAttr)
        let pageNumLine = CTLineCreateWithAttributedString(pageNumStr)
        let pageNumBounds = CTLineGetBoundsWithOptions(pageNumLine, .useOpticalBounds)
        context.textPosition = CGPoint(
            x: (pageSize.width - pageNumBounds.width) / 2,
            y: margin * 0.45
        )
        CTLineDraw(pageNumLine, context)

        context.endPDFPage()
    }

    // MARK: - End Page

    private func renderEndPage(context: CGContext, storybook: StoryBook,
                                pageSize: CGSize, contentRect: CGRect) {
        context.beginPDFPage(nil)
        fillBackground(context: context, pageSize: pageSize)

        // Top ornament
        drawOrnament(context: context, centerX: pageSize.width / 2,
                     y: pageSize.height * 0.62, fontSize: 14)

        // "The End"
        let endFont = CTFontCreateWithName("Georgia-Bold" as CFString, 36, nil)
        let endAttr: [NSAttributedString.Key: Any] = [
            .font: endFont,
            .foregroundColor: darkText
        ]
        let endString = NSAttributedString(string: "The End", attributes: endAttr)
        let endLine = CTLineCreateWithAttributedString(endString)
        let endBounds = CTLineGetBoundsWithOptions(endLine, .useOpticalBounds)
        context.textPosition = CGPoint(
            x: (pageSize.width - endBounds.width) / 2,
            y: pageSize.height * 0.55
        )
        CTLineDraw(endLine, context)

        // Bottom ornament
        drawOrnament(context: context, centerX: pageSize.width / 2,
                     y: pageSize.height * 0.50, fontSize: 14)

        // Moral
        let moralFont = CTFontCreateWithName("Georgia-Italic" as CFString, 14, nil)
        let moralParagraphStyle = NSMutableParagraphStyle()
        moralParagraphStyle.alignment = .center
        moralParagraphStyle.lineSpacing = 5
        let moralAttr: [NSAttributedString.Key: Any] = [
            .font: moralFont,
            .foregroundColor: mutedText,
            .paragraphStyle: moralParagraphStyle
        ]
        let moralString = NSAttributedString(string: storybook.moral, attributes: moralAttr)
        let moralFramesetter = CTFramesetterCreateWithAttributedString(moralString)
        let moralRect = CGRect(
            x: contentRect.minX + 40,
            y: pageSize.height * 0.35,
            width: contentRect.width - 80,
            height: pageSize.height * 0.13
        )
        let moralPath = CGPath(rect: moralRect, transform: nil)
        let moralFrame = CTFramesetterCreateFrame(moralFramesetter, CFRangeMake(0, 0), moralPath, nil)
        CTFrameDraw(moralFrame, context)

        context.endPDFPage()
    }

    // MARK: - Drawing Helpers

    /// Fills the entire page with warm cream background.
    private func fillBackground(context: CGContext, pageSize: CGSize) {
        context.setFillColor(creamBg)
        context.fill(CGRect(origin: .zero, size: pageSize))
    }

    /// Draws an image clipped to a rounded rectangle, aspect-ratio preserved.
    private func drawRoundedImage(_ image: CGImage, in rect: CGRect, context: CGContext) {
        let fitted = fitImage(image, in: rect)

        context.saveGState()
        let roundedPath = CGPath(roundedRect: fitted,
                                  cornerWidth: imageCornerRadius,
                                  cornerHeight: imageCornerRadius,
                                  transform: nil)
        context.addPath(roundedPath)
        context.clip()
        context.draw(image, in: fitted)
        context.restoreGState()
    }

    /// Draws a thin coral accent line with a small center ornament.
    private func drawDivider(context: CGContext, y: CGFloat, contentRect: CGRect) {
        let lineInset: CGFloat = contentRect.width * 0.15
        let leftStart = contentRect.minX + lineInset
        let rightEnd = contentRect.maxX - lineInset
        let centerX = contentRect.midX

        context.saveGState()
        context.setStrokeColor(accentCoral)
        context.setLineWidth(0.75)

        // Left segment
        context.move(to: CGPoint(x: leftStart, y: y))
        context.addLine(to: CGPoint(x: centerX - 12, y: y))
        context.strokePath()

        // Right segment
        context.move(to: CGPoint(x: centerX + 12, y: y))
        context.addLine(to: CGPoint(x: rightEnd, y: y))
        context.strokePath()

        // Center diamond ornament
        let diamondSize: CGFloat = 3.5
        context.move(to: CGPoint(x: centerX, y: y + diamondSize))
        context.addLine(to: CGPoint(x: centerX + diamondSize, y: y))
        context.addLine(to: CGPoint(x: centerX, y: y - diamondSize))
        context.addLine(to: CGPoint(x: centerX - diamondSize, y: y))
        context.closePath()
        context.setFillColor(accentCoral)
        context.fillPath()

        context.restoreGState()
    }

    /// Draws a decorative text ornament (centered).
    private func drawOrnament(context: CGContext, centerX: CGFloat, y: CGFloat, fontSize: CGFloat) {
        let ornamentFont = CTFontCreateWithName("Georgia" as CFString, fontSize, nil)
        let ornamentAttr: [NSAttributedString.Key: Any] = [
            .font: ornamentFont,
            .foregroundColor: accentCoral
        ]
        let ornamentStr = NSAttributedString(string: "—  ◆  —", attributes: ornamentAttr)
        let ornamentLine = CTLineCreateWithAttributedString(ornamentStr)
        let ornamentBounds = CTLineGetBoundsWithOptions(ornamentLine, .useOpticalBounds)
        context.textPosition = CGPoint(
            x: centerX - ornamentBounds.width / 2,
            y: y
        )
        CTLineDraw(ornamentLine, context)
    }

    /// Fits an image into a rect while preserving aspect ratio.
    private func fitImage(_ image: CGImage, in rect: CGRect) -> CGRect {
        let imageAspect = CGFloat(image.width) / CGFloat(image.height)
        let rectAspect = rect.width / rect.height

        if imageAspect > rectAspect {
            let height = rect.width / imageAspect
            let y = rect.midY - height / 2
            return CGRect(x: rect.minX, y: y, width: rect.width, height: height)
        } else {
            let width = rect.height * imageAspect
            let x = rect.midX - width / 2
            return CGRect(x: x, y: rect.minY, width: width, height: rect.height)
        }
    }
}
