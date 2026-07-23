import SwiftUI

/// Shows cruise / power settings for the selected aircraft, highlighting the
/// row that best matches the current pressure altitude.
struct PropSettingsView: View {
    @Environment(AircraftStore.self) private var store
    @Environment(FlightConditions.self) private var conditions

    private var pressureAltitude: Double {
        AtmosphereCalculator.pressureAltitude(
            elevationFt: conditions.fieldElevationFt,
            qnhHpa: conditions.qnhHpa
        )
    }

    private var adjustedSettings: [AdjustedCruiseSetting] {
        CruiseAdvisor.adjustedSettings(for: store.selected, conditions: conditions.snapshot)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    AircraftHeaderView(aircraft: store.selected)

                    currentConditionsCard

                    SectionCard(title: "Leistungseinstellungen (\(store.selected.propType.displayName))",
                                systemImage: "gauge.with.dots.needle.67percent") {
                        VStack(spacing: 4) {
                            ForEach(adjustedSettings) { setting in
                                CruiseSettingRowView(setting: setting, propType: store.selected.propType)
                                if setting.id != adjustedSettings.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }

                    recommendationCard

                    DisclaimerView()
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Prop & Cruise")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var currentConditionsCard: some View {
        HStack(spacing: 12) {
            ResultTile(title: "Druckhöhe", value: pressureAltitude, unit: "ft", tint: Theme.accent)
            ResultTile(title: "OAT", value: conditions.temperatureC,
                       format: .number.precision(.fractionLength(0)), unit: "°C", tint: Theme.accent)
        }
    }

    @ViewBuilder
    private var recommendationCard: some View {
        if let recommended = adjustedSettings.first(where: { $0.isRecommended }) {
            SectionCard(title: "Empfehlung für aktuelle Höhe", systemImage: "star.fill") {
                VStack(alignment: .leading, spacing: 8) {
                    if store.selected.propType == .constantSpeed,
                       let mp = recommended.base.manifoldPressureInHg {
                        recommendationRow("Ladedruck / Drehzahl",
                                          "\(Int(mp.rounded()))\" · \(recommended.base.rpm) RPM")
                    } else {
                        recommendationRow("Drehzahl", "\(recommended.base.rpm) RPM")
                    }
                    recommendationRow("Leistung", "\(recommended.base.percentPower) %")
                    recommendationRow("TAS (korrigiert)",
                                      "\(Int(recommended.adjustedTasKt.rounded())) kt")
                    recommendationRow("Verbrauch",
                                      "\(Int(recommended.base.fuelFlowLph.rounded())) l/h")
                }
            }
        }
    }

    private func recommendationRow(_ title: LocalizedStringKey, _ value: String) -> some View {
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
