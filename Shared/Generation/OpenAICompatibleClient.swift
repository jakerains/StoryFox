import CoreGraphics
import Foundation
import ImageIO
import os

/// Stateless, `Sendable` HTTP client for OpenAI-compatible cloud APIs.
/// Used by all three cloud providers (OpenRouter, Together AI, HuggingFace).
struct OpenAICompatibleClient: Sendable {
    private static let logger = Logger(subsystem: "com.storyfox.app", category: "CloudClient")

    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    // MARK: - Chat Completion

    /// Sends a chat completion request and returns the raw response data.
    func chatCompletion(
        url: URL,
        apiKey: String,
        model: String,
        systemPrompt: String,
        userPrompt: String,
        temperature: Double = 0.7,
        maxTokens: Int = 4096,
        extraHeaders: [String: String] = [:]
    ) async throws -> Data {
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": temperature,
            "max_tokens": maxTokens
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = TimeInterval(GenerationConfig.cloudTextGenerationTimeoutSeconds)

        for (key, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        Self.logger.info("Chat completion → \(url.host() ?? "unknown", privacy: .public) model=\(model, privacy: .public)")

        let (data, response) = try await urlSession.data(for: request)
        try validateHTTPResponse(response, data: data)

        return data
    }

    // MARK: - Image Generation

    /// Sends an image generation request and returns a decoded CGImage.
    func imageGeneration(
        url: URL,
        apiKey: String,
        model: String,
        prompt: String,
        size: String = "1024x1024",
        n: Int = 1,
        extraHeaders: [String: String] = [:]
    ) async throws -> CGImage {
        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "size": size,
            "n": n,
            "response_format": "b64_json"
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = TimeInterval(GenerationConfig.cloudImageGenerationTimeoutSeconds)

        for (key, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        Self.logger.info("Image generation → \(url.host() ?? "unknown", privacy: .public) model=\(model, privacy: .public)")

        let (data, response) = try await urlSession.data(for: request)
        try validateHTTPResponse(response, data: data)

        return try await decodeImageResponse(data)
    }

    // MARK: - Model Listing

    /// Fetches the list of available models from a provider.
    func fetchModels(
        url: URL,
        apiKey: String,
        extraHeaders: [String: String] = [:]
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        for (key, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await urlSession.data(for: request)
        try validateHTTPResponse(response, data: data)

        return data
    }

    // MARK: - Response Handling

    private func validateHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudProviderError.unparsableResponse
        }

        if (200...299).contains(httpResponse.statusCode) {
            return
        }

        if httpResponse.statusCode == 429 {
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap(Int.init)
            throw CloudProviderError.rateLimited(retryAfterSeconds: retryAfter)
        }

        let message = String(data: data, encoding: .utf8) ?? "Unknown error"
        throw CloudProviderError.httpError(
            statusCode: httpResponse.statusCode,
            message: String(message.prefix(500))
        )
    }

    /// Decodes image data from an OpenAI-compatible image response.
    /// Supports both `b64_json` and `url` response formats.
    private func decodeImageResponse(_ data: Data) async throws -> CGImage {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]],
              let first = dataArray.first else {
            throw CloudProviderError.unparsableResponse
        }

        // Try base64 first (preferred — no extra network hop)
        if let b64String = first["b64_json"] as? String,
           let imageData = Data(base64Encoded: b64String),
           let image = cgImage(from: imageData) {
            return image
        }

        // Fall back to URL download
        if let urlString = first["url"] as? String,
           let imageURL = URL(string: urlString) {
            let (imageData, _) = try await urlSession.data(from: imageURL)
            if let image = cgImage(from: imageData) {
                return image
            }
        }

        throw CloudProviderError.imageDecodingFailed
    }

    private func cgImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0 else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
