import SwiftUI

/// Form section presenting the extracted take-off / landing / cruise data for
/// review and correction before the aircraft is saved.
struct PerformanceReviewSection: View {
    @Bindable var vm: AircraftDraftViewModel

    var body: some View {
        Section("Start & Landung") {
            runwayRows(title: "Start", enabled: $vm.hasTakeoff, performance: $vm.takeoff)
            runwayRows(title: "Landung", enabled: $vm.hasLanding, performance: $vm.landing)
        }

        Section {
            if vm.cruiseSettings.isEmpty {
                Text("Keine Cruise-Daten erkannt.")
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
                withAnimation {
                    vm.cruiseSettings.append(
                        CruiseSetting(pressureAltitudeFt: 0, rpm: 2300,
                                      manifoldPressureInHg: vm.propType == .constantSpeed ? 25 : nil,
                                      percentPower: 65, trueAirspeedKt: 100, fuelFlowLph: 30)
                    )
                }
            } label: {
                Label("Zeile hinzufügen", systemImage: "plus.circle")
            }
        } header: {
            Text("Cruise / Leistungseinstellungen")
        } footer: {
            if !vm.cruiseSettings.isEmpty {
                Text("Zum Löschen einer Zeile nach links wischen.")
            }
        }
    }

    private func runwayRows(title: LocalizedStringKey, enabled: Binding<Bool>, performance: Binding<RunwayPerformance>) -> some View {
        Group {
            Toggle(title, isOn: enabled)
            if enabled.wrappedValue {
                numberRow("Rollstrecke", value: performance.groundRollM)
                numberRow("Über 50 ft", value: performance.distanceOver50ftM)
            }
        }
    }

    private func numberRow(_ title: LocalizedStringKey, value: Binding<Double>) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            TextField(title, value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
            Text("m")
                .foregroundStyle(.secondary)
        }
    }
}
