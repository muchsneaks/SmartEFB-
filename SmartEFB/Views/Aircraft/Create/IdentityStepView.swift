import SwiftUI

/// Wizard step 1 – aircraft identity and engine type.
struct IdentityStepView: View {
    @Bindable var vm: AircraftDraftViewModel

    var body: some View {
        Form {
            Section {
                TextField("Name (z. B. Cessna 172S)", text: $vm.name)

                TextField("Kennung (z. B. D-EABC)", text: $vm.registration)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                TextField("ICAO-Typ (z. B. C172)", text: $vm.icaoType)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            } footer: {
                Text("Der Name erscheint später in der Flugzeugauswahl.")
            }

            Section("Antrieb") {
                Picker("Propeller", selection: $vm.propType) {
                    ForEach(PropType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}
