import Foundation
import Observation

/// Observable holder for the OpenAI credentials and model choice.
///
/// The key lives in the Keychain; only the (non-secret) model name is kept in
/// `UserDefaults`.
@MainActor
@Observable
final class APIKeyStore {
    private static let modelDefaultsKey = "openai_model"

    /// The default vision model: widely available and reliable at reading charts.
    static let defaultModel = "gpt-4o"

    /// Models offered in the settings picker.
    static let availableModels = ["gpt-4o", "gpt-4.1", "o4-mini"]

    /// The editable key. Call ``save()`` to persist it to the Keychain.
    var apiKey: String

    /// The model used for POH extraction.
    var model: String {
        didSet { UserDefaults.standard.set(model, forKey: Self.modelDefaultsKey) }
    }

    init() {
        apiKey = KeychainStore.read() ?? ""
        model = UserDefaults.standard.string(forKey: Self.modelDefaultsKey) ?? Self.defaultModel
    }

    /// Whether a non-empty key is currently entered.
    var hasKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The trimmed key for use in requests, or `nil` if empty.
    var trimmedKey: String? {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Persists the current key to the Keychain (or removes it if empty).
    func save() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            KeychainStore.delete()
        } else {
            KeychainStore.save(trimmed)
        }
    }
}
