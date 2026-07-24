import Foundation
import Observation

/// Observable holder for the OpenAI API key, backed by the Keychain.
@MainActor
@Observable
final class APIKeyStore {
    /// The editable key. Call ``save()`` to persist it to the Keychain.
    var apiKey: String

    init() {
        apiKey = KeychainStore.read() ?? ""
    }

    /// Whether a non-empty key is currently entered.
    var hasKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The trimmed key value for use in requests, or `nil` if empty.
    var trimmedKey: String? {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Persists the current value to the Keychain (or removes it if empty).
    func save() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            KeychainStore.delete()
        } else {
            KeychainStore.save(trimmed)
        }
    }
}
