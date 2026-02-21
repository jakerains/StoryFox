import Foundation

/// Validates and repairs character descriptions produced by small models.
/// If the model returned empty, too short, or poorly formatted descriptions,
/// this validator extracts character names from image prompts as a fallback.
/// The harness does the heavy lifting — we don't rely on the model to be consistent.
enum CharacterDescriptionValidator {

    /// Validate character descriptions and attempt repair if inadequate.
    /// Returns the original if good, or a best-effort extraction from story content.
    static func validate(
        descriptions: String,
        pages: [StoryPage],
        title: String
    ) -> String {
        let cleaned = normalize(descriptions)

        // If the model produced adequate descriptions, use them.
        if isAdequate(cleaned) {
            return cleaned
        }

        // Otherwise, try to extract character info from image prompts.
        let extracted = extractFromImagePrompts(pages: pages)

        if !extracted.isEmpty {
            // If we had partial descriptions, merge them
            if !cleaned.isEmpty {
                return cleaned + "\n" + extracted
            }
            return extracted
        }

        // Return whatever we have, even if weak
        return cleaned
    }

    // MARK: - Quality Check

    /// A description is "adequate" if it has at least one line with a character name
    /// and 4+ words of visual detail.
    private static func isAdequate(_ desc: String) -> Bool {
        guard !desc.isEmpty else { return false }

        let lines = desc
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { return false }

        // At least one line should have 4+ words (a name + some description).
        // We check for a dash separator which is the format we requested,
        // but also accept lines with 5+ words even without a dash.
        return lines.contains { line in
            let words = line.split(whereSeparator: \.isWhitespace)
            let hasDashFormat = line.contains(" - ") && words.count >= 4
            let hasEnoughDetail = words.count >= 5
            return hasDashFormat || hasEnoughDetail
        }
    }

    // MARK: - Fallback Extraction

    /// Extract character names from image prompts.
    /// Our prompt template tells the model to "name the character first" in each imagePrompt,
    /// so the text before the first comma is likely a character name.
    private static func extractFromImagePrompts(pages: [StoryPage]) -> String {
        var characterNames: [String] = []

        for page in pages {
            let prompt = page.imagePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !prompt.isEmpty else { continue }

            // Extract text before first comma — likely the character name
            if let commaIndex = prompt.firstIndex(of: ",") {
                let candidate = String(prompt[..<commaIndex])
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                // Validate: character names start with uppercase, aren't too long,
                // and aren't scene descriptions (which tend to start with "A" or "The")
                if isLikelyCharacterName(candidate) {
                    let normalized = candidate
                        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                    if !characterNames.contains(normalized) {
                        characterNames.append(normalized)
                    }
                }
            }
        }

        guard !characterNames.isEmpty else { return "" }

        // Build minimal descriptions from extracted names.
        // We can also try to find color/appearance words near the name in the prompts.
        var descriptions: [String] = []
        for name in characterNames.prefix(4) {
            let details = findAppearanceDetails(for: name, in: pages)
            if details.isEmpty {
                descriptions.append("\(name) - main character")
            } else {
                descriptions.append("\(name) - \(details)")
            }
        }

        return descriptions.joined(separator: "\n")
    }

    /// Check if a string looks like a character name rather than a scene description.
    private static func isLikelyCharacterName(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        // Too long for a name (likely a sentence/description)
        let words = trimmed.split(whereSeparator: \.isWhitespace)
        guard words.count <= 5 else { return false }

        // Must start with an uppercase letter
        guard let first = trimmed.first, first.isUppercase else { return false }

        // Filter out common scene starters
        let lowerFirst = words.first.map { String($0).lowercased() } ?? ""
        let sceneStarters = ["a", "an", "the", "in", "on", "at", "with", "under", "inside", "outside"]
        if sceneStarters.contains(lowerFirst) { return false }

        return true
    }

    /// Scan image prompts for appearance-related words near a character name.
    private static func findAppearanceDetails(for name: String, in pages: [StoryPage]) -> String {
        let colorWords = Set([
            "red", "blue", "green", "yellow", "orange", "purple", "pink", "white",
            "black", "brown", "golden", "silver", "bright", "dark", "light",
            "spotted", "striped", "fluffy", "tiny", "small", "big", "tall"
        ])
        let clothingWords = Set([
            "dress", "hat", "scarf", "cape", "boots", "shirt", "coat", "crown",
            "ribbon", "bow", "glasses", "vest", "apron", "jacket"
        ])
        let speciesWords = Set([
            "fox", "rabbit", "bunny", "bear", "cat", "dog", "mouse", "owl",
            "deer", "bird", "dragon", "unicorn", "frog", "turtle", "squirrel",
            "hedgehog", "penguin", "lion", "wolf", "elephant", "puppy", "kitten"
        ])

        var foundDetails: [String] = []

        for page in pages {
            let lower = page.imagePrompt.lowercased()
            guard lower.contains(name.lowercased()) else { continue }

            let words = lower
                .replacingOccurrences(of: #"[^\p{L}\s]"#, with: " ", options: .regularExpression)
                .split(whereSeparator: \.isWhitespace)
                .map(String.init)

            for word in words {
                if speciesWords.contains(word) && !foundDetails.contains(word) {
                    foundDetails.insert(word, at: 0)  // species first
                }
                if colorWords.contains(word) && !foundDetails.contains(word) {
                    foundDetails.append(word)
                }
                if clothingWords.contains(word) && !foundDetails.contains(word) {
                    foundDetails.append(word)
                }
            }

            // Don't need to scan every page — a few is enough
            if foundDetails.count >= 3 { break }
        }

        return foundDetails.prefix(5).joined(separator: ", ")
    }

    // MARK: - Normalization

    /// Normalize character descriptions: ensure line breaks between characters,
    /// clean up whitespace, remove markdown artifacts.
    private static func normalize(_ desc: String) -> String {
        var cleaned = desc.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return "" }

        // Strip markdown formatting
        cleaned = StoryTextCleanup.clean(cleaned)

        // If the model put all characters on one line separated by periods,
        // try to split them into separate lines.
        // Pattern: "Name1 - desc1. Name2 - desc2." → split on ". " before uppercase
        if !cleaned.contains("\n") && cleaned.contains(" - ") {
            cleaned = cleaned.replacingOccurrences(
                of: #"\.\s+(?=[A-Z])"#,
                with: ".\n",
                options: .regularExpression
            )
        }

        // Normalize whitespace within lines
        let lines = cleaned
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return lines.joined(separator: "\n")
    }
}
