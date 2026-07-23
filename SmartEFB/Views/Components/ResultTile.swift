import SwiftUI

/// A large, high-contrast tile presenting a single computed figure.
///
/// Designed to be read at a glance in a moving aircraft: big value, clear unit
/// and an optional accent colour to signal status.
struct ResultTile: View {
    let title: LocalizedStringKey
    let value: Double
    var format: FloatingPointFormatStyle<Double> = .number.precision(.fractionLength(0))
    let unit: String
    var tint: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value, format: format)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(tint)
                Text(unit)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: Theme.cornerRadius))
    }
}
