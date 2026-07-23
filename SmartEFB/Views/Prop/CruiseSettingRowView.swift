import SwiftUI

/// A single row in the cruise power-settings table.
struct CruiseSettingRowView: View {
    let setting: AdjustedCruiseSetting
    let propType: PropType

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(setting.base.pressureAltitudeFt, format: .number.precision(.fractionLength(0)))
                    .font(.headline)
                    .monospacedDigit()
                Text("ft PA")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 64, alignment: .leading)

            Spacer()

            powerColumn
            valueColumn(setting.adjustedTasKt, unit: "kt TAS", format: .number.precision(.fractionLength(0)))
            valueColumn(setting.base.fuelFlowLph, unit: "l/h", format: .number.precision(.fractionLength(0)))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            setting.isRecommended ? Theme.accent.opacity(0.18) : Color.clear,
            in: .rect(cornerRadius: Theme.cornerRadius)
        )
        .overlay(alignment: .leading) {
            if setting.isRecommended {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.accent)
                    .frame(width: 4)
                    .padding(.vertical, 8)
            }
        }
    }

    private var powerColumn: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if propType == .constantSpeed, let mp = setting.base.manifoldPressureInHg {
                Text("\(mp, format: .number.precision(.fractionLength(0)))\" / \(setting.base.rpm)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            } else {
                Text("\(setting.base.rpm) RPM")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            Text("\(setting.base.percentPower) %")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 96, alignment: .trailing)
    }

    private func valueColumn(
        _ value: Double,
        unit: String,
        format: FloatingPointFormatStyle<Double>
    ) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(value, format: format)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 56, alignment: .trailing)
    }
}
