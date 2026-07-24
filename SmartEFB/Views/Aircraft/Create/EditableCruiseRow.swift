import SwiftUI

/// One editable row of the imported cruise power table, so the pilot can correct
/// any misread value before saving.
struct EditableCruiseRow: View {
    @Binding var setting: CruiseSetting
    let showManifold: Bool

    var body: some View {
        VStack(spacing: 8) {
            numberField("Druckhöhe", value: $setting.pressureAltitudeFt, unit: "ft")
            HStack(spacing: 12) {
                intField("RPM", value: $setting.rpm)
                if showManifold {
                    optionalManifoldField
                }
                intField("% Leistung", value: $setting.percentPower)
            }
            HStack(spacing: 12) {
                numberField("TAS", value: $setting.trueAirspeedKt, unit: "kt")
                numberField("Verbrauch", value: $setting.fuelFlowLph, unit: "l/h")
            }
        }
        .padding(.vertical, 6)
    }

    private var optionalManifoldField: some View {
        let binding = Binding(
            get: { setting.manifoldPressureInHg ?? 0 },
            set: { setting.manifoldPressureInHg = $0 }
        )
        return numberField("MP", value: binding, unit: "inHg")
    }

    private func numberField(_ title: LocalizedStringKey, value: Binding<Double>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                TextField(title, value: value, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func intField(_ title: LocalizedStringKey, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            TextField(title, value: value, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
        }
    }
}
