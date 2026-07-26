import SwiftUI
import PhotosUI
import UIKit

/// A guided, step-by-step wizard for creating – or later editing – a custom
/// aircraft, including AI import of POH performance data from a photo.
struct CreateAircraftView: View {
    @Environment(AircraftStore.self) private var store
    @Environment(APIKeyStore.self) private var keyStore
    @Environment(\.dismiss) private var dismiss

    @State private var vm: AircraftDraftViewModel
    @State private var step: WizardStep
    @State private var goingForward = true

    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    /// Presenting several `.sheet` modifiers from one view is unreliable, so both
    /// sheets are driven by this single value.
    private enum Destination: String, Identifiable {
        case camera, settings
        var id: String { rawValue }
    }

    @State private var destination: Destination?

    /// Creates the wizard for a new aircraft, or pre-filled for editing.
    init(editing aircraft: Aircraft? = nil) {
        if let aircraft {
            _vm = State(initialValue: AircraftDraftViewModel(editing: aircraft))
            _step = State(initialValue: .review)
        } else {
            _vm = State(initialValue: AircraftDraftViewModel())
            _step = State(initialValue: .identity)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WizardProgressBar(current: step)
                WizardStepHeader(step: step)
                    .id(step)
                    .transition(.opacity)

                stepContent
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: goingForward ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: goingForward ? .leading : .trailing).combined(with: .opacity)
                    ))
            }
            .background(Theme.background)
            .navigationTitle(vm.isEditing ? "Flieger bearbeiten" : "Neuer Flieger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                navigationButtons
            }
            .sheet(item: $destination) { destination in
                switch destination {
                case .camera:
                    CameraPicker { image in startAnalysis(with: image) }
                        .ignoresSafeArea()
                case .settings:
                    SettingsView()
                }
            }
            .onChange(of: pickerItem) { _, newItem in
                loadPickedImage(newItem)
            }
            .animation(.snappy, value: step)
        }
    }

    // MARK: - Step content

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .identity:
            IdentityStepView(vm: vm)
        case .weights:
            WeightsStepView(vm: vm)
        case .performance:
            PhotoStepView(
                vm: vm,
                selectedImage: selectedImage,
                hasKey: keyStore.hasKey,
                pickerItem: $pickerItem,
                onTakePhoto: { destination = .camera },
                onOpenSettings: { destination = .settings }
            )
        case .review:
            ReviewStepView(vm: vm)
        case .summary:
            SummaryStepView(vm: vm)
        }
    }

    // MARK: - Navigation bar

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if step.previous != nil {
                Button {
                    goingForward = false
                    if let previous = step.previous { step = previous }
                } label: {
                    Label("Zurück", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                }
                .buttonStyle(.bordered)
            }

            if step == .summary {
                Button {
                    save()
                } label: {
                    Label(vm.isEditing ? "Aktualisieren" : "Speichern", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!vm.canSave)
            } else {
                Button {
                    goingForward = true
                    if let next = step.next { step = next }
                } label: {
                    Label("Weiter", systemImage: "chevron.right")
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canAdvance)
            }
        }
        .controlSize(.large)
        .padding()
        .background(.bar)
    }

    /// Whether the current step is complete enough to move on.
    private var canAdvance: Bool {
        switch step {
        case .identity:
            !vm.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .weights:
            vm.maxTakeoffWeightKg > vm.emptyWeightKg
        case .performance:
            true
        case .review:
            vm.hasAnyPerformanceData
        case .summary:
            true
        }
    }

    private func save() {
        let aircraft = vm.buildAircraft()
        if vm.isEditing {
            store.update(aircraft)
        } else {
            store.add(aircraft)
        }
        dismiss()
    }

    // MARK: - Image handling

    private func loadPickedImage(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                startAnalysis(with: image)
            }
        }
    }

    private func startAnalysis(with image: UIImage) {
        selectedImage = image
        guard let data = ImageProcessing.jpegForUpload(image) else {
            vm.importState = .failed("Das Bild konnte nicht verarbeitet werden.")
            return
        }
        Task {
            await vm.analyze(
                imageData: data,
                mimeType: "image/jpeg",
                apiKey: keyStore.trimmedKey,
                model: keyStore.model
            )
        }
    }
}
