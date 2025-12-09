import Foundation

/// Configuration for the AI client
public struct AIConfiguration: Sendable {
    /// The API key for authentication
    public let apiKey: String

    /// The base URL for the API
    public let baseURL: URL

    /// Request timeout interval in seconds
    public let timeoutInterval: TimeInterval

    /// Default model to use
    public let defaultModel: String?

    /// Creates a new AI configuration
    /// - Parameters:
    ///   - apiKey: Your SwiftAIKit API key (starts with sk_live_ or sk_test_)
    ///   - baseURL: The API base URL (defaults to SwiftAIKit API)
    ///   - timeoutInterval: Request timeout in seconds (default: 60)
    ///   - defaultModel: Default model to use for requests
    public init(
        apiKey: String,
        baseURL: URL = URL(string: "https://api.swiftaikit.com")!,
        timeoutInterval: TimeInterval = 60,
        defaultModel: String? = nil
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.timeoutInterval = timeoutInterval
        self.defaultModel = defaultModel
    }

    /// Creates a configuration for local development
    /// - Parameters:
    ///   - apiKey: Your API key
    ///   - port: Local server port (default: 3001)
    public static func local(apiKey: String, port: Int = 3001) -> AIConfiguration {
        AIConfiguration(
            apiKey: apiKey,
            baseURL: URL(string: "http://localhost:\(port)")!,
            timeoutInterval: 60
        )
    }
}
