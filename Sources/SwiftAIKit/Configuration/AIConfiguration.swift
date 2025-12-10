import Foundation

/// Configuration for the AI client
public struct AIConfiguration: Sendable {
    /// The API key for authentication
    public let apiKey: String

    /// The API environment (production, test, or custom)
    public let environment: AIEnvironment

    /// Request timeout interval in seconds
    public let timeoutInterval: TimeInterval

    /// Default model to use
    public let defaultModel: String?

    /// The base URL for the API (computed from environment)
    public var baseURL: URL {
        environment.baseURL
    }

    /// Creates a new AI configuration with automatic environment detection
    /// - Parameters:
    ///   - apiKey: Your SwiftAIKit API key (starts with sk_live_ or sk_test_)
    ///   - environment: The API environment (defaults to automatic detection based on build configuration)
    ///   - timeoutInterval: Request timeout in seconds (default: 60)
    ///   - defaultModel: Default model to use for requests
    ///
    /// Environment auto-detection:
    /// - Simulator: always uses test environment (api-test.swiftaikit.com)
    /// - DEBUG build: uses test environment
    /// - RELEASE build: uses production environment (api.swiftaikit.com)
    public init(
        apiKey: String,
        environment: AIEnvironment? = nil,
        timeoutInterval: TimeInterval = 60,
        defaultModel: String? = nil
    ) {
        self.apiKey = apiKey
        self.environment = environment ?? .auto
        self.timeoutInterval = timeoutInterval
        self.defaultModel = defaultModel
    }

    /// Creates a configuration for production environment
    /// - Parameters:
    ///   - apiKey: Your API key
    ///   - timeoutInterval: Request timeout in seconds (default: 60)
    ///   - defaultModel: Default model to use for requests
    public static func production(
        apiKey: String,
        timeoutInterval: TimeInterval = 60,
        defaultModel: String? = nil
    ) -> AIConfiguration {
        AIConfiguration(
            apiKey: apiKey,
            environment: .production,
            timeoutInterval: timeoutInterval,
            defaultModel: defaultModel
        )
    }

    /// Creates a configuration for test environment
    /// - Parameters:
    ///   - apiKey: Your API key
    ///   - timeoutInterval: Request timeout in seconds (default: 60)
    ///   - defaultModel: Default model to use for requests
    public static func test(
        apiKey: String,
        timeoutInterval: TimeInterval = 60,
        defaultModel: String? = nil
    ) -> AIConfiguration {
        AIConfiguration(
            apiKey: apiKey,
            environment: .test,
            timeoutInterval: timeoutInterval,
            defaultModel: defaultModel
        )
    }

    /// Creates a configuration for local development
    /// - Parameters:
    ///   - apiKey: Your API key
    ///   - port: Local server port (default: 3001)
    public static func local(apiKey: String, port: Int = 3001) -> AIConfiguration {
        AIConfiguration(
            apiKey: apiKey,
            environment: .custom(baseURL: URL(string: "http://localhost:\(port)")!),
            timeoutInterval: 60
        )
    }
}
