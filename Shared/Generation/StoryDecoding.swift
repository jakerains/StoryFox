import Foundation

enum StoryDecodingError: LocalizedError {
    case unparsableResponse
    case contentRejected

    var errorDescription: String? {
        switch self {
        case .unparsableResponse:
            return "Model response could not be parsed into a story."
        case .contentRejected:
            return "Model response did not include valid pages."
        }
    }
}

struct StoryDTO: Decodable {
    let title: String
    let authorLine: String
    let moral: String
    let pages: [StoryPageDTO]

    func toStoryBook(pageCount: Int, fallbackConcept: String) -> StoryBook {
        let orderedPages = pages
            .sorted { $0.pageNumber < $1.pageNumber }
            .prefix(pageCount)
            .enumerated()
            .map { offset, page -> StoryPage in
                let pageNumber = offset + 1
                let safeText = StoryTextCleanup.clean(page.text)
                let safePrompt = page.imagePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
                let fallbackPrompt = ContentSafetyPolicy.safeIllustrationPrompt(
                    "A gentle scene inspired by \(fallbackConcept)"
                )

                return StoryPage(
                    pageNumber: pageNumber,
                    text: safeText.isEmpty ? "A gentle moment unfolds." : safeText,
                    imagePrompt: safePrompt.isEmpty ? fallbackPrompt : safePrompt
                )
            }

        let cleanTitle = StoryTextCleanup.clean(title)
        let cleanAuthor = StoryTextCleanup.clean(authorLine)
        let cleanMoral = StoryTextCleanup.clean(moral)

        return StoryBook(
            title: cleanTitle.isEmpty ? "StoryFox Book" : cleanTitle,
            authorLine: cleanAuthor.isEmpty ? "Written by StoryFox" : cleanAuthor,
            moral: cleanMoral.isEmpty ? "Kindness and curiosity guide every adventure." : cleanMoral,
            pages: orderedPages
        )
    }
}

/// Strips markdown formatting artifacts that cloud and MLX models often
/// embed in JSON string values (bold, italic, headings, etc.) and
/// normalizes whitespace so story text renders cleanly in the reader, PDF,
/// and EPUB exports.
enum StoryTextCleanup {
    static func clean(_ text: String) -> String {
        var s = text

        // Strip markdown bold/italic wrappers: ***bold italic***, **bold**, *italic*, __bold__, _italic_
        // Process longest patterns first so we don't leave orphaned markers.
        s = s.replacingOccurrences(of: "\\*{3}(.+?)\\*{3}", with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: "\\*{2}(.+?)\\*{2}", with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: "(?<=\\s|^)\\*(?=\\S)(.+?)(?<=\\S)\\*(?=\\s|$|[.,!?])", with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: "__(.+?)__", with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: "(?<=\\s|^)_(?=\\S)(.+?)(?<=\\S)_(?=\\s|$|[.,!?])", with: "$1", options: .regularExpression)

        // Strip markdown heading prefixes (# Title, ## Subtitle, etc.)
        s = s.replacingOccurrences(of: "(?m)^#{1,6}\\s+", with: "", options: .regularExpression)

        // Normalize smart/curly quotes to straight quotes
        s = s.replacingOccurrences(of: "\u{201C}", with: "\"") // left double
        s = s.replacingOccurrences(of: "\u{201D}", with: "\"") // right double
        s = s.replacingOccurrences(of: "\u{2018}", with: "'")  // left single
        s = s.replacingOccurrences(of: "\u{2019}", with: "'")  // right single

        // Strip wrapping quotes that some models put around the entire value
        if s.hasPrefix("\"") && s.hasSuffix("\"") && s.count > 2 {
            s = String(s.dropFirst().dropLast())
        }

        // Collapse multiple whitespace/newlines into a single space
        s = s.replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)

        // Final trim
        s = s.trimmingCharacters(in: .whitespacesAndNewlines)

        return s
    }
}

struct StoryPageDTO: Decodable {
    let pageNumber: Int
    let text: String
    let imagePrompt: String
}

private struct StoryEnvelopeDTO: Decodable {
    let story: StoryDTO
}

enum StoryDecoding {
    static func decodeStoryDTO(from data: Data) throws -> StoryDTO {
        let decoder = JSONDecoder()
        if let story = try? decoder.decode(StoryDTO.self, from: data) {
            return story
        }
        if let envelope = try? decoder.decode(StoryEnvelopeDTO.self, from: data) {
            return envelope.story
        }
        if let content = extractTextContent(from: data),
           let json = extractFirstJSONObjectString(from: content)?.data(using: .utf8),
           let story = try? decoder.decode(StoryDTO.self, from: json) {
            return story
        }
        throw StoryDecodingError.unparsableResponse
    }

    static func decodeStoryDTO(from text: String) throws -> StoryDTO {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw StoryDecodingError.unparsableResponse
        }

        let decoder = JSONDecoder()
        if let data = trimmed.data(using: .utf8),
           let story = try? decoder.decode(StoryDTO.self, from: data) {
            return story
        }

        if let jsonString = extractFirstJSONObjectString(from: trimmed),
           let data = jsonString.data(using: .utf8),
           let story = try? decoder.decode(StoryDTO.self, from: data) {
            return story
        }

        throw StoryDecodingError.unparsableResponse
    }

    static func extractTextContent(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        if let content = object["content"] as? String {
            return content
        }

        if let story = object["story"] as? [String: Any],
           let storyData = try? JSONSerialization.data(withJSONObject: story),
           let storyJSON = String(data: storyData, encoding: .utf8) {
            return storyJSON
        }

        if let choices = object["choices"] as? [[String: Any]],
           let first = choices.first,
           let message = first["message"] as? [String: Any] {
            if let content = message["content"] as? String {
                return content
            }
            if let contentItems = message["content"] as? [[String: Any]] {
                let parts = contentItems.compactMap { item -> String? in
                    if let text = item["text"] as? String {
                        return text
                    }
                    if let text = item["output_text"] as? String {
                        return text
                    }
                    return nil
                }
                if !parts.isEmpty {
                    return parts.joined(separator: "\n")
                }
            }
        }

        return nil
    }

    static func extractFirstJSONObjectString(from text: String) -> String? {
        guard let firstBrace = text.firstIndex(of: "{"),
              let lastBrace = text.lastIndex(of: "}") else {
            return nil
        }
        return String(text[firstBrace...lastBrace])
    }
}
