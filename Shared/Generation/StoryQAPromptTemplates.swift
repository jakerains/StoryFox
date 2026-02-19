import Foundation

enum StoryQAPromptTemplates {

    // MARK: - System Instructions

    static func systemInstructions(for audience: AudienceMode) -> String {
        switch audience {
        case .kid:
            return """
            You help kids (ages 5-8) make up stories. You talk like a fun teacher at \
            story time. Use short, simple words only. Every question must be one short \
            sentence a 5-year-old can read. Every suggestion must be one short sentence \
            with fun, silly ideas kids love (animals, magic, silly names, adventures). \
            VOCABULARY RULE: Only use words a kindergartner knows. Write at a 1st-grade \
            reading level. \
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

        if audience == .kid {
            prompt += """
            This is round \(roundNumber) of \(totalRounds).

            \(focusGuidance)

            IMPORTANT: Write at a kindergarten reading level. Use only words a 5-year-old knows. \
            Keep every question to one short sentence. Keep every suggestion to one short sentence. \
            Make it fun and silly! Return ONLY the JSON array — no other text.
            """
        } else {
            prompt += """
            This is round \(roundNumber) of \(totalRounds). \(focusGuidance)

            Generate exactly 3 questions. For each question, provide exactly 3 suggested \
            answers that are creative, specific, and evocative.

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
        }

        return prompt
    }

    // MARK: - Round Focus

    private static func roundFocus(_ round: Int, audience: AudienceMode) -> String {
        switch (round, audience) {
        case (1, .kid):
            return """
            Ask about the HERO and the PLACE. Copy this style EXACTLY:
            [
              {"question": "Who is the hero of your story?", "suggestions": ["A brave little bunny named Pip", "A silly dragon who can't fly yet", "A kid just like you with a magic hat"]},
              {"question": "What makes your hero super special?", "suggestions": ["They can talk to animals!", "They have a glowing magic backpack", "They are the funniest kid in town"]},
              {"question": "Where does the adventure happen?", "suggestions": ["A candy forest with chocolate rivers", "A floating castle in the clouds", "Under the sea with friendly fish"]}
            ]
            Use the SAME simple words and short sentences as above. Change the content to fit the story concept but keep the same easy reading level.
            """
        case (1, .adult):
            return """
            Focus on the CHARACTERS and SETTING: \
            Who is the protagonist? What's their personality, motivation, and world? \
            What atmosphere and time period should the story evoke?
            """
        case (2, .kid):
            return """
            Ask about the ADVENTURE and the PROBLEM. Copy this style EXACTLY:
            [
              {"question": "What big problem does the hero run into?", "suggestions": ["A sneaky fox stole all the cookies!", "A giant storm is coming to the town", "The hero's best friend is lost"]},
              {"question": "Who helps the hero?", "suggestions": ["A funny talking bird", "A wise old turtle", "A group of tiny brave mice"]},
              {"question": "What is the scariest or silliest part?", "suggestions": ["They fall into a pit of tickle monsters!", "A big shadow turns out to be a baby bunny", "The hero has to cross a wobbly bridge over goo"]}
            ]
            Use the SAME simple words and short sentences as above. Change the content to fit the story concept and previous answers but keep the same easy reading level.
            """
        case (2, .adult):
            return """
            Focus on the PLOT and CONFLICT: \
            What challenge drives the narrative? What's at stake? \
            What complications or turning points should arise?
            """
        case (_, .kid):
            return """
            Ask about the ENDING and HOW IT FEELS. Copy this style EXACTLY:
            [
              {"question": "How does the story end?", "suggestions": ["Everyone has a big party!", "The hero makes a new best friend", "They find a treasure and share it with everyone"]},
              {"question": "What happy thing happens at the end?", "suggestions": ["The hero gets a big hug from mom", "All the animals dance together", "A rainbow appears in the sky"]},
              {"question": "How should the story make you feel?", "suggestions": ["Happy and warm inside", "Excited and ready for more adventures", "Giggly and silly"]}
            ]
            Use the SAME simple words and short sentences as above. Change the content to fit the story concept and previous answers but keep the same easy reading level.
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
