import SwiftUI

/// Presents the computed distances, runway margin, derived atmospheric figures
/// and any warnings for a take-off or landing.
struct PerformanceResultView: View {
    let result: PerformanceResult

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ResultTile(title: "Rollstrecke", value: result.groundRollM,
                           unit: "m", tint: Theme.accent)
                ResultTile(title: "Über 50 ft", value: result.distanceOver50ftM,
                           unit: "m", tint: Theme.accent)
            }

            marginTile

            if !result.warnings.isEmpty {
                warningsCard
            }

            SectionCard(title: "Bedingungen (berechnet)", systemImage: "function") {
                infoRow("Druckhöhe", value: result.pressureAltitudeFt, unit: "ft")
                infoRow("Dichtehöhe", value: result.densityAltitudeFt, unit: "ft")
                Divider()
                windRow
            }
        }
    }

    private var marginTile: some View {
        let fits = result.fitsOnRunway
        let tint = fits ? Theme.positive : Theme.warning

        return VStack(alignment: .leading, spacing: 10) {
            Label(fits ? "Piste ausreichend" : "Piste zu kurz",
                  systemImage: fits ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(tint)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Erforderlich")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(result.requiredDistanceM, format: .number.precision(.fractionLength(0)))
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("m")
                    .foregroundStyle(.secondary)
                if result.safetyFactorPercent > 0 {
                    Text("inkl. +\(Int(result.safetyFactorPercent)) %")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Reserve")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(result.marginM, format: .number.precision(.fractionLength(0)))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(tint)
                Text("m")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(tint.opacity(0.14), in: .rect(cornerRadius: Theme.cornerRadius))
    }

    private var warningsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(result.warnings.indices, id: \.self) { index in
                Label {
                    Text(result.warnings[index])
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(Theme.caution)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.caution.opacity(0.12), in: .rect(cornerRadius: Theme.cornerRadius))
    }

    private var windRow: some View {
        HStack {
            let head = result.headwindKt
            Label {
                Text(abs(head), format: .number.precision(.fractionLength(0))) + Text(" kt")
            } icon: {
                Image(systemName: head >= 0 ? "arrow.down.to.line" : "arrow.up.to.line")
            }
            .foregroundStyle(head >= 0 ? Theme.positive : Theme.warning)
            Text(head >= 0 ? "Gegenwind" : "Rückenwind")
                .foregroundStyle(.secondary)

            Spacer()

            Label {
                Text(result.crosswindKt, format: .number.precision(.fractionLength(0))) + Text(" kt")
            } icon: {
                Image(systemName: result.crosswindFromLeft ? "arrow.right" : "arrow.left")
            }
            Text("Seitenwind")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }

    private func infoRow(_ title: LocalizedStringKey, value: Double, unit: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value, format: .number.precision(.fractionLength(0)))
                .monospacedDigit()
                .bold()
            Text(unit)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}
