import SwiftUI
import PhotosUI
import UIKit

/// Form section driving the AI import of a POH page: which chart it is, picking
/// or capturing the photo, progress, and the resulting confidence / warnings.
struct POHImportSection: View {
    @Bindable var vm: AircraftDraftViewModel

    let selectedImage: UIImage?
    let hasKey: Bool
    @Binding var pickerItem: PhotosPickerItem?
    var onTakePhoto: () -> Void
    var onOpenSettings: () -> Void

    var body: some View {
        Section {
            if !hasKey {
                missingKeyNotice
            }

            Picker("Diese Seite zeigt", selection: $vm.importKind) {
                ForEach(POHTableKind.allCases) { kind in
                    Label(kind.displayName, systemImage: kind.systemImage).tag(kind)
                }
            }

            Toggle(isOn: $vm.refineEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Zweiter Prüfdurchgang")
                    Text("Die KI kontrolliert ihre eigene Ablesung. Genauer, dauert länger.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let selectedImage {
                AnalyzingScanView(
                    image: selectedImage,
                    isAnalyzing: vm.importState.isBusy,
                    phaseLabel: phaseLabel
                )
                .frame(maxHeight: 280)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 4)
            }

            HStack(spacing: 12) {
                Button(action: onTakePhoto) {
                    Label("Foto", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasKey || vm.importState.isBusy)

                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Aus Fotos", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!hasKey || vm.importState.isBusy)
            }
            .padding(.vertical, 4)

            statusContent
        } header: {
            Label("POH-Import per KI", systemImage: "sparkles")
        } footer: {
            Text("Auch reine Diagramme (Nomogramme) werden gelesen: die KI verfolgt die Kurven und erzeugt daraus eine Tabelle, mit der die App rechnet.")
        }
    }

    private var phaseLabel: String {
        switch vm.importState {
        case .extracting: "KI liest die POH-Seite …"
        case .refining: "KI prüft ihre Ablesung …"
        default: "Analyse läuft …"
        }
    }

    @ViewBuilder
    private var statusContent: some View {
        switch vm.importState {
        case .idle, .extracting, .refining:
            EmptyView()
        case .success:
            VStack(spacing: 10) {
                ImportStatusBanner(confidence: vm.confidence, warnings: vm.warnings)
                if let verification = vm.verification {
                    VerificationCard(outcome: verification)
                }
            }
            .listRowInsets(EdgeInsets())
            .padding(.vertical, 4)
        case .failed(let message):
            Label {
                Text(message)
                    .font(.footnote)
            } icon: {
                Image(systemName: "xmark.octagon")
                    .foregroundStyle(Theme.warning)
            }
            .padding(.vertical, 4)
        }
    }

    private var missingKeyNotice: some View {
        Button(action: onOpenSettings) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("OpenAI-API-Key erforderlich")
                        .font(.subheadline.weight(.semibold))
                    Text("Zum Einrichten tippen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "key.horizontal")
                    .foregroundStyle(Theme.caution)
            }
        }
        .buttonStyle(.plain)
    }
}
