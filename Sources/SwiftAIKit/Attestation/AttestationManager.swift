import Foundation
import DeviceCheck
import CryptoKit

/// Manages App Attest operations for device attestation
///
/// Provides hardware-backed device verification using Apple's App Attest framework.
/// Requires iOS 14.0+, macOS 11.0+, tvOS 15.0+, or watchOS 9.0+.
@available(iOS 14.0, macOS 11.0, tvOS 15.0, watchOS 9.0, *)
actor AttestationManager {
    private let service = DCAppAttestService.shared
    private let userDefaults: UserDefaults
    private let keyIdKey = "com.swiftaikit.attestation.keyId"

    /// Check if App Attest is supported on this device
    var isSupported: Bool {
        service.isSupported
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Key Management

    /// Get stored key ID if available
    /// - Returns: Existing key ID, or nil if not yet generated
    func getKeyId() -> String? {
        userDefaults.string(forKey: keyIdKey)
    }

    /// Ensure attestation key exists, generating if needed
    /// - Returns: The key ID (existing or newly generated)
    /// - Throws: DCError if key generation fails
    func ensureKeyExists() async throws -> String {
        if let existingKeyId = getKeyId() {
            return existingKeyId
        }

        // Generate new key
        let keyId = try await service.generateKey()
        userDefaults.set(keyId, forKey: keyIdKey)
        return keyId
    }

    // MARK: - Attestation

    /// Attest the key with Apple's servers
    /// - Parameter challenge: Base64-encoded challenge from server
    /// - Returns: Base64-encoded attestation object
    /// - Throws: DCError if attestation fails, or if challenge is invalid
    func attestKey(challenge: String) async throws -> String {
        guard let challengeData = Data(base64Encoded: challenge) else {
            throw NSError(
                domain: "SwiftAIKit.Attestation",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid base64 challenge"]
            )
        }

        let keyId = try await ensureKeyExists()

        // Hash the challenge with SHA256
        let challengeHash = SHA256.hash(data: challengeData)
        let challengeHashData = Data(challengeHash)

        // Request attestation from Apple
        let attestationData = try await service.attestKey(keyId, clientDataHash: challengeHashData)

        return attestationData.base64EncodedString()
    }

    // MARK: - Assertions

    /// Generate assertion for request authentication
    /// - Parameters:
    ///   - requestData: Request body data to sign
    ///   - counter: Monotonic counter value
    /// - Returns: Base64-encoded assertion
    /// - Throws: DCError if assertion generation fails
    func generateAssertion(requestData: Data, counter: Int) async throws -> String {
        guard let keyId = getKeyId() else {
            throw NSError(
                domain: "SwiftAIKit.Attestation",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "No attestation key found. Must attest first."]
            )
        }

        // Create client data hash: SHA256(requestData + counter)
        var dataToHash = requestData
        withUnsafeBytes(of: counter.bigEndian) { bytes in
            dataToHash.append(contentsOf: bytes)
        }

        let clientDataHash = SHA256.hash(data: dataToHash)
        let clientDataHashData = Data(clientDataHash)

        // Generate assertion
        let assertionData = try await service.generateAssertion(keyId, clientDataHash: clientDataHashData)

        return assertionData.base64EncodedString()
    }

    // MARK: - Cleanup

    /// Clear all attestation data (key ID from UserDefaults)
    /// - Note: This does not revoke the key with Apple
    func clearAttestation() {
        userDefaults.removeObject(forKey: keyIdKey)
    }
}
