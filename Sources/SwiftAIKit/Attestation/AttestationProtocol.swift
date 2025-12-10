import Foundation

/// Protocol for attestation operations
///
/// Implemented by both real App Attest (AttestationManager) and
/// simulator mock attestation (SimulatorAttestation).
@available(iOS 14.0, macOS 11.0, tvOS 15.0, watchOS 9.0, *)
protocol AttestationProtocol: Actor {
    /// Check if attestation is supported
    var isSupported: Bool { get }

    /// Get stored key ID if available
    func getKeyId() -> String?

    /// Ensure attestation key exists
    func ensureKeyExists() async throws -> String

    /// Attest the key with challenge
    func attestKey(challenge: String) async throws -> String

    /// Generate assertion for request
    func generateAssertion(requestData: Data, counter: Int) async throws -> String

    /// Clear attestation data
    func clearAttestation()
}

// MARK: - Conformance

@available(iOS 14.0, macOS 11.0, tvOS 15.0, watchOS 9.0, *)
extension AttestationManager: AttestationProtocol {}

@available(iOS 14.0, macOS 11.0, tvOS 15.0, watchOS 9.0, *)
extension SimulatorAttestation: AttestationProtocol {}
