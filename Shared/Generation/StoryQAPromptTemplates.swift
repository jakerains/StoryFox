import Foundation

enum StoryQAPromptTemplates {

    // MARK: - System Instructions

    static func systemInstructions(for audience: AudienceMode) -> String {
        switch audience {
        case .kid:
            return """
            You are a super friendly story helper talking to a kid (ages 5-10). \
            IMPORTANT RULES FOR KID MODE: \
            - Use ONLY simple words a 6-year-old would understand. \
            - NEVER use words like "protagonist", "narrative", "atmosphere", "motivation", "conflict", "resolution", "emotional register", or any fancy grown-up words. \
            - Say "hero" instead of "protagonist". Say "adventure" instead of "narrative". Say "place" or "world" instead of "setting". Say "problem" instead of "conflict". \
            - Keep questions SHORT and FUN — one sentence max. \
            - Make suggested answers silly, playful, and full of imagination — kids love animals, magic, silly names, and wild adventures. \
            - Talk like you're excited to help a kid make the COOLEST story ever! \
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
        answers that are creative, specific, and \(audience == .kid ? "fun for kids — use simple words a 6-year-old would understand, NO fancy vocabulary" : "evocative").

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
            Ask about the HERO and the PLACE. \
            Examples of good kid questions: "Who is the hero of your story?", \
            "What makes your hero special?", "Where does the adventure happen?" \
            Remember — simple words only! No "protagonist", no "setting", no "atmosphere".
            """
        case (1, .adult):
            return """
            Focus on the CHARACTERS and SETTING: \
            Who is the protagonist? What's their personality, motivation, and world? \
            What atmosphere and time period should the story evoke?
            """
        case (2, .kid):
            return """
            Ask about the ADVENTURE and the PROBLEM. \
            Examples of good kid questions: "What big problem does the hero face?", \
            "Who helps the hero on the adventure?", "What's the scariest or silliest part?" \
            Keep it fun and exciting! No grown-up words like "conflict" or "stakes".
            """
        case (2, .adult):
            return """
            Focus on the PLOT and CONFLICT: \
            What challenge drives the narrative? What's at stake? \
            What complications or turning points should arise?
            """
        case (_, .kid):
            return """
            Ask about the ENDING and HOW IT FEELS. \
            Examples of good kid questions: "How does the story end?", \
            "What happy thing happens at the end?", "How should the reader feel?" \
            Keep it warm and simple! No "resolution" or "emotional tone".
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
