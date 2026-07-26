import SwiftUI
import PhotosUI
import UIKit

/// Wizard step 3 – AI import of performance data from POH pages.
///
/// Several pages can be imported one after another (take-off chart, landing
/// chart, cruise table); a badge row shows what is already covered.
struct PhotoStepView: View {
    @Bindable var vm: AircraftDraftViewModel

    let selectedImage: UIImage?
    let hasKey: Bool
    @Binding var pickerItem: PhotosPickerItem?
    var onTakePhoto: () -> Void
    var onOpenSettings: () -> Void

    var body: some View {
        Form {
            Section {
                HStack(spacing: 8) {
                    badge("Start", available: !vm.takeoffPoints.isEmpty)
                    badge("Landung", available: !vm.landingPoints.isEmpty)
                    badge("Cruise", available: !vm.cruiseSettings.isEmpty)
                }
                .frame(maxWidth: .infinity)
                .animation(.snappy, value: vm.takeoffPoints.count + vm.landingPoints.count + vm.cruiseSettings.count)
            } header: {
                Text("Bereits erfasst")
            } footer: {
                Text("Du kannst mehrere Seiten nacheinander importieren – wähle oben jeweils den passenden Seitentyp.")
            }

            POHImportSection(
                vm: vm,
                selectedImage: selectedImage,
                hasKey: hasKey,
                pickerItem: $pickerItem,
                onTakePhoto: onTakePhoto,
                onOpenSettings: onOpenSettings
            )

            Section {
                Label("Diesen Schritt kannst du überspringen und alle Werte im nächsten Schritt selbst eintragen.",
                      systemImage: "hand.point.up.left")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func badge(_ title: String, available: Bool) -> some View {
        Label(title, systemImage: available ? "checkmark.circle.fill" : "circle.dashed")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                (available ? Theme.positive : Color.secondary).opacity(available ? 0.2 : 0.12),
                in: .capsule
            )
            .foregroundStyle(available ? Theme.positive : .secondary)
    }
}
