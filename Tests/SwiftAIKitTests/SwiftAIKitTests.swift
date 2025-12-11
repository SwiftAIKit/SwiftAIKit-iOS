import XCTest
@testable import SwiftAIKit

final class SwiftAIKitTests: XCTestCase {

    // MARK: - ChatMessage Tests

    func testSystemMessage() {
        let message = ChatMessage.system("You are a helpful assistant.")
        XCTAssertEqual(message.role, .system)
        XCTAssertEqual(message.content, "You are a helpful assistant.")
        XCTAssertNil(message.name)
        XCTAssertNil(message.toolCalls)
    }

    func testUserMessage() {
        let message = ChatMessage.user("Hello, world!")
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "Hello, world!")
    }

    func testAssistantMessage() {
        let message = ChatMessage.assistant("Hello! How can I help you?")
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "Hello! How can I help you?")
    }

    func testCustomMessage() {
        let message = ChatMessage(role: .tool, content: "Result", toolCallId: "call_123")
        XCTAssertEqual(message.role, .tool)
        XCTAssertEqual(message.content, "Result")
        XCTAssertEqual(message.toolCallId, "call_123")
    }

    // MARK: - ChatMessage Encoding Tests

    func testChatMessageEncoding() throws {
        let message = ChatMessage.user("Hello")
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["role"] as? String, "user")
        XCTAssertEqual(json?["content"] as? String, "Hello")
    }

    func testChatMessageDecoding() throws {
        let json = """
        {
            "role": "assistant",
            "content": "Hello! How can I help?",
            "tool_calls": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let message = try decoder.decode(ChatMessage.self, from: json)

        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "Hello! How can I help?")
        XCTAssertNil(message.toolCalls)
    }

    // MARK: - AIConfiguration Tests

    func testDefaultConfiguration() {
        let config = AIConfiguration(apiKey: "sk_test_123")
        XCTAssertEqual(config.apiKey, "sk_test_123")
        // Default environment is auto, which resolves to test in simulator/DEBUG
        XCTAssertEqual(config.timeoutInterval, 60)
        XCTAssertNil(config.defaultModel)
    }

    func testProductionConfiguration() {
        let config = AIConfiguration.production(apiKey: "sk_live_123")
        XCTAssertEqual(config.apiKey, "sk_live_123")
        XCTAssertEqual(config.baseURL.absoluteString, "https://api.swiftaikit.com")
    }

    func testTestConfiguration() {
        let config = AIConfiguration.test(apiKey: "sk_test_123")
        XCTAssertEqual(config.apiKey, "sk_test_123")
        XCTAssertEqual(config.baseURL.absoluteString, "https://api-test.swiftaikit.com")
    }

    func testLocalConfiguration() {
        let config = AIConfiguration.local(apiKey: "sk_test_123", port: 8080)
        XCTAssertEqual(config.apiKey, "sk_test_123")
        XCTAssertEqual(config.baseURL.absoluteString, "http://localhost:8080")
    }

    func testCustomConfiguration() {
        let config = AIConfiguration(
            apiKey: "sk_live_abc",
            environment: .custom(baseURL: URL(string: "https://custom.api.com")!),
            timeoutInterval: 120,
            defaultModel: "openai/gpt-4o"
        )
        XCTAssertEqual(config.apiKey, "sk_live_abc")
        XCTAssertEqual(config.baseURL.absoluteString, "https://custom.api.com")
        XCTAssertEqual(config.timeoutInterval, 120)
        XCTAssertEqual(config.defaultModel, "openai/gpt-4o")
    }

    // MARK: - AIError Tests

    func testErrorDescriptions() {
        XCTAssertEqual(AIError.invalidAPIKey.errorDescription, "Invalid or missing API key")
        XCTAssertEqual(AIError.timeout.errorDescription, "Request timed out")
        XCTAssertEqual(AIError.streamInterrupted.errorDescription, "Stream was interrupted")
        XCTAssertEqual(AIError.quotaExceeded.errorDescription, "Monthly token quota exceeded")

        let httpError = AIError.httpError(statusCode: 404, message: "Not found")
        XCTAssertEqual(httpError.errorDescription, "HTTP error 404: Not found")

        let rateLimitError = AIError.rateLimitExceeded(retryAfter: 30)
        XCTAssertEqual(rateLimitError.errorDescription, "Rate limit exceeded. Retry after 30 seconds")
    }

    func testRateLimitErrorWithoutRetryAfter() {
        let rateLimitError = AIError.rateLimitExceeded(retryAfter: nil)
        XCTAssertEqual(rateLimitError.errorDescription, "Rate limit exceeded")
    }

    // MARK: - Security Error Tests

    func testInvalidSignatureError() {
        let error = AIError.invalidSignature
        XCTAssertEqual(error.errorDescription, "Invalid request signature")
    }

    func testTimestampExpiredError() {
        let error = AIError.timestampExpired
        XCTAssertEqual(error.errorDescription, "Request timestamp is outside acceptable window")
    }

    func testNonceReusedError() {
        let error = AIError.nonceReused
        XCTAssertEqual(error.errorDescription, "Request nonce has already been used")
    }

    func testInvalidBundleIdError() {
        let error = AIError.invalidBundleId
        XCTAssertEqual(error.errorDescription, "Invalid Bundle ID for this project")
    }

    func testInvalidTeamIdError() {
        let error = AIError.invalidTeamId
        XCTAssertEqual(error.errorDescription, "Invalid Team ID for this project")
    }

    // MARK: - Other Error Tests

    func testInvalidRequestError() {
        let error = AIError.invalidRequest(message: "Missing required field")
        XCTAssertEqual(error.errorDescription, "Invalid request: Missing required field")
    }

    func testServerError() {
        let error = AIError.serverError(message: "Internal server error")
        XCTAssertEqual(error.errorDescription, "Server error: Internal server error")
    }

    func testUnknownError() {
        let error = AIError.unknown(message: "Something went wrong")
        XCTAssertEqual(error.errorDescription, "Unknown error: Something went wrong")
    }

    func testNetworkError() {
        let underlyingError = NSError(domain: "NSURLErrorDomain", code: -1009, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])
        let error = AIError.networkError(underlying: underlyingError)
        XCTAssertEqual(error.errorDescription, "Network error: No internet connection")
    }

    func testEncodingError() {
        let underlyingError = NSError(domain: "Encoding", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        let error = AIError.encodingError(underlying: underlyingError)
        XCTAssertEqual(error.errorDescription, "Failed to encode request: Invalid JSON")
    }

    func testDecodingError() {
        let underlyingError = NSError(domain: "Decoding", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unexpected format"])
        let error = AIError.decodingError(underlying: underlyingError)
        XCTAssertEqual(error.errorDescription, "Failed to decode response: Unexpected format")
    }

    // MARK: - ChatCompletion Tests

    func testChatCompletionDecoding() throws {
        let json = """
        {
            "id": "chatcmpl-123",
            "object": "chat.completion",
            "created": 1677652288,
            "model": "gpt-4o-mini",
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": "Hello! How can I help?"
                },
                "finish_reason": "stop"
            }],
            "usage": {
                "prompt_tokens": 9,
                "completion_tokens": 12,
                "total_tokens": 21
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let completion = try decoder.decode(ChatCompletion.self, from: json)

        XCTAssertEqual(completion.id, "chatcmpl-123")
        XCTAssertEqual(completion.model, "gpt-4o-mini")
        XCTAssertEqual(completion.choices.count, 1)
        XCTAssertEqual(completion.content, "Hello! How can I help?")
        XCTAssertEqual(completion.usage?.totalTokens, 21)
    }

    // MARK: - ChatCompletionChunk Tests

    func testChatCompletionChunkDecoding() throws {
        let json = """
        {
            "id": "chatcmpl-123",
            "object": "chat.completion.chunk",
            "created": 1677652288,
            "model": "gpt-4o-mini",
            "choices": [{
                "index": 0,
                "delta": {
                    "content": "Hello"
                },
                "finish_reason": null
            }]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let chunk = try decoder.decode(ChatCompletionChunk.self, from: json)

        XCTAssertEqual(chunk.id, "chatcmpl-123")
        XCTAssertEqual(chunk.content, "Hello")
        XCTAssertNil(chunk.choices.first?.finishReason)
    }
}
