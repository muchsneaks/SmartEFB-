import SwiftUI

/// Detailed reference information for a single aircraft: weights, the extent of
/// its performance charts and key operating speeds.
struct AircraftDetailView: View {
    let aircraft: Aircraft

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AircraftHeaderView(aircraft: aircraft)

                SectionCard(title: "Massen", systemImage: "scalemass") {
                    infoRow("Leermasse", "\(Int(aircraft.emptyWeightKg)) kg")
                    infoRow("Max. Startmasse (MTOM)", "\(Int(aircraft.maxTakeoffWeightKg)) kg")
                    infoRow("Antrieb", aircraft.propType.displayName)
                }

                tableCard(title: "Starttabelle", table: aircraft.takeoffTable)
                tableCard(title: "Landetabelle", table: aircraft.landingTable)

                if let speeds = aircraft.vSpeeds {
                    SectionCard(title: "Geschwindigkeiten (KIAS)", systemImage: "speedometer") {
                        infoRow("Vr (Rotation)", speed(speeds.rotateKt))
                        infoRow("Vx (bester Winkel)", speed(speeds.bestAngleOfClimbKt))
                        infoRow("Vy (beste Rate)", speed(speeds.bestRateOfClimbKt))
                        infoRow("Vref (Anflug)", speed(speeds.approachKt))
                        infoRow("Vs0 (Überziehen)", speed(speeds.stallLandingKt))
                        infoRow("Vne (nie überschreiten)", speed(speeds.neverExceedKt))
                    }
                }

                DisclaimerView()
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(aircraft.icaoType.isEmpty ? aircraft.name : aircraft.icaoType)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func tableCard(title: LocalizedStringKey, table: PerformanceTable?) -> some View {
        SectionCard(title: title, systemImage: "tablecells") {
            if let table, !table.isEmpty {
                infoRow("Stützpunkte", "\(table.points.count)")
                infoRow("Druckhöhen", rangeText(table.pressureAltitudes, unit: "ft"))
                infoRow("Temperaturen", rangeText(table.temperatures, unit: "°C"))
                infoRow("Massen", rangeText(table.weights, unit: "kg"))
                Divider()
                infoRow("Gegenwind", "\(percent(table.corrections.headwindPerKt)) / kt")
                infoRow("Rückenwind", "+\(percent(table.corrections.tailwindPerKt)) / kt")
                infoRow("Gras", "× \(format(table.corrections.grassFactor))")
                infoRow("Nass", "× \(format(table.corrections.wetFactor))")
                infoRow("Neigung", "\(percent(table.corrections.slopePerPercent)) / %")
                if let note = table.configurationNote, !note.isEmpty {
                    Divider()
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Nicht hinterlegt")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func rangeText(_ values: [Double], unit: String) -> String {
        guard let first = values.first, let last = values.last else { return "–" }
        if values.count == 1 { return "\(Int(first)) \(unit)" }
        return "\(Int(first)) – \(Int(last)) \(unit)"
    }

    private func percent(_ fraction: Double) -> String {
        "\(format(fraction * 100)) %"
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }

    private func speed(_ value: Double) -> String {
        value > 0 ? "\(Int(value)) kt" : "–"
    }

    private func infoRow(_ title: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .bold()
                .monospacedDigit()
        }
        .font(.subheadline)
    }
}
