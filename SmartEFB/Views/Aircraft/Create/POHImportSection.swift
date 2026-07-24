import SwiftUI
import PhotosUI
import UIKit

/// Form section that drives the AI-assisted import of POH performance data:
/// choosing the table type, picking or capturing a photo, showing progress and
/// surfacing the confidence / warnings afterwards.
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

            Picker("Tabellen-Typ", selection: $vm.importKind) {
                ForEach(POHTableKind.allCases) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            .pickerStyle(.menu)

            if let selectedImage {
                AnalyzingScanView(image: selectedImage, isAnalyzing: vm.importState == .analyzing)
                    .frame(maxHeight: 260)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 4)
            }

            HStack(spacing: 12) {
                Button(action: onTakePhoto) {
                    Label("Foto aufnehmen", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasKey || vm.importState == .analyzing)

                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Aus Fotos", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!hasKey || vm.importState == .analyzing)
            }
            .padding(.vertical, 4)

            statusContent
        } header: {
            Label("POH-Import per KI", systemImage: "sparkles")
        } footer: {
            Text("Fotografiere die Leistungstabelle aus dem Flughandbuch. Die KI liest die Werte aus – bitte anschließend prüfen und ggf. korrigieren.")
        }
    }

    @ViewBuilder
    private var statusContent: some View {
        switch vm.importState {
        case .idle, .analyzing:
            EmptyView()
        case .success:
            ImportStatusBanner(confidence: vm.confidence, warnings: vm.warnings)
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
