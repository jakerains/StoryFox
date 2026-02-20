import Foundation
import HuggingFace
import os

/// Thin wrapper around the HuggingFace SDK's `HuggingFaceAuthenticationManager`.
///
/// Login state is cached in UserDefaults so opening Settings never touches the Keychain
/// (which would trigger macOS password prompts on debug builds with changing code signatures).
/// The Keychain is only accessed when the user explicitly signs in or out.
@Observable
@MainActor
final class HuggingFaceOAuth {
    private static let logger = Logger(subsystem: "com.storyfox.app", category: "HFOAuth")

    /// Set this to a registered HuggingFace OAuth client ID before enabling OAuth.
    /// Register at: https://huggingface.co/settings/applications/new
    static var clientID: String = "c73e811a-a6e8-4c79-8935-6691e2bc6c44"

    private static let callbackScheme = "storyfox"
    private static let redirectURI = URL(string: "storyfox://oauth/hf/callback")!
    private static let keychainService = "com.jakerains.StoryFox.hf.oauth"
    private static let keychainAccount = "hf-oauth-token"

    private static let loggedInDefaultsKey = "com.jakerains.StoryFox.hf.oauth.loggedIn"
    private static let usernameDefaultsKey = "com.jakerains.StoryFox.hf.oauth.username"

    private(set) var isLoggedIn: Bool = false
    private(set) var username: String?
    private(set) var isLoggingIn: Bool = false
    private(set) var error: String?

    /// Whether OAuth is available (requires a registered client ID).
    var isOAuthAvailable: Bool {
        !Self.clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var authManager: HuggingFaceAuthenticationManager?

    init() {
        // Restore login state from UserDefaults only — NO Keychain access in init.
        // This prevents macOS password prompts when opening Settings.
        isLoggedIn = UserDefaults.standard.bool(forKey: Self.loggedInDefaultsKey)
        if isLoggedIn {
            username = UserDefaults.standard.string(forKey: Self.usernameDefaultsKey)
        }
    }

    /// Start the OAuth PKCE login flow using the HuggingFace SDK.
    func login() async {
        guard isOAuthAvailable else {
            error = "OAuth not configured. Register a client ID at huggingface.co/settings/applications/new"
            return
        }

        isLoggingIn = true
        error = nil

        if authManager == nil {
            setupAuthManager()
        }

        guard let manager = authManager else {
            error = "Failed to initialize OAuth manager."
            isLoggingIn = false
            return
        }

        do {
            try await manager.signIn()
            isLoggedIn = manager.isAuthenticated

            // Store the access token in CloudCredentialStore so the rest of the app can find it.
            if let token = manager.authToken?.accessToken {
                _ = CloudCredentialStore.saveOAuthAccessToken(token, for: .huggingFace)
                await fetchUsername(token: token)
            }

            // Cache login state in UserDefaults so future Settings opens don't hit Keychain.
            UserDefaults.standard.set(isLoggedIn, forKey: Self.loggedInDefaultsKey)

            Self.logger.info("HuggingFace OAuth login successful")
        } catch {
            let nsError = error as NSError
            // ASWebAuthenticationSessionError.canceledLogin == 1
            if nsError.domain == "com.apple.AuthenticationServices.WebAuthenticationSession",
               nsError.code == 1 {
                self.error = nil // User cancelled — not an error
            } else {
                self.error = "Login failed: \(error.localizedDescription)"
                Self.logger.warning("HuggingFace OAuth failed: \(String(describing: error), privacy: .public)")
            }
        }

        isLoggingIn = false
    }

    /// Log out and clear stored tokens.
    func logout() async {
        if let manager = authManager {
            await manager.signOut()
        }
        CloudCredentialStore.deleteOAuthTokens(for: .huggingFace)
        UserDefaults.standard.set(false, forKey: Self.loggedInDefaultsKey)
        UserDefaults.standard.removeObject(forKey: Self.usernameDefaultsKey)
        isLoggedIn = false
        username = nil
        error = nil
    }

    /// Get a valid access token, refreshing if needed.
    func getValidToken() async -> String? {
        guard let manager = authManager else { return nil }
        return try? await manager.getValidToken()
    }

    // MARK: - Private

    private func setupAuthManager() {
        do {
            let manager = try HuggingFaceAuthenticationManager(
                clientID: Self.clientID,
                redirectURL: Self.redirectURI,
                scope: .inferenceOnly,
                keychainService: Self.keychainService,
                keychainAccount: Self.keychainAccount
            )
            self.authManager = manager
        } catch {
            Self.logger.warning("Failed to initialize HF auth manager: \(String(describing: error), privacy: .public)")
        }
    }

    private func fetchUsername(token: String) async {
        let url = URL(string: "https://huggingface.co/api/whoami-v2")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let name = json["name"] as? String {
                username = name
                UserDefaults.standard.set(name, forKey: Self.usernameDefaultsKey)
            }
        } catch {
            // Non-critical — username is cosmetic
        }
    }
}
