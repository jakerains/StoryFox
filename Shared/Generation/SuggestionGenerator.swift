import Foundation
import FoundationModels

@Generable
struct StoryConceptSuggestions {
    @Guide(description: "Exactly 4 unique children's story concepts. Each is one short sentence about a real animal doing a relatable activity in an everyday setting — like a park, kitchen, garden, school, or neighborhood. Keep each under 90 characters. No fantasy kingdoms, no magical objects, no made-up place names.")
    var concepts: [String]
}

enum SuggestionGenerator {
    /// Generate 4 fresh story concept suggestions using the on-device Foundation Model.
    /// Returns nil if the model is unavailable or generation fails.
    static func generate() async -> [String]? {
        guard SystemLanguageModel.default.availability == .available else {
            return nil
        }

        do {
            let session = LanguageModelSession(
                instructions: """
                You are a children's story idea generator. \
                Generate warm, relatable story concepts featuring animal characters \
                in everyday settings like gardens, kitchens, schools, parks, farms, \
                and neighborhoods. Focus on real emotions and simple adventures — \
                making a friend, learning a skill, solving a small problem, or \
                helping someone. Avoid fantasy worlds, magical powers, and made-up places.
                """
            )

            let options = GenerationOptions(temperature: 0.9)

            let response = try await session.respond(
                to: "Generate 4 unique children's story concepts.",
                generating: StoryConceptSuggestions.self,
                options: options
            )

            let concepts = response.content.concepts
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            guard concepts.count >= 2 else { return nil }
            return Array(concepts.prefix(4))
        } catch {
            return nil
        }
    }

    /// Curated fallback suggestions when Foundation Models are unavailable.
    /// Returns 4 randomly chosen concepts from a pool of 8.
    static func randomFallback() -> [String] {
        let pool = [
            "A curious fox who starts a little lending library in the park",
            "A shy kitten trying to make friends on the first day of school",
            "A clumsy puppy learning to fetch at the neighborhood dog park",
            "A little rabbit growing the biggest carrot in the garden",
            "A brave duckling swimming across the pond for the first time",
            "An otter who teaches her younger brother how to share",
            "A baby bear helping grandma bake a birthday cake",
            "A small owl staying up past bedtime to count the stars",
        ]
        return Array(pool.shuffled().prefix(4))
    }
}
