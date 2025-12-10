import Foundation
import CryptoKit

/// Mock attestation implementation for iOS Simulator
///
/// App Attest only works on physical devices. This provides fake attestation
/// for development and testing in the simulator environment.
@available(iOS 14.0, macOS 11.0, tvOS 15.0, watchOS 9.0, *)
actor SimulatorAttestation {
    private let userDefaults: UserDefaults
    private let keyIdKey = "com.swiftaikit.attestation.simulator.keyId"

    /// Simulator attestation is always "supported"
    var isSupported: Bool { true }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Key Management

    /// Get stored simulator key ID
    func getKeyId() -> String? {
        userDefaults.string(forKey: keyIdKey)
    }

    /// Generate or retrieve simulator key ID (SIM-{UUID} format)
    func ensureKeyExists() async throws -> String {
        if let existingKeyId = getKeyId() {
            return existingKeyId
        }

        // Generate simulator key ID
        let keyId = "SIM-\(UUID().uuidString)"
        userDefaults.set(keyId, forKey: keyIdKey)
        return keyId
    }

    // MARK: - Mock Attestation

    /// Generate fake attestation object for simulator
    /// - Parameter challenge: Base64-encoded challenge from server
    /// - Returns: Base64-encoded JSON attestation object
    func attestKey(challenge: String) async throws -> String {
        let keyId = try await ensureKeyExists()

        // Create mock attestation object
        let attestation: [String: Any] = [
            "keyId": keyId,
            "challenge": challenge,
            "environment": "simulator",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "bundleId": Bundle.main.bundleIdentifier ?? "unknown",
            "mockAttestation": true,
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: attestation)
        return jsonData.base64EncodedString()
    }

    // MARK: - Mock Assertions

    /// Generate fake assertion for simulator
    /// - Parameters:
    ///   - requestData: Request body data
    ///   - counter: Monotonic counter value
    /// - Returns: Base64-encoded JSON assertion
    func generateAssertion(requestData: Data, counter: Int) async throws -> String {
        guard let keyId = getKeyId() else {
            throw NSError(
                domain: "SwiftAIKit.SimulatorAttestation",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No simulator key found"]
            )
        }

        // Create simple hash for mock signature
        var dataToHash = requestData
        withUnsafeBytes(of: counter.bigEndian) { bytes in
            dataToHash.append(contentsOf: bytes)
        }
        let hash = SHA256.hash(data: dataToHash)

        let assertion: [String: Any] = [
            "keyId": keyId,
            "counter": counter,
            "signature": Data(hash).base64EncodedString(),
            "environment": "simulator",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "mockAssertion": true,
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: assertion)
        return jsonData.base64EncodedString()
    }

    // MARK: - Cleanup

    /// Clear simulator attestation data
    func clearAttestation() {
        userDefaults.removeObject(forKey: keyIdKey)
    }
}
