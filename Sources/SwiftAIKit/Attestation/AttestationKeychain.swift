import Foundation
import Security

/// Secure keychain storage for attestation counter
///
/// Stores the monotonic counter used for App Attest assertion generation.
/// The counter must always increase to prevent replay attacks.
struct AttestationKeychain: Sendable {
    private let service = "com.swiftaikit.attestation"
    private let counterKey = "assertion_counter"

    /// Get current counter value
    /// - Returns: Current counter, or 0 if not set
    func getCounter() -> Int {
        guard let data = read(key: counterKey),
              let counterString = String(data: data, encoding: .utf8),
              let counter = Int(counterString) else {
            return 0
        }
        return counter
    }

    /// Increment and return new counter value
    /// - Note: Caller must ensure exclusive access (e.g., via actor isolation)
    /// - Returns: New counter value after increment
    func incrementCounter() -> Int {
        let current = getCounter()
        let next = current + 1
        write(key: counterKey, data: String(next).data(using: .utf8)!)
        return next
    }

    /// Clear all stored attestation data
    func clear() {
        delete(key: counterKey)
    }

    // MARK: - Keychain Operations

    private func read(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private func write(key: String, data: Data) {
        // Try to update first
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
        ]

        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        // If update failed because item doesn't exist, add it
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            status = SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
