import Foundation
import Security

/// Generalized Keychain store for cloud provider API keys and OAuth tokens.
/// Each `CloudProvider` uses its own Keychain service to isolate credentials.
enum CloudCredentialStore {

    // MARK: - API Key Operations

    static func saveAPIKey(_ key: String, for provider: CloudProvider) -> Bool {
        save(value: key, service: provider.keychainService, account: "apiKey")
    }

    static func loadAPIKey(for provider: CloudProvider) -> String? {
        load(service: provider.keychainService, account: "apiKey")
    }

    static func deleteAPIKey(for provider: CloudProvider) {
        delete(service: provider.keychainService, account: "apiKey")
    }

    static func hasAPIKey(for provider: CloudProvider) -> Bool {
        loadAPIKey(for: provider) != nil
    }

    // MARK: - OAuth Token Operations (HuggingFace)

    static func saveOAuthAccessToken(_ token: String, for provider: CloudProvider) -> Bool {
        save(value: token, service: provider.keychainService, account: "oauthAccessToken")
    }

    static func loadOAuthAccessToken(for provider: CloudProvider) -> String? {
        load(service: provider.keychainService, account: "oauthAccessToken")
    }

    static func saveOAuthRefreshToken(_ token: String, for provider: CloudProvider) -> Bool {
        save(value: token, service: provider.keychainService, account: "oauthRefreshToken")
    }

    static func loadOAuthRefreshToken(for provider: CloudProvider) -> String? {
        load(service: provider.keychainService, account: "oauthRefreshToken")
    }

    static func deleteOAuthTokens(for provider: CloudProvider) {
        delete(service: provider.keychainService, account: "oauthAccessToken")
        delete(service: provider.keychainService, account: "oauthRefreshToken")
    }

    /// Returns the bearer token to use for API calls.
    /// Checks API key first, then falls back to OAuth access token if available.
    static func bearerToken(for provider: CloudProvider) -> String? {
        if let apiKey = loadAPIKey(for: provider) {
            return apiKey
        }
        return loadOAuthAccessToken(for: provider)
    }

    /// Whether this provider has a usable credential (API key or OAuth token).
    static func isAuthenticated(for provider: CloudProvider) -> Bool {
        bearerToken(for: provider) != nil
    }

    // MARK: - Private Keychain Helpers

    private static func save(value: String, service: String, account: String) -> Bool {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        let attributes: [CFString: Any] = [
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return true
        }

        var addQuery = query
        addQuery[kSecValueData] = data
        addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        return addStatus == errSecSuccess
    }

    private static func load(service: String, account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    private static func delete(service: String, account: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
