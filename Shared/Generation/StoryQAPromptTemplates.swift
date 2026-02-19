import Foundation

enum StoryQAPromptTemplates {

    // MARK: - System Instructions

    static func systemInstructions(for audience: AudienceMode) -> String {
        switch audience {
        case .kid:
            return """
            You are a friendly, enthusiastic story helper talking to a child! \
            Use simple, fun language. Keep questions short and exciting. \
            Make your suggested answers playful and imaginative — kids love \
            animals, magic, adventures, and silly things. \
            Always respond with valid JSON only — no extra text before or after.
            """
        case .adult:
            return """
            You are a creative story development consultant for illustrated picture books. \
            Ask thoughtful questions about characters, world-building, narrative arc, \
            and emotional tone. Your suggested answers should be specific, evocative, \
            and help the creator envision the story clearly. \
            Always respond with valid JSON only — no extra text before or after.
            """
        }
    }

    // MARK: - Question Generation

    static func questionGenerationPrompt(
        concept: String,
        roundNumber: Int,
        totalRounds: Int,
        previousQA: [(question: String, answer: String)],
        audience: AudienceMode
    ) -> String {
        var prompt = """
        Story concept: "\(concept)"

        """

        if !previousQA.isEmpty {
            prompt += "Previous answers from the creator:\n"
            for qa in previousQA {
                prompt += "- Q: \(qa.question)\n  A: \(qa.answer)\n"
            }
            prompt += "\n"
        }

        let focusGuidance = roundFocus(roundNumber, audience: audience)

        prompt += """
        This is round \(roundNumber) of \(totalRounds). \(focusGuidance)

        Generate exactly 3 questions. For each question, provide exactly 3 suggested \
        answers that are creative, specific, and \(audience == .kid ? "fun for kids" : "evocative").

        Return JSON with this exact shape (no markdown, no extra text):
        [
          {
            "question": "Your question here?",
            "suggestions": [
              "First suggestion",
              "Second suggestion",
              "Third suggestion"
            ]
          }
        ]
        """

        return prompt
    }

    // MARK: - Round Focus

    private static func roundFocus(_ round: Int, audience: AudienceMode) -> String {
        switch (round, audience) {
        case (1, .kid):
            return """
            Focus on the CHARACTERS and SETTING: \
            Who is the hero? What are they like? Where does the story happen? \
            Make questions exciting — kids love choosing cool characters and magical places!
            """
        case (1, .adult):
            return """
            Focus on the CHARACTERS and SETTING: \
            Who is the protagonist? What's their personality, motivation, and world? \
            What atmosphere and time period should the story evoke?
            """
        case (2, .kid):
            return """
            Focus on the ADVENTURE and CHALLENGE: \
            What problem does the hero face? Who helps them? What makes it exciting? \
            Think big — dragons, treasure hunts, mystery puzzles!
            """
        case (2, .adult):
            return """
            Focus on the PLOT and CONFLICT: \
            What challenge drives the narrative? What's at stake? \
            What complications or turning points should arise?
            """
        case (_, .kid):
            return """
            Focus on the ENDING and FEELINGS: \
            How does the story end? What happy thing happens? \
            What should kids feel when the story is over?
            """
        case (_, .adult):
            return """
            Focus on the TONE and RESOLUTION: \
            What emotional register should the story maintain? \
            How does it resolve — and what lasting impression should it leave?
            """
        }
    }

    // MARK: - Enriched Concept Compilation

    static func compileEnrichedConcept(
        originalConcept: String,
        rounds: [StoryQARound]
    ) -> String {
        var enriched = originalConcept

        let answeredPairs = rounds.flatMap { round in
            round.questions.filter(\.isAnswered).map { q in
                (q.questionText, q.userAnswer)
            }
        }

        guard !answeredPairs.isEmpty else { return enriched }

        enriched += "\n\nAdditional story details:\n"
        for (question, answer) in answeredPairs {
            enriched += "- \(question): \(answer)\n"
        }

        return enriched
    }

    // MARK: - JSON Parsing

    static func parseQuestions(from text: String) -> [StoryQuestion]? {
        let cleaned = extractJSONArray(from: text)
        guard let data = cleaned.data(using: .utf8) else { return nil }

        if let dtos = try? JSONDecoder().decode([QuestionDTO].self, from: data) {
            return dtos.map { $0.toStoryQuestion() }
        }

        return nil
    }

    private static func extractJSONArray(from text: String) -> String {
        // Try to find a JSON array in the text (handles markdown code blocks, etc.)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Direct array
        if trimmed.hasPrefix("[") {
            return trimmed
        }

        // Extract from markdown code block
        if let range = trimmed.range(of: #"\[[\s\S]*\]"#, options: .regularExpression) {
            return String(trimmed[range])
        }

        return trimmed
    }
}
