import SwiftUI

/// The computed take-off or landing figures, presented as a scannable panel.
struct PerformanceResultsPanel: View {
    let result: PerformanceResult
    let mode: PerformanceMode
    let vSpeeds: VSpeeds?

    var body: some View {
        VStack(spacing: 14) {
            VerdictBanner(result: result)

            SectionCard(title: "Strecken", systemImage: "ruler") {
                ValueRow(title: mode == .takeoff ? "Startrollstrecke" : "Landerollstrecke",
                         value: metres(result.groundRollM))
                ValueRow(title: "Über 50 ft (15 m)",
                         value: metres(result.distanceOver50ftM))
                Divider()
                ValueRow(title: result.safetyFactorPercent > 0
                         ? "Erforderlich (+\(Int(result.safetyFactorPercent)) %)"
                         : "Erforderlich",
                         value: metres(result.requiredDistanceM),
                         tint: result.fitsOnRunway ? Theme.positive : Theme.warning,
                         isProminent: true)
                ValueRow(title: "Reserve",
                         value: metres(result.marginM),
                         tint: result.fitsOnRunway ? Theme.positive : Theme.warning)
            }

            SectionCard(title: "Korrekturen", systemImage: "slider.horizontal.3") {
                if let dominant = result.dominantPenalty {
                    ValueRow(title: LocalizedStringKey("Größter Zuschlag: \(dominant.name)"),
                             value: "+\(percent(dominant.percentChange))",
                             tint: Theme.caution,
                             isProminent: true)
                } else {
                    ValueRow(title: "Keine Verlängerung",
                             value: "±0 %",
                             tint: Theme.positive,
                             isProminent: true)
                }

                let relevant = result.factors.filter { !$0.isNeutral }
                if !relevant.isEmpty {
                    Divider()
                    ValueRow(title: "Tabellenwert (unkorrigiert)",
                             value: metres(result.chartDistanceM),
                             tint: .secondary)
                    ForEach(relevant) { factor in
                        ValueRow(title: LocalizedStringKey(factor.name),
                                 value: signedPercent(factor.percentChange),
                                 tint: tint(for: factor))
                    }
                }
            }

            if let vSpeeds {
                SpeedsCard(vSpeeds: vSpeeds, mode: mode)
            }

            SectionCard(title: "Atmosphäre", systemImage: "thermometer.medium") {
                ValueRow(title: "Druckhöhe", value: "\(Int(result.pressureAltitudeFt.rounded())) ft")
                ValueRow(title: "Dichtehöhe", value: "\(Int(result.densityAltitudeFt.rounded())) ft")
                ValueRow(title: result.headwindKt >= 0 ? "Gegenwind" : "Rückenwind",
                         value: "\(Int(abs(result.headwindKt).rounded())) kt",
                         tint: result.headwindKt >= 0 ? Theme.positive : Theme.warning)
                ValueRow(title: "Seitenwind",
                         value: "\(Int(result.crosswindKt.rounded())) kt von \(result.crosswindFromLeft ? "links" : "rechts")")
            }

            if !result.warnings.isEmpty {
                WarningsCard(warnings: result.warnings)
            }
        }
    }

    private func metres(_ value: Double) -> String {
        "\(Int(value.rounded())) m"
    }

    private func percent(_ value: Double) -> String {
        "\(Int(value.rounded())) %"
    }

    private func signedPercent(_ value: Double) -> String {
        let rounded = Int(value.rounded())
        if rounded == 0 { return "±0 %" }
        return rounded > 0 ? "+\(rounded) %" : "\(rounded) %"
    }

    private func tint(for factor: PerformanceFactor) -> Color {
        if factor.isPenalty { return Theme.caution }
        if factor.isBenefit { return Theme.positive }
        return .secondary
    }
}

/// The headline go / no-go statement.
private struct VerdictBanner: View {
    let result: PerformanceResult

    private var fits: Bool { result.fitsOnRunway }
    private var tint: Color { fits ? Theme.positive : Theme.warning }

    /// How much of the runway the required distance uses.
    private var usedFraction: Double {
        let available = result.requiredDistanceM + result.marginM
        guard available > 0 else { return 1 }
        return (result.requiredDistanceM / available).clamped(to: 0...1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(fits ? "Piste ausreichend" : "Piste zu kurz",
                      systemImage: fits ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(tint)
                Spacer()
                Text(usedFraction, format: .percent.precision(.fractionLength(0)))
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(tint)
            }

            ProgressView(value: usedFraction)
                .tint(tint)

            Text(fits
                 ? "Die erforderliche Strecke passt auf die verfügbare Bahn."
                 : "Die erforderliche Strecke überschreitet die verfügbare Bahn.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(tint.opacity(0.14), in: .rect(cornerRadius: Theme.cornerRadius))
    }
}

/// Key speeds relevant to the selected phase of flight.
private struct SpeedsCard: View {
    let vSpeeds: VSpeeds
    let mode: PerformanceMode

    var body: some View {
        SectionCard(title: "Geschwindigkeiten", systemImage: "speedometer") {
            if mode == .takeoff {
                speedRow("Vr (Rotation)", vSpeeds.rotateKt)
                speedRow("Vx (bester Winkel)", vSpeeds.bestAngleOfClimbKt)
                speedRow("Vy (beste Rate)", vSpeeds.bestRateOfClimbKt)
            } else {
                speedRow("Vref (Anflug)", vSpeeds.approachKt)
                speedRow("Vs0 (Überziehen)", vSpeeds.stallLandingKt)
            }
        }
    }

    @ViewBuilder
    private func speedRow(_ title: LocalizedStringKey, _ value: Double) -> some View {
        if value > 0 {
            ValueRow(title: title, value: "\(Int(value.rounded())) kt")
        }
    }
}

/// Notes the pilot must be aware of before using the numbers.
private struct WarningsCard: View {
    let warnings: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(warnings.indices, id: \.self) { index in
                Label {
                    Text(warnings[index])
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
}
