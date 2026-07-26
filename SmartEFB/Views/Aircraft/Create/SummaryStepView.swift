import SwiftUI

/// Wizard step 5 – a final read-only summary before saving.
struct SummaryStepView: View {
    let vm: AircraftDraftViewModel

    var body: some View {
        Form {
            Section("Flugzeug") {
                row("Name", vm.name.isEmpty ? "–" : vm.name)
                row("Kennung", vm.registration.isEmpty ? "–" : vm.registration)
                row("Typ", vm.icaoType.isEmpty ? "–" : vm.icaoType.uppercased())
                row("Antrieb", vm.propType.displayName)
            }

            Section("Massen") {
                row("Leermasse", "\(Int(vm.emptyWeightKg)) kg")
                row("MTOM", "\(Int(vm.maxTakeoffWeightKg)) kg")
                row("Planungsmasse", "\(Int(vm.defaultPlanningWeightKg)) kg")
            }

            Section("Leistungsdaten") {
                countRow("Startstrecken", count: vm.takeoffPoints.count, unit: "Stützpunkte")
                countRow("Landestrecken", count: vm.landingPoints.count, unit: "Stützpunkte")
                countRow("Cruise", count: vm.cruiseSettings.count, unit: "Zeilen")
            }

            if let verification = vm.verification {
                Section("Gegenrechnung") {
                    VerificationCard(outcome: verification)
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 4)
                }
            }

            Section {
                Label("Alle Werte stammen aus deinem Flughandbuch und sollten vor dem ersten Einsatz noch einmal gegen das POH geprüft werden.",
                      systemImage: "exclamationmark.shield")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if !vm.canSave {
                    Label("Es fehlen noch Angaben: Name, gültige Massen und mindestens eine Start-, Lande- oder Cruise-Tabelle.",
                          systemImage: "exclamationmark.triangle")
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

    private func countRow(_ title: LocalizedStringKey, count: Int, unit: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            if count > 0 {
                Label("\(count) \(unit)", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.positive)
            } else {
                Label("fehlt", systemImage: "minus.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
