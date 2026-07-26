import SwiftUI

/// A large, turbulence-friendly stepper control.
///
/// It exposes big plus/minus buttons (with press-and-hold auto-repeat) and a
/// prominent value read-out, so a value can be adjusted without precise typing
/// while the aircraft is moving.
struct BigStepper: View {
    let title: LocalizedStringKey
    let systemImage: String

    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    /// Format style for the displayed value.
    var format: FloatingPointFormatStyle<Double> = .number
    var unit: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                stepButton(systemImage: "minus", amount: -step)

                VStack(spacing: 0) {
                    Text(value, format: format)
                        .font(.system(.title, design: .rounded).weight(.semibold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                stepButton(systemImage: "plus", amount: step)
            }
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: Theme.cornerRadius))
    }

    private func stepButton(systemImage: String, amount: Double) -> some View {
        Button {
            let newValue = (value + amount).clamped(to: range)
            withAnimation(.snappy) { value = newValue }
        } label: {
            Image(systemName: systemImage)
                .font(.title2.bold())
                .frame(width: Theme.controlSize, height: Theme.controlSize)
                .background(Theme.accent.opacity(0.18), in: .rect(cornerRadius: Theme.cornerRadius))
                .foregroundStyle(Theme.accent)
        }
        .buttonRepeatBehavior(.enabled)
        .accessibilityLabel(amount < 0 ? "Verringern" : "Erhöhen")
    }
}
