import SwiftUI

/// Wizard step 4 – review and correct everything that was imported or entered.
struct ReviewStepView: View {
    @Bindable var vm: AircraftDraftViewModel

    var body: some View {
        Form {
            if let verification = vm.verification {
                Section {
                    VerificationCard(outcome: verification)
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 4)
                }
            }

            PerformancePointsEditor(
                title: "Startstrecken",
                points: $vm.takeoffPoints,
                corrections: $vm.takeoffCorrections,
                isLanding: false
            )

            PerformancePointsEditor(
                title: "Landestrecken",
                points: $vm.landingPoints,
                corrections: $vm.landingCorrections,
                isLanding: true
            )

            cruiseSection
        }
    }

    @ViewBuilder
    private var cruiseSection: some View {
        Section {
            if vm.cruiseSettings.isEmpty {
                Text("Keine Cruise-Daten.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach($vm.cruiseSettings) { $setting in
                    EditableCruiseRow(setting: $setting, showManifold: vm.propType == .constantSpeed)
                }
                .onDelete { offsets in
                    vm.cruiseSettings.remove(atOffsets: offsets)
                }
            }

            Button {
                withAnimation(.snappy) {
                    vm.cruiseSettings.append(
                        CruiseSetting(
                            pressureAltitudeFt: 0,
                            rpm: 2300,
                            manifoldPressureInHg: vm.propType == .constantSpeed ? 25 : nil,
                            percentPower: 65,
                            trueAirspeedKt: 100,
                            fuelFlowLph: 30
                        )
                    )
                }
            } label: {
                Label("Cruise-Zeile hinzufügen", systemImage: "plus.circle")
            }
        } header: {
            Text("Cruise / Leistungseinstellungen")
        }
    }
}
