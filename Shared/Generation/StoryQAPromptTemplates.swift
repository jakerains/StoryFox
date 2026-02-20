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
            You decide how many questions to ask (1-3) and whether you have enough \
            detail to write a great story. When you have enough, set "done" to true. \
            Always respond with valid JSON only — no extra text before or after.
            """
        case .adult:
            return """
            You are a creative story development consultant for illustrated picture books. \
            Ask thoughtful questions about characters, world-building, narrative arc, \
            and emotional tone. Your suggested answers should be specific, evocative, \
            and help the creator envision the story clearly. \
            You decide how many questions to ask (1-3) and whether you have enough \
            detail to write a great story. When you have enough, set "done" to true. \
            Always respond with valid JSON only — no extra text before or after.
            """
        }
    }

    // MARK: - Question Generation

    static func questionGenerationPrompt(
        concept: String,
        roundNumber: Int,
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
            This is question round \(roundNumber).

            \(focusGuidance)

            IMPORTANT: Write at a kindergarten reading level. Use only words a 5-year-old knows. \
            Keep every question to one short sentence. Keep every suggestion to one short sentence. \
            Make it fun and silly!

            Ask 1 to 3 questions (only what you still need to know). \
            If you already have enough detail to write an amazing story, set "done" to true \
            and return an empty questions array.

            Return ONLY JSON in this exact shape — no other text:
            {"questions": [...], "done": false}
            """
        } else {
            prompt += """
            This is question round \(roundNumber). \(focusGuidance)

            Ask 1 to 3 questions — only what you still need to know. For each question, \
            provide exactly 3 suggested answers that are creative, specific, and evocative. \
            If you already have enough detail to write an amazing story, set "done" to true \
            and return an empty questions array.

            Return JSON with this exact shape (no markdown, no extra text):
            {
              "questions": [
                {
                  "question": "Your question here?",
                  "suggestions": ["First suggestion", "Second suggestion", "Third suggestion"]
                }
              ],
              "done": false
            }
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
            {"questions": [
              {"question": "Who is the hero of your story?", "suggestions": ["A brave little bunny named Pip", "A silly dragon who can't fly yet", "A kid just like you with a magic hat"]},
              {"question": "What makes your hero super special?", "suggestions": ["They can talk to animals!", "They have a glowing magic backpack", "They are the funniest kid in town"]},
              {"question": "Where does the adventure happen?", "suggestions": ["A candy forest with chocolate rivers", "A floating castle in the clouds", "Under the sea with friendly fish"]}
            ], "done": false}
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
            {"questions": [
              {"question": "What big problem does the hero run into?", "suggestions": ["A sneaky fox stole all the cookies!", "A giant storm is coming to the town", "The hero's best friend is lost"]},
              {"question": "Who helps the hero?", "suggestions": ["A funny talking bird", "A wise old turtle", "A group of tiny brave mice"]}
            ], "done": false}
            Use the SAME simple words and short sentences as above. Change the content to fit the story concept and previous answers but keep the same easy reading level. Ask only 1-3 questions — whatever you still need to know.
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
            {"questions": [
              {"question": "How does the story end?", "suggestions": ["Everyone has a big party!", "The hero makes a new best friend", "They find a treasure and share it with everyone"]},
              {"question": "How should the story make you feel?", "suggestions": ["Happy and warm inside", "Excited and ready for more adventures", "Giggly and silly"]}
            ], "done": true}
            Use the SAME simple words and short sentences as above. Change the content to fit the story concept and previous answers but keep the same easy reading level. If you already know enough to write an amazing story, return {"questions": [], "done": true} instead.
            """
        case (_, .adult):
            return """
            Focus on the TONE and RESOLUTION: \
            What emotional register should the story maintain? \
            How does it resolve — and what lasting impression should it leave? \
            If you already have enough detail, set "done" to true with an empty questions array.
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

    /// Parse the model's response into questions and a `done` flag.
    /// Supports both the new wrapper `{"questions": [...], "done": bool}`
    /// and the legacy plain array `[{"question": ..., "suggestions": [...]}]`.
    static func parseRound(from text: String) -> (questions: [StoryQuestion], done: Bool)? {
        let cleaned = extractJSON(from: text)
        guard let data = cleaned.data(using: .utf8) else { return nil }

        // Try new wrapper format first
        if let roundDTO = try? JSONDecoder().decode(QARoundResponseDTO.self, from: data) {
            let questions = roundDTO.questions.map { $0.toStoryQuestion() }
            return (questions, roundDTO.done)
        }

        // Fall back to legacy array format
        if let dtos = try? JSONDecoder().decode([QuestionDTO].self, from: data) {
            return (dtos.map { $0.toStoryQuestion() }, false)
        }

        return nil
    }

    private static func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Direct object or array
        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            return trimmed
        }

        // Extract JSON object from markdown code block
        if let range = trimmed.range(of: #"\{[\s\S]*\}"#, options: .regularExpression) {
            return String(trimmed[range])
        }

        // Extract JSON array from markdown code block
        if let range = trimmed.range(of: #"\[[\s\S]*\]"#, options: .regularExpression) {
            return String(trimmed[range])
        }

        return trimmed
    }
}
