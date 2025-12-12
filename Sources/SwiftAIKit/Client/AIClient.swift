import Foundation

/// The main client for interacting with the SwiftAIKit API
public actor AIClient {
    private let httpClient: HTTPClient
    private let configuration: AIConfiguration

    /// Creates a new AI client
    /// - Parameter configuration: The client configuration
    public init(configuration: AIConfiguration) {
        self.configuration = configuration
        self.httpClient = HTTPClient(configuration: configuration)
    }

    /// Creates a new AI client with an API key
    /// - Parameters:
    ///   - apiKey: Your SwiftAIKit API key
    ///   - baseURL: The API base URL (optional, uses custom environment if provided)
    public init(apiKey: String, baseURL: URL? = nil) {
        let config: AIConfiguration
        if let baseURL {
            config = AIConfiguration(
                apiKey: apiKey,
                environment: .custom(baseURL: baseURL)
            )
        } else {
            config = AIConfiguration(apiKey: apiKey)
        }
        self.configuration = config
        self.httpClient = HTTPClient(configuration: config)
    }

    // MARK: - Chat Completion

    /// Create a chat completion
    /// - Parameters:
    ///   - messages: The conversation messages (must not be empty)
    ///   - model: The model to use (optional, uses default if not specified)
    ///   - temperature: Sampling temperature (0-2, default: 1)
    ///   - maxTokens: Maximum tokens to generate (must be positive)
    ///   - topP: Top-p sampling parameter (0-1)
    ///   - frequencyPenalty: Frequency penalty (-2 to 2)
    ///   - presencePenalty: Presence penalty (-2 to 2)
    ///   - stop: Stop sequences
    /// - Returns: The chat completion response
    /// - Throws: `AIError.invalidRequest` if parameters are invalid
    public func chatCompletion(
        messages: [ChatMessage],
        model: String? = nil,
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        topP: Double? = nil,
        frequencyPenalty: Double? = nil,
        presencePenalty: Double? = nil,
        stop: [String]? = nil
    ) async throws -> ChatCompletion {
        let response = try await chatCompletionWithBilling(
            messages: messages,
            model: model,
            temperature: temperature,
            maxTokens: maxTokens,
            topP: topP,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty,
            stop: stop
        )
        return response.data
    }

    /// Create a chat completion with billing information
    /// - Parameters:
    ///   - messages: The conversation messages (must not be empty)
    ///   - model: The model to use (optional, uses default if not specified)
    ///   - temperature: Sampling temperature (0-2, default: 1)
    ///   - maxTokens: Maximum tokens to generate (must be positive)
    ///   - topP: Top-p sampling parameter (0-1)
    ///   - frequencyPenalty: Frequency penalty (-2 to 2)
    ///   - presencePenalty: Presence penalty (-2 to 2)
    ///   - stop: Stop sequences
    /// - Returns: The chat completion response with billing info
    /// - Throws: `AIError.invalidRequest` if parameters are invalid
    public func chatCompletionWithBilling(
        messages: [ChatMessage],
        model: String? = nil,
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        topP: Double? = nil,
        frequencyPenalty: Double? = nil,
        presencePenalty: Double? = nil,
        stop: [String]? = nil
    ) async throws -> ChatCompletionResponse {
        // Validate parameters
        try validateParameters(
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
            topP: topP,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty
        )

        let request = ChatCompletionRequest(
            model: model ?? configuration.defaultModel ?? "google/gemini-2.5-flash",
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
            topP: topP,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty,
            stop: stop,
            stream: false
        )

        let (completion, billing): (ChatCompletion, BillingInfo?) = try await httpClient.postWithBilling(
            path: "v1/chat/completions",
            body: request
        )
        return ChatCompletionResponse(data: completion, billing: billing)
    }

    /// Create a streaming chat completion
    /// - Parameters:
    ///   - messages: The conversation messages (must not be empty)
    ///   - model: The model to use
    ///   - temperature: Sampling temperature (0-2)
    ///   - maxTokens: Maximum tokens to generate (must be positive)
    ///   - topP: Top-p sampling (0-1)
    ///   - frequencyPenalty: Frequency penalty (-2 to 2)
    ///   - presencePenalty: Presence penalty (-2 to 2)
    ///   - stop: Stop sequences
    /// - Returns: An async stream of completion chunks
    /// - Throws: `AIError.invalidRequest` if parameters are invalid
    public func chatCompletionStream(
        messages: [ChatMessage],
        model: String? = nil,
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        topP: Double? = nil,
        frequencyPenalty: Double? = nil,
        presencePenalty: Double? = nil,
        stop: [String]? = nil
    ) async throws -> AsyncThrowingStream<ChatCompletionChunk, Error> {
        // Validate parameters
        try validateParameters(
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
            topP: topP,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty
        )

        let request = ChatCompletionRequest(
            model: model ?? configuration.defaultModel ?? "google/gemini-2.5-flash",
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
            topP: topP,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty,
            stop: stop,
            stream: true
        )

        let dataStream = try await httpClient.stream(path: "v1/chat/completions", body: request)

        return AsyncThrowingStream { continuation in
            let task = Task {
                let decoder = JSONDecoder()

                do {
                    for try await data in dataStream {
                        // Check for cancellation
                        try Task.checkCancellation()

                        guard let line = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                              !line.isEmpty else {
                            continue
                        }

                        // Skip SSE comments
                        if line.hasPrefix(":") {
                            continue
                        }

                        // Check for end of stream
                        if line == "data: [DONE]" {
                            break
                        }

                        // Parse SSE data
                        guard line.hasPrefix("data: ") else {
                            continue
                        }

                        let jsonString = String(line.dropFirst(6))
                        guard let jsonData = jsonString.data(using: .utf8) else {
                            continue
                        }

                        do {
                            let chunk = try decoder.decode(ChatCompletionChunk.self, from: jsonData)
                            continuation.yield(chunk)
                        } catch {
                            // Skip malformed chunks
                            continue
                        }
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            // Handle stream cancellation
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    // MARK: - Models

    /// List available models
    /// - Returns: An array of model information
    public func listModels() async throws -> [Model] {
        struct ModelsResponse: Decodable {
            let data: [Model]
        }

        let response: ModelsResponse = try await httpClient.get(path: "v1/models")
        return response.data
    }

    // MARK: - Private Methods

    private func validateParameters(
        messages: [ChatMessage],
        temperature: Double?,
        maxTokens: Int?,
        topP: Double?,
        frequencyPenalty: Double?,
        presencePenalty: Double?
    ) throws {
        // Validate messages
        guard !messages.isEmpty else {
            throw AIError.invalidRequest(message: "Messages array cannot be empty")
        }

        // Validate temperature (0-2)
        if let temperature, !(0...2).contains(temperature) {
            throw AIError.invalidRequest(message: "Temperature must be between 0 and 2")
        }

        // Validate maxTokens (positive)
        if let maxTokens, maxTokens <= 0 {
            throw AIError.invalidRequest(message: "Max tokens must be a positive integer")
        }

        // Validate topP (0-1)
        if let topP, !(0...1).contains(topP) {
            throw AIError.invalidRequest(message: "Top-p must be between 0 and 1")
        }

        // Validate frequencyPenalty (-2 to 2)
        if let frequencyPenalty, !(-2...2).contains(frequencyPenalty) {
            throw AIError.invalidRequest(message: "Frequency penalty must be between -2 and 2")
        }

        // Validate presencePenalty (-2 to 2)
        if let presencePenalty, !(-2...2).contains(presencePenalty) {
            throw AIError.invalidRequest(message: "Presence penalty must be between -2 and 2")
        }
    }
}

// MARK: - Internal Types

/// Model information
public struct Model: Codable, Sendable, Identifiable {
    public let id: String
    public let object: String
    public let created: Int
    public let ownedBy: String

    enum CodingKeys: String, CodingKey {
        case id, object, created
        case ownedBy = "owned_by"
    }
}

/// Internal request type
private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double?
    let maxTokens: Int?
    let topP: Double?
    let frequencyPenalty: Double?
    let presencePenalty: Double?
    let stop: [String]?
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stop, stream
        case maxTokens = "max_tokens"
        case topP = "top_p"
        case frequencyPenalty = "frequency_penalty"
        case presencePenalty = "presence_penalty"
    }
}
