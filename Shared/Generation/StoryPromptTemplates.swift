import Foundation

enum StoryPromptTemplates {
    static var systemInstructions: String {
        """
        You are an award-winning children's storybook writer and art director.
        Output only content that is safe for ages 3-8 and suitable for on-device image generation.
        Avoid violence, weapons, gore, horror, nudity, substance use, hateful content, or unsafe scenarios.
        """
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
