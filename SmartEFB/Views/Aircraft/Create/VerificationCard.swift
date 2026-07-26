import SwiftUI

/// Shows the cross-check of the imported grid against the worked example printed
/// in the POH: what the handbook says versus what the app now computes.
struct VerificationCard: View {
    let outcome: VerificationOutcome

    private var tint: Color {
        outcome.passed ? Theme.positive : Theme.warning
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(outcome.passed ? "Gegenrechnung bestanden" : "Gegenrechnung abweichend",
                  systemImage: outcome.passed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)

            Text("POH-Beispiel: \(outcome.conditionsSummary)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            comparisonRow(
                title: "Rollstrecke",
                expected: outcome.expectedGroundRollM,
                computed: outcome.computedGroundRollM
            )
            comparisonRow(
                title: "Über 50 ft",
                expected: outcome.expectedDistanceOver50ftM,
                computed: outcome.computedDistanceOver50ftM
            )

            HStack {
                Text("Max. Abweichung")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(outcome.maxDeviationPercent, format: .number.precision(.fractionLength(0)))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                Text("%")
                    .font(.caption)
                    .foregroundStyle(tint)
            }
        }
        .padding()
        .background(tint.opacity(0.12), in: .rect(cornerRadius: Theme.cornerRadius))
        .transition(.scale(scale: 0.96).combined(with: .opacity))
    }

    private func comparisonRow(title: LocalizedStringKey, expected: Double, computed: Double) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("POH \(Int(expected.rounded())) m")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("App \(Int(computed.rounded())) m")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(tint)
        }
    }
}
