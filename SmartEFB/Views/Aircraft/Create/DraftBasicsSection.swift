import SwiftUI

/// Form section for the aircraft's basic identity and weights.
struct DraftBasicsSection: View {
    @Bindable var vm: AircraftDraftViewModel

    var body: some View {
        Section("Basisdaten") {
            TextField("Name (z. B. Cessna 172S)", text: $vm.name)

            TextField("Kennung (z. B. D-EABC)", text: $vm.registration)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()

            TextField("ICAO-Typ (z. B. C172)", text: $vm.icaoType)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()

            Picker("Antrieb", selection: $vm.propType) {
                ForEach(PropType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }

            weightRow("Leermasse", value: $vm.emptyWeightKg)
            weightRow("Max. Startmasse (MTOM)", value: $vm.maxTakeoffWeightKg)
            weightRow("Standard-Planungsmasse", value: $vm.defaultPlanningWeightKg)
        }
    }

    private func weightRow(_ title: LocalizedStringKey, value: Binding<Double>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
            Text("kg")
                .foregroundStyle(.secondary)
        }
    }
}
