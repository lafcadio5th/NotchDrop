//
//  AIKeyManager.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import Foundation
import Security

/// Stores and retrieves AI provider API keys securely via macOS Keychain.
///
/// Each provider key is stored as a generic password keyed by
/// the service name and provider identifier (e.g. "openai", "anthropic").
class AIKeyManager {
    static let shared = AIKeyManager()

    private let service = "com.kelvintan.NotchDrop.AIKeys"

    /// Save an API key for a given provider to the Keychain.
    func saveKey(_ key: String, for provider: String) {
        guard let data = key.data(using: .utf8) else { return }

        // Delete any existing entry first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add the new key
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider,
            kSecValueData as String: data,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    /// Retrieve the API key for a given provider from the Keychain.
    func getKey(for provider: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Delete the API key for a given provider from the Keychain.
    func deleteKey(for provider: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider,
        ]
        SecItemDelete(query as CFDictionary)
    }

    /// Check whether a key exists for the given provider.
    func hasKey(for provider: String) -> Bool {
        return getKey(for: provider) != nil
    }
}
