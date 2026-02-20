import Foundation

struct RemoteStoryGeneratorConfig: Sendable {
    let endpointURL: URL
    let apiKey: String?
    let model: String?
    let timeoutSeconds: TimeInterval
    let apiHeaderName: String
    let apiHeaderPrefix: String

    static func load(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        defaults: UserDefaults = .standard
    ) -> RemoteStoryGeneratorConfig? {
        let endpointValue = value(
            envKeys: ["STORYFOX_LARGE_MODEL_ENDPOINT", "STORYFOX_REMOTE_LLM_ENDPOINT"],
            defaultKey: "storyfox.largeModelEndpoint",
            environment: environment,
            defaults: defaults
        )
        guard let endpointValue,
              let endpointURL = URL(string: endpointValue) else {
            return nil
        }

        let apiKey = value(
            envKeys: ["STORYFOX_LARGE_MODEL_API_KEY", "STORYFOX_REMOTE_LLM_API_KEY"],
            defaultKey: "storyfox.largeModelApiKey",
            environment: environment,
            defaults: defaults
        )
        let model = value(
            envKeys: ["STORYFOX_LARGE_MODEL_NAME", "STORYFOX_REMOTE_LLM_MODEL"],
            defaultKey: "storyfox.largeModelName",
            environment: environment,
            defaults: defaults
        )
        let apiHeaderName = value(
            envKeys: ["STORYFOX_LARGE_MODEL_API_HEADER", "STORYFOX_REMOTE_LLM_API_HEADER"],
            defaultKey: "storyfox.largeModelApiHeader",
            environment: environment,
            defaults: defaults
        ) ?? "Authorization"
        let apiHeaderPrefix = value(
            envKeys: ["STORYFOX_LARGE_MODEL_API_PREFIX", "STORYFOX_REMOTE_LLM_API_PREFIX"],
            defaultKey: "storyfox.largeModelApiPrefix",
            environment: environment,
            defaults: defaults
        ) ?? "Bearer "

        let timeoutRaw = value(
            envKeys: ["STORYFOX_LARGE_MODEL_TIMEOUT_SECONDS", "STORYFOX_REMOTE_LLM_TIMEOUT_SECONDS"],
            defaultKey: "storyfox.largeModelTimeoutSeconds",
            environment: environment,
            defaults: defaults
        )
        let timeoutSeconds = timeoutRaw.flatMap(TimeInterval.init) ?? 60

        return RemoteStoryGeneratorConfig(
            endpointURL: endpointURL,
            apiKey: apiKey,
            model: model,
            timeoutSeconds: timeoutSeconds,
            apiHeaderName: apiHeaderName,
            apiHeaderPrefix: apiHeaderPrefix
        )
    }

    private static func value(
        envKeys: [String],
        defaultKey: String,
        environment: [String: String],
        defaults: UserDefaults
    ) -> String? {
        for key in envKeys {
            if let value = environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
               !value.isEmpty {
                return value
            }
        }
        if let value = defaults.string(forKey: defaultKey)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !value.isEmpty {
            return value
        }
        return nil
    }
}

enum RemoteStoryGeneratorError: LocalizedError {
    case notConfigured
    case invalidResponse(statusCode: Int, message: String)
    case unparsableResponse
    case contentRejected

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Remote large-model generator is not configured."
        case .invalidResponse(let statusCode, let message):
            return "Large-model request failed (\(statusCode)): \(message)"
        case .unparsableResponse:
            return "Large-model response could not be parsed into a story."
        case .contentRejected:
            return "Large-model response did not include valid pages."
        }
    }
}

/// Calls an optional remote "larger model" endpoint for story generation.
/// If endpoint details are missing, caller should fall back to local generation.
struct RemoteStoryGenerator: Sendable {
    var config: RemoteStoryGeneratorConfig? = RemoteStoryGeneratorConfig.load()
    var urlSession: URLSession = .shared

    var isConfigured: Bool {
        config != nil
    }

    func generateStory(
        concept: String,
        pageCount: Int
    ) async throws -> StoryBook {
        guard let config else {
            throw RemoteStoryGeneratorError.notConfigured
        }

        let safeConcept = ContentSafetyPolicy.sanitizeConcept(concept)
        var request = URLRequest(url: config.endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.timeoutSeconds

        if let apiKey = config.apiKey, !apiKey.isEmpty {
            request.setValue(
                "\(config.apiHeaderPrefix)\(apiKey)",
                forHTTPHeaderField: config.apiHeaderName
            )
        }

        let payload = RemoteStoryRequestPayload(
            model: config.model,
            concept: safeConcept,
            pageCount: pageCount,
            systemInstructions: StoryPromptTemplates.systemInstructions,
            userPrompt: StoryPromptTemplates.userPrompt(concept: safeConcept, pageCount: pageCount)
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RemoteStoryGeneratorError.unparsableResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw RemoteStoryGeneratorError.invalidResponse(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }

        let dto: StoryDTO
        do {
            dto = try StoryDecoding.decodeStoryDTO(from: data)
        } catch {
            throw RemoteStoryGeneratorError.unparsableResponse
        }
        let story = dto.toStoryBook(
            pageCount: pageCount,
            fallbackConcept: safeConcept
        )
        guard !story.pages.isEmpty else {
            throw RemoteStoryGeneratorError.contentRejected
        }
        return story
    }

    // Prompt templates moved to StoryPromptTemplates for shared use across generators.
}

private struct RemoteStoryRequestPayload: Encodable {
    let model: String?
    let concept: String
    let pageCount: Int
    let systemInstructions: String
    let userPrompt: String
}
