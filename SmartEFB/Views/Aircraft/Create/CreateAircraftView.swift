import SwiftUI
import PhotosUI
import UIKit

/// The full flow for creating a custom aircraft, including AI import of POH
/// performance data from a photo.
struct CreateAircraftView: View {
    @Environment(AircraftStore.self) private var store
    @Environment(APIKeyStore.self) private var keyStore
    @Environment(\.dismiss) private var dismiss

    @State private var vm = AircraftDraftViewModel()
    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var showSettings = false

    private var hasImportedOrManualData: Bool {
        vm.hasImportedData || vm.hasTakeoff || vm.hasLanding || !vm.cruiseSettings.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                DraftBasicsSection(vm: vm)

                POHImportSection(
                    vm: vm,
                    selectedImage: selectedImage,
                    hasKey: keyStore.hasKey,
                    pickerItem: $pickerItem,
                    onTakePhoto: { showCamera = true },
                    onOpenSettings: { showSettings = true }
                )

                if hasImportedOrManualData {
                    PerformanceReviewSection(vm: vm)
                }
            }
            .navigationTitle("Neuer Flieger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        store.addCustom(vm.buildAircraft())
                        dismiss()
                    }
                    .disabled(!vm.canSave)
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in
                    startAnalysis(with: image)
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onChange(of: pickerItem) { _, newItem in
                loadPickedImage(newItem)
            }
            .animation(.snappy, value: vm.importState)
            .animation(.snappy, value: hasImportedOrManualData)
        }
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
            await vm.analyze(imageData: data, mimeType: "image/jpeg", apiKey: keyStore.trimmedKey)
        }
    }
}
