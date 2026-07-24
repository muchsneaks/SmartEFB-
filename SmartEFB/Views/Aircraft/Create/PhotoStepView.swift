import SwiftUI
import PhotosUI
import UIKit

/// Wizard step 3 – AI import of performance data from a POH photo. Optional: the
/// pilot can skip and enter the data manually in the next step.
struct PhotoStepView: View {
    @Bindable var vm: AircraftDraftViewModel

    let selectedImage: UIImage?
    let hasKey: Bool
    @Binding var pickerItem: PhotosPickerItem?
    var onTakePhoto: () -> Void
    var onOpenSettings: () -> Void

    var body: some View {
        Form {
            POHImportSection(
                vm: vm,
                selectedImage: selectedImage,
                hasKey: hasKey,
                pickerItem: $pickerItem,
                onTakePhoto: onTakePhoto,
                onOpenSettings: onOpenSettings
            )

            Section {
                Label("Diesen Schritt kannst du überspringen und die Werte im nächsten Schritt selbst eingeben.", systemImage: "hand.point.up.left")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
