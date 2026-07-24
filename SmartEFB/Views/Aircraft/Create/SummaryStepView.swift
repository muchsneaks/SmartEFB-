import SwiftUI

/// Wizard step 5 – a final read-only summary before saving.
struct SummaryStepView: View {
    let vm: AircraftDraftViewModel

    var body: some View {
        Form {
            Section("Flugzeug") {
                row("Name", vm.name.isEmpty ? "–" : vm.name)
                row("Kennung", vm.registration.isEmpty ? "–" : vm.registration)
                row("Antrieb", vm.propType.displayName)
            }

            Section("Massen") {
                row("Leermasse", "\(Int(vm.emptyWeightKg)) kg")
                row("MTOM", "\(Int(vm.maxTakeoffWeightKg)) kg")
            }

            Section("Leistungsdaten") {
                statusRow("Startstrecke", available: vm.hasTakeoff)
                statusRow("Landestrecke", available: vm.hasLanding)
                row("Cruise-Zeilen", "\(vm.cruiseSettings.count)")
            }

            if !vm.canSave {
                Section {
                    Label("Es fehlen noch Angaben (Name, gültige Massen und mindestens Start-/Lande- oder Cruise-Daten).", systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(Theme.caution)
                }
            }
        }
    }

    private func row(_ title: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }

    private func statusRow(_ title: LocalizedStringKey, available: Bool) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Label(available ? "vorhanden" : "fehlt",
                  systemImage: available ? "checkmark.circle.fill" : "minus.circle")
                .labelStyle(.titleAndIcon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(available ? Theme.positive : .secondary)
        }
    }
}
