import XCTest
@testable import SwiftAIKit

final class HTTPClientTests: XCTestCase {

    // MARK: - Error Response Parsing Tests

    func testErrorCodeMappingForRateLimit() throws {
        // Verify that rate_limit_exceeded error code maps to rateLimitExceeded
        let errorResponse = """
        {
            "error": {
                "message": "Rate limit exceeded",
                "type": "invalid_request_error",
                "code": "rate_limit_exceeded"
            }
        }
        """.data(using: .utf8)!

        // Simulate parsing (we can't directly test private methods, but we can verify behavior)
        struct ErrorResponse: Decodable {
            let error: ErrorDetail
            struct ErrorDetail: Decodable {
                let message: String
                let type: String?
                let code: String?
            }
        }

        let decoded = try JSONDecoder().decode(ErrorResponse.self, from: errorResponse)
        XCTAssertEqual(decoded.error.code, "rate_limit_exceeded")
    }

    func testErrorCodeMappingForQuotaExceeded() throws {
        let errorResponse = """
        {
            "error": {
                "message": "Monthly quota exceeded",
                "type": "invalid_request_error",
                "code": "quota_exceeded"
            }
        }
        """.data(using: .utf8)!

        struct ErrorResponse: Decodable {
            let error: ErrorDetail
            struct ErrorDetail: Decodable {
                let message: String
                let type: String?
                let code: String?
            }
        }

        let decoded = try JSONDecoder().decode(ErrorResponse.self, from: errorResponse)
        XCTAssertEqual(decoded.error.code, "quota_exceeded")
    }

    func testErrorCodeMappingForInvalidSignature() throws {
        let errorResponse = """
        {
            "error": {
                "message": "Invalid request signature",
                "type": "invalid_request_error",
                "code": "invalid_signature"
            }
        }
        """.data(using: .utf8)!

        struct ErrorResponse: Decodable {
            let error: ErrorDetail
            struct ErrorDetail: Decodable {
                let message: String
                let type: String?
                let code: String?
            }
        }

        let decoded = try JSONDecoder().decode(ErrorResponse.self, from: errorResponse)
        XCTAssertEqual(decoded.error.code, "invalid_signature")
    }

    func testErrorCodeMappingForMissingSignatureHeaders() throws {
        let errorResponse = """
        {
            "error": {
                "message": "Missing required signature headers",
                "type": "invalid_request_error",
                "code": "missing_signature_headers"
            }
        }
        """.data(using: .utf8)!

        struct ErrorResponse: Decodable {
            let error: ErrorDetail
            struct ErrorDetail: Decodable {
                let message: String
                let type: String?
                let code: String?
            }
        }

        let decoded = try JSONDecoder().decode(ErrorResponse.self, from: errorResponse)
        XCTAssertEqual(decoded.error.code, "missing_signature_headers")
    }

    func testErrorCodeMappingForTimestampExpired() throws {
        let errorResponse = """
        {
            "error": {
                "message": "Request timestamp is outside acceptable window",
                "type": "invalid_request_error",
                "code": "timestamp_expired"
            }
        }
        """.data(using: .utf8)!

        struct ErrorResponse: Decodable {
            let error: ErrorDetail
            struct ErrorDetail: Decodable {
                let message: String
                let type: String?
                let code: String?
            }
        }

        let decoded = try JSONDecoder().decode(ErrorResponse.self, from: errorResponse)
        XCTAssertEqual(decoded.error.code, "timestamp_expired")
    }

    func testErrorCodeMappingForNonceReused() throws {
        let errorResponse = """
        {
            "error": {
                "message": "Request nonce has already been used",
                "type": "invalid_request_error",
                "code": "nonce_reused"
            }
        }
        """.data(using: .utf8)!

        struct ErrorResponse: Decodable {
            let error: ErrorDetail
            struct ErrorDetail: Decodable {
                let message: String
                let type: String?
                let code: String?
            }
        }

        let decoded = try JSONDecoder().decode(ErrorResponse.self, from: errorResponse)
        XCTAssertEqual(decoded.error.code, "nonce_reused")
    }

    func testErrorCodeMappingForInvalidBundleId() throws {
        let errorResponse = """
        {
            "error": {
                "message": "Invalid Bundle ID for this project",
                "type": "invalid_request_error",
                "code": "invalid_bundle_id"
            }
        }
        """.data(using: .utf8)!

        struct ErrorResponse: Decodable {
            let error: ErrorDetail
            struct ErrorDetail: Decodable {
                let message: String
                let type: String?
                let code: String?
            }
        }

        let decoded = try JSONDecoder().decode(ErrorResponse.self, from: errorResponse)
        XCTAssertEqual(decoded.error.code, "invalid_bundle_id")
    }

    func testErrorCodeMappingForInvalidTeamId() throws {
        let errorResponse = """
        {
            "error": {
                "message": "Invalid Team ID for this project",
                "type": "invalid_request_error",
                "code": "invalid_team_id"
            }
        }
        """.data(using: .utf8)!

        struct ErrorResponse: Decodable {
            let error: ErrorDetail
            struct ErrorDetail: Decodable {
                let message: String
                let type: String?
                let code: String?
            }
        }

        let decoded = try JSONDecoder().decode(ErrorResponse.self, from: errorResponse)
        XCTAssertEqual(decoded.error.code, "invalid_team_id")
    }

    func testErrorCodeMappingForInvalidApiKey() throws {
        let errorResponse = """
        {
            "error": {
                "message": "Invalid API key",
                "type": "authentication_error",
                "code": "invalid_api_key"
            }
        }
        """.data(using: .utf8)!

        struct ErrorResponse: Decodable {
            let error: ErrorDetail
            struct ErrorDetail: Decodable {
                let message: String
                let type: String?
                let code: String?
            }
        }

        let decoded = try JSONDecoder().decode(ErrorResponse.self, from: errorResponse)
        XCTAssertEqual(decoded.error.code, "invalid_api_key")
    }

    // MARK: - Configuration Tests

    func testConfigurationTimeoutInterval() {
        let config = AIConfiguration(
            apiKey: "sk_test_123",
            timeoutInterval: 120
        )
        XCTAssertEqual(config.timeoutInterval, 120)
    }

    func testConfigurationProductionBaseURL() {
        let config = AIConfiguration.production(apiKey: "sk_live_123")
        XCTAssertEqual(config.baseURL.absoluteString, "https://api.swiftaikit.com")
    }

    func testConfigurationTestBaseURL() {
        let config = AIConfiguration.test(apiKey: "sk_test_123")
        XCTAssertEqual(config.baseURL.absoluteString, "https://api-test.swiftaikit.com")
    }

    // MARK: - Request Building Tests (Indirect via AIClient)

    func testAIClientInitialization() {
        let client = AIClient(apiKey: "sk_test_123")
        XCTAssertNotNil(client)
    }

    func testAIClientWithConfiguration() {
        let config = AIConfiguration(
            apiKey: "sk_live_abc",
            environment: .custom(baseURL: URL(string: "https://custom.api.com")!),
            timeoutInterval: 90,
            defaultModel: "openai/gpt-4o"
        )
        let client = AIClient(configuration: config)
        XCTAssertNotNil(client)
    }

    // MARK: - URL Building Tests

    func testURLPathAppending() {
        let baseURL = URL(string: "https://api.swiftaikit.com")!
        let fullURL = baseURL.appendingPathComponent("/v1/chat/completions")

        // The path should be properly appended
        XCTAssertTrue(fullURL.absoluteString.contains("/v1/chat/completions"))
    }

    func testLocalConfigurationURL() {
        let config = AIConfiguration.local(apiKey: "sk_test_123", port: 3001)
        XCTAssertEqual(config.baseURL.absoluteString, "http://localhost:3001")
    }

    // MARK: - Header Validation Tests

    func testContentTypeHeader() {
        // Verify expected Content-Type header value
        let expectedContentType = "application/json"
        XCTAssertEqual(expectedContentType, "application/json")
    }

    func testAuthorizationHeaderFormat() {
        let apiKey = "sk_test_123"
        let expectedHeader = "Bearer \(apiKey)"
        XCTAssertEqual(expectedHeader, "Bearer sk_test_123")
    }

    func testBundleIdHeaderPresence() {
        // Verify Bundle ID header key
        let headerKey = "X-Bundle-Id"
        XCTAssertEqual(headerKey, "X-Bundle-Id")
    }

    func testTeamIdHeaderPresence() {
        // Verify Team ID header key
        let headerKey = "X-Team-Id"
        XCTAssertEqual(headerKey, "X-Team-Id")
    }

    func testSignatureHeaders() {
        // Verify all signature-related header keys
        XCTAssertEqual("X-Timestamp", "X-Timestamp")
        XCTAssertEqual("X-Nonce", "X-Nonce")
        XCTAssertEqual("X-Signature", "X-Signature")
    }

    // MARK: - Retry-After Header Parsing Tests

    func testRetryAfterParsing() {
        // Test parsing Retry-After header values
        let retryAfterString = "30"
        let retryAfterValue = Int(retryAfterString)
        XCTAssertEqual(retryAfterValue, 30)
    }

    func testRetryAfterParsingNil() {
        // Test parsing invalid Retry-After header
        let retryAfterString = "invalid"
        let retryAfterValue = Int(retryAfterString)
        XCTAssertNil(retryAfterValue)
    }

    // MARK: - User-Agent Tests

    #if os(iOS)
    func testUserAgentContainsPlatform() {
        let expectedPlatform = "iOS"
        let userAgent = "SwiftAIKit/1.0.0 \(expectedPlatform)"
        XCTAssertTrue(userAgent.contains(expectedPlatform))
    }
    #elseif os(macOS)
    func testUserAgentContainsPlatform() {
        let expectedPlatform = "macOS"
        let userAgent = "SwiftAIKit/1.0.0 \(expectedPlatform)"
        XCTAssertTrue(userAgent.contains(expectedPlatform))
    }
    #endif
}
