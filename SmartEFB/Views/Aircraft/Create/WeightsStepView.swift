import SwiftUI

/// Wizard step 2 – the aircraft's weights.
struct WeightsStepView: View {
    @Bindable var vm: AircraftDraftViewModel

    var body: some View {
        Form {
            Section {
                weightRow("Leermasse", value: $vm.emptyWeightKg)
                weightRow("Max. Startmasse (MTOM)", value: $vm.maxTakeoffWeightKg)
                weightRow("Standard-Planungsmasse", value: $vm.defaultPlanningWeightKg)
            } footer: {
                Text("Alle Massen in Kilogramm. Die Planungsmasse ist beim Öffnen der Berechnung voreingestellt.")
            }

            if vm.maxTakeoffWeightKg <= vm.emptyWeightKg {
                Section {
                    Label("Die maximale Startmasse muss größer als die Leermasse sein.", systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(Theme.caution)
                }
            }
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
