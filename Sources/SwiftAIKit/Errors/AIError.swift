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

    /// Quota exceeded (legacy token-based)
    case quotaExceeded

    /// Insufficient credits (credits-based billing)
    case insufficientCredits

    /// Invalid request parameters
    case invalidRequest(message: String)

    /// Server error
    case serverError(message: String)

    /// Invalid request signature
    case invalidSignature

    /// Request timestamp expired (replay attack prevention)
    case timestampExpired

    /// Request nonce was reused (replay attack prevention)
    case nonceReused

    /// Invalid Bundle ID for this project
    case invalidBundleId

    /// Invalid Team ID for this project
    case invalidTeamId

    /// Device attestation is required but not provided
    case attestationRequired

    /// Device is not registered for App Attest
    case deviceNotRegistered

    /// Device attestation is invalid or verification failed
    case invalidAttestation

    /// Device attestation has been revoked
    case attestationRevoked

    /// App Attest is not supported on this device
    case attestationNotSupported

    /// Simulator attestation not allowed on production API
    case simulatorNotAllowed

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
        case .insufficientCredits:
            return "Insufficient credits. Please upgrade your plan or wait for quota reset."
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .invalidSignature:
            return "Invalid request signature"
        case .timestampExpired:
            return "Request timestamp is outside acceptable window"
        case .nonceReused:
            return "Request nonce has already been used"
        case .invalidBundleId:
            return "Invalid Bundle ID for this project"
        case .invalidTeamId:
            return "Invalid Team ID for this project"
        case .attestationRequired:
            return "Device attestation is required for API access"
        case .deviceNotRegistered:
            return "Device is not registered. Please allow automatic registration."
        case .invalidAttestation:
            return "Device attestation is invalid or verification failed"
        case .attestationRevoked:
            return "Device attestation has been revoked. Please contact support."
        case .attestationNotSupported:
            return "App Attest is not supported on this device"
        case .simulatorNotAllowed:
            return "Simulator attestation is not allowed on production API. Use test API instead."
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
