//
//  KeychainStorage.swift
//  SwiftAIKitDemo
//
//  **REFERENCE IMPLEMENTATION**: Production-ready Keychain storage utility.
//
//  ⚠️ This file is NOT used by the demo app (which uses UserDefaults for simplicity).
//  It's provided as a copy-paste reference for implementing secure storage in your production app.
//
//  This implementation demonstrates best practices for storing API keys
//  and other sensitive credentials in iOS applications using the Keychain.
//
//  To use in your app:
//  1. Copy this file to your project
//  2. Replace UserDefaults/AppStorage with KeychainStorage calls
//  3. See usage examples in the documentation below
//

import Foundation
import Security

/// Secure storage utility for sensitive data using iOS Keychain Services.
///
/// The Keychain provides encrypted storage that:
/// - Persists across app uninstalls (optional)
/// - Is protected by device encryption
/// - Is not backed up to iCloud (by default)
/// - Cannot be accessed by other apps
///
/// Example usage:
/// ```swift
/// // Save API key
/// try KeychainStorage.save(key: "apiKey", value: "sk_live_...")
///
/// // Retrieve API key
/// if let apiKey = KeychainStorage.get(key: "apiKey") {
///     print("API Key: \(apiKey)")
/// }
///
/// // Delete API key
/// try KeychainStorage.delete(key: "apiKey")
/// ```
enum KeychainStorage {

    // MARK: - Configuration

    /// Service identifier for Keychain items.
    /// This should be unique to your app to avoid conflicts.
    private static let service = "com.swiftaikit.demo"

    /// Accessibility level for stored items.
    /// - `.whenUnlockedThisDeviceOnly`: Most secure, data accessible only when device is unlocked
    ///   and will not be backed up or synced.
    private static let accessibility = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

    // MARK: - Public Methods

    /// Saves a string value to the Keychain.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for this value (e.g., "apiKey")
    ///   - value: The string to store securely
    /// - Throws: `KeychainError` if the save operation fails
    static func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        // Build query for the item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility
        ]

        // Delete any existing item first
        SecItemDelete(query as CFDictionary)

        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }

    /// Retrieves a string value from the Keychain.
    ///
    /// - Parameter key: The unique identifier for the value to retrieve
    /// - Returns: The stored string, or `nil` if not found
    /// - Throws: `KeychainError` if the retrieval fails (other than not found)
    static func get(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        // Not found is not an error, just return nil
        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.retrievalFailed(status: status)
        }

        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingFailed
        }

        return string
    }

    /// Deletes a value from the Keychain.
    ///
    /// - Parameter key: The unique identifier for the value to delete
    /// - Throws: `KeychainError` if the deletion fails (not found is not an error)
    static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        // Not found is not an error when deleting
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deletionFailed(status: status)
        }
    }

    /// Checks if a value exists in the Keychain.
    ///
    /// - Parameter key: The unique identifier to check
    /// - Returns: `true` if the value exists, `false` otherwise
    static func exists(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}

// MARK: - Keychain Errors

/// Errors that can occur during Keychain operations.
enum KeychainError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case saveFailed(status: OSStatus)
    case retrievalFailed(status: OSStatus)
    case deletionFailed(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode value for Keychain storage"
        case .decodingFailed:
            return "Failed to decode value from Keychain"
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .retrievalFailed(let status):
            return "Failed to retrieve from Keychain (status: \(status))"
        case .deletionFailed(let status):
            return "Failed to delete from Keychain (status: \(status))"
        }
    }
}
