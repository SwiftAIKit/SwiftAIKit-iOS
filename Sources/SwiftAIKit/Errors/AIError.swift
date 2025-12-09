import Foundation

/// Errors that can occur when using SwiftAIKit
public enum AIError: LocalizedError {
    /// The API key is missing or invalid
    case invalidAPIKey

    /// The request failed with an HTTP error
    case httpError(statusCode: Int, message: String)

    /// The request timed out
    case timeout

    /// Network connection failed
    case networkError(underlying: Error)

    /// Failed to encode the request
    case encodingError(underlying: Error)

    /// Failed to decode the response
    case decodingError(underlying: Error)

    /// The stream was interrupted
    case streamInterrupted

    /// Rate limit exceeded
    case rateLimitExceeded(retryAfter: Int?)

    /// Quota exceeded
    case quotaExceeded

    /// Invalid request parameters
    case invalidRequest(message: String)

    /// Server error
    case serverError(message: String)

    /// Unknown error
    case unknown(message: String)

    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid or missing API key"
        case .httpError(let statusCode, let message):
            return "HTTP error \(statusCode): \(message)"
        case .timeout:
            return "Request timed out"
        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case .encodingError(let underlying):
            return "Failed to encode request: \(underlying.localizedDescription)"
        case .decodingError(let underlying):
            return "Failed to decode response: \(underlying.localizedDescription)"
        case .streamInterrupted:
            return "Stream was interrupted"
        case .rateLimitExceeded(let retryAfter):
            if let retryAfter {
                return "Rate limit exceeded. Retry after \(retryAfter) seconds"
            }
            return "Rate limit exceeded"
        case .quotaExceeded:
            return "Monthly token quota exceeded"
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
