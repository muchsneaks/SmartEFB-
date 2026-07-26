import SwiftUI

/// Shows cruise / power settings for the selected aircraft.
struct PropSettingsView: View {
    @Environment(AircraftStore.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if let aircraft = store.selected {
                    PropSettingsContentView(aircraft: aircraft)
                } else {
                    NoAircraftView()
                }
            }
            .background(Theme.background)
            .navigationTitle("Prop & Cruise")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// The cruise table for one selected aircraft, highlighting the row that best
/// matches the current pressure altitude.
private struct PropSettingsContentView: View {
    let aircraft: Aircraft

    @Environment(FlightConditions.self) private var conditions

    private var pressureAltitude: Double {
        AtmosphereCalculator.pressureAltitude(
            elevationFt: conditions.fieldElevationFt,
            qnhHpa: conditions.qnhHpa
        )
    }

    private var settings: [AdjustedCruiseSetting] {
        CruiseAdvisor.adjustedSettings(for: aircraft, conditions: conditions.snapshot)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AircraftHeaderView(aircraft: aircraft)

                HStack(spacing: 12) {
                    ResultTile(title: "Druckhöhe", value: pressureAltitude,
                               unit: "ft", tint: Theme.accent)
                    ResultTile(title: "OAT", value: conditions.temperatureC,
                               format: .number.precision(.fractionLength(0)),
                               unit: "°C", tint: Theme.accent)
                }

                if settings.isEmpty {
                    MissingDataView(
                        title: "Keine Cruise-Daten",
                        message: "Für dieses Flugzeug ist noch keine Leistungstabelle hinterlegt. Bearbeite das Flugzeug und importiere die Cruise-Seite aus dem POH."
                    )
                    .padding(.vertical)
                } else {
                    SectionCard(title: "Leistungseinstellungen (\(aircraft.propType.displayName))",
                                systemImage: "gauge.with.dots.needle.67percent") {
                        VStack(spacing: 4) {
                            ForEach(settings) { setting in
                                CruiseSettingRowView(setting: setting, propType: aircraft.propType)
                                if setting.id != settings.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }

                    RecommendationCard(settings: settings, propType: aircraft.propType)
                }

                DisclaimerView()
            }
            .padding()
        }
    }
}

/// Highlights the single power setting closest to the current pressure altitude.
private struct RecommendationCard: View {
    let settings: [AdjustedCruiseSetting]
    let propType: PropType

    var body: some View {
        if let recommended = settings.first(where: { $0.isRecommended }) {
            SectionCard(title: "Empfehlung für aktuelle Höhe", systemImage: "star.fill") {
                VStack(alignment: .leading, spacing: 8) {
                    if propType == .constantSpeed, let mp = recommended.base.manifoldPressureInHg {
                        row("Ladedruck / Drehzahl", "\(Int(mp.rounded()))\" · \(recommended.base.rpm) RPM")
                    } else {
                        row("Drehzahl", "\(recommended.base.rpm) RPM")
                    }
                    row("Leistung", "\(recommended.base.percentPower) %")
                    row("TAS (korrigiert)", "\(Int(recommended.adjustedTasKt.rounded())) kt")
                    row("Verbrauch", "\(Int(recommended.base.fuelFlowLph.rounded())) l/h")
                }
            }
        }
    }

    private func row(_ title: LocalizedStringKey, _ value: String) -> some View {
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
