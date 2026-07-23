import SwiftUI

/// Presents the computed distances, runway margin and derived atmospheric
/// figures for a take-off or landing.
struct PerformanceResultView: View {
    let mode: PerformanceMode
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
        return VStack(alignment: .leading, spacing: 4) {
            Label(fits ? "Piste ausreichend" : "Piste zu kurz",
                  systemImage: fits ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(fits ? Theme.positive : Theme.warning)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("Reserve")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(result.marginM, format: .number.precision(.fractionLength(0)))
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(fits ? Theme.positive : Theme.warning)
                Text("m")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background((fits ? Theme.positive : Theme.warning).opacity(0.14),
                    in: .rect(cornerRadius: Theme.cornerRadius))
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
