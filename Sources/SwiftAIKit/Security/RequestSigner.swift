import CryptoKit
import Foundation

/// Signs API requests using HMAC-SHA256 to prevent replay attacks and request tampering.
///
/// The signature algorithm:
/// 1. Derive signing key: `SHA256(apiKey + bundleId)`
/// 2. Compute body hash: `SHA256(requestBody)`
/// 3. Build message: `timestamp + "\n" + nonce + "\n" + bodyHash`
/// 4. Generate signature: `HMAC-SHA256(signingKey, message)`
///
/// This ensures that even if an API key is intercepted, it cannot be used
/// from a different app (different bundleId), and requests cannot be replayed
/// (timestamp + nonce validation).
public struct RequestSigner: Sendable {
    private let apiKey: String
    private let bundleId: String

    /// Creates a new request signer.
    /// - Parameters:
    ///   - apiKey: The API key used for authentication.
    ///   - bundleId: The app's bundle identifier.
    public init(apiKey: String, bundleId: String) {
        self.apiKey = apiKey
        self.bundleId = bundleId
    }

    /// Signs a request and returns the signature components.
    /// - Parameter bodyData: The request body data (can be nil for GET requests).
    /// - Returns: A tuple containing timestamp, nonce, and signature.
    public func sign(bodyData: Data?) -> (timestamp: Int64, nonce: String, signature: String) {
        let timestamp = Int64(Date().timeIntervalSince1970)
        let nonce = UUID().uuidString

        let signature = computeSignature(
            timestamp: timestamp,
            nonce: nonce,
            bodyData: bodyData
        )

        return (timestamp, nonce, signature)
    }

    /// Computes the signature for a request.
    /// - Parameters:
    ///   - timestamp: Unix timestamp in seconds.
    ///   - nonce: Unique request identifier.
    ///   - bodyData: The request body data.
    /// - Returns: Base64-encoded HMAC-SHA256 signature.
    public func computeSignature(
        timestamp: Int64,
        nonce: String,
        bodyData: Data?
    ) -> String {
        // 1. Derive signing key: SHA256(apiKey + bundleId)
        let keyMaterial = apiKey + bundleId
        let keyHash = SHA256.hash(data: Data(keyMaterial.utf8))
        let signingKey = SymmetricKey(data: keyHash)

        // 2. Compute body hash: SHA256(requestBody)
        let bodyHash = SHA256.hash(data: bodyData ?? Data()).hexString

        // 3. Build message: timestamp + "\n" + nonce + "\n" + bodyHash
        let message = "\(timestamp)\n\(nonce)\n\(bodyHash)"

        // 4. Generate signature: HMAC-SHA256(signingKey, message)
        let signature = HMAC<SHA256>.authenticationCode(
            for: Data(message.utf8),
            using: signingKey
        )

        return Data(signature).base64EncodedString()
    }
}

// MARK: - Helper Extensions

extension Digest {
    /// Converts the digest to a lowercase hexadecimal string.
    var hexString: String {
        compactMap { String(format: "%02x", $0) }.joined()
    }
}
