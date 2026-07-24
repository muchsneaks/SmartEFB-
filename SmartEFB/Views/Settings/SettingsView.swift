import SwiftUI

/// Settings screen for entering the OpenAI API key used by the AI POH import.
///
/// The key is stored only in the Keychain via ``APIKeyStore`` and never written
/// to the project or synced anywhere.
struct SettingsView: View {
    @Environment(APIKeyStore.self) private var keyStore
    @Environment(\.dismiss) private var dismiss

    @State private var revealed = false
    @State private var savedConfirmation = false

    var body: some View {
        @Bindable var keyStore = keyStore

        NavigationStack {
            Form {
                Section {
                    if revealed {
                        TextField("sk-…", text: $keyStore.apiKey, axis: .vertical)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(.footnote, design: .monospaced))
                    } else {
                        SecureField("sk-…", text: $keyStore.apiKey)
                            .textContentType(.password)
                    }

                    Toggle("Key anzeigen", isOn: $revealed)
                } header: {
                    Text("OpenAI API-Key")
                } footer: {
                    Text("Wird nur lokal im iOS-Schlüsselbund (Keychain) gespeichert – niemals hochgeladen oder im Code abgelegt.")
                }

                Section {
                    Button {
                        keyStore.save()
                        withAnimation { savedConfirmation = true }
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            withAnimation { savedConfirmation = false }
                        }
                    } label: {
                        HStack {
                            Label("Speichern", systemImage: "checkmark.circle")
                            Spacer()
                            if savedConfirmation {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.positive)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .disabled(!keyStore.hasKey)

                    if keyStore.hasKey {
                        Button(role: .destructive) {
                            keyStore.apiKey = ""
                            keyStore.save()
                        } label: {
                            Label("Key entfernen", systemImage: "trash")
                        }
                    }
                }

                Section {
                    Label {
                        Text("Der Key erlaubt kostenpflichtige Anfragen an OpenAI. Teile ihn mit niemandem. Wurde er versehentlich veröffentlicht, widerrufe ihn im OpenAI-Dashboard und erstelle einen neuen.")
                    } icon: {
                        Image(systemName: "exclamationmark.shield")
                            .foregroundStyle(Theme.caution)
                    }
                    .font(.footnote)

                    if let url = URL(string: "https://platform.openai.com/api-keys") {
                        Link(destination: url) {
                            Label("API-Keys verwalten", systemImage: "safari")
                        }
                    }
                } header: {
                    Text("Sicherheit")
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
