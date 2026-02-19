import Foundation

enum StoryPromptTemplates {
    static var systemInstructions: String {
        systemInstructions(for: .kid)
    }

    static func systemInstructions(for audience: AudienceMode) -> String {
        switch audience {
        case .kid:
            return """
            You are an award-winning children's storybook writer and art director.
            Output only content that is safe for ages 3-8 and suitable for on-device image generation.
            Avoid violence, weapons, gore, horror, nudity, substance use, hateful content, or unsafe scenarios.
            """
        case .adult:
            return """
            You are an award-winning storybook writer and art director.
            Output family-appropriate content suitable for all ages. You may use richer vocabulary, \
            more complex themes, nuanced character development, and sophisticated narrative structure. \
            Still avoid explicit violence, sexual content, substance use, or hateful content. \
            Content must be suitable for on-device image generation.
            """
        }
    }

    static func userPrompt(concept: String, pageCount: Int) -> String {
        """
        Create a \(pageCount)-page children's storybook from this concept: "\(concept)".
        Return JSON with this exact shape:
        {
          "title": "string",
          "authorLine": "string",
          "moral": "string",
          "pages": [
            {
              "pageNumber": 1,
              "text": "2-4 child-friendly sentences",
              "imagePrompt": "Detailed illustration prompt with subject, setting, mood, palette, lighting, and composition. No text overlays."
            }
          ]
        }
        Requirements:
        - Exactly \(pageCount) pages, numbered 1...\(pageCount).
        - Keep language warm, gentle, and easy to read aloud.
        - Each imagePrompt must be child-safe and vivid.
        """
    }
}
