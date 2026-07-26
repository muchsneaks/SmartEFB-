import SwiftUI

/// Editable input for every quantity that influences the take-off and landing
/// distance calculation.
///
/// Uses ``BigStepper`` controls throughout so values can be adjusted with large
/// tap targets under turbulence.
struct ConditionsInputView: View {
    @Environment(FlightConditions.self) private var conditions

    var body: some View {
        @Bindable var conditions = conditions

        VStack(spacing: 16) {
            SectionCard(title: "Atmosphäre", systemImage: "thermometer.medium") {
                BigStepper(title: "Platzhöhe", systemImage: "mountain.2",
                           value: $conditions.fieldElevationFt, range: -1000...15000, step: 50,
                           unit: "ft MSL")
                BigStepper(title: "QNH", systemImage: "barometer",
                           value: $conditions.qnhHpa, range: 940...1060, step: 1,
                           unit: "hPa")
                BigStepper(title: "Temperatur (OAT)", systemImage: "thermometer.medium",
                           value: $conditions.temperatureC, range: -40...55, step: 1,
                           unit: "°C")
            }

            SectionCard(title: "Wind", systemImage: "wind") {
                BigStepper(title: "Windrichtung (von)", systemImage: "location.north.line",
                           value: $conditions.windDirectionDeg, range: 0...360, step: 10,
                           unit: "°")
                BigStepper(title: "Windgeschwindigkeit", systemImage: "wind",
                           value: $conditions.windSpeedKt, range: 0...60, step: 1,
                           unit: "kt")
            }

            SectionCard(title: "Piste", systemImage: "road.lanes") {
                BigStepper(title: "Pistenrichtung", systemImage: "arrow.up.forward",
                           value: $conditions.runwayHeadingDeg, range: 0...360, step: 10,
                           unit: "°")
                BigStepper(title: "Verfügbare Länge", systemImage: "ruler",
                           value: $conditions.runwayLengthM, range: 100...5000, step: 25,
                           unit: "m")
                BigStepper(title: "Neigung", systemImage: "triangle",
                           value: $conditions.runwaySlopePercent, range: -5...5, step: 0.1,
                           format: .number.precision(.fractionLength(1)),
                           unit: "% (+ = bergauf)")

                Picker("Oberfläche", selection: $conditions.surface) {
                    ForEach(RunwaySurface.allCases) { surface in
                        Text(surface.displayName).tag(surface)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Zustand", selection: $conditions.runwayCondition) {
                    ForEach(RunwayCondition.allCases) { condition in
                        Text(condition.displayName).tag(condition)
                    }
                }
                .pickerStyle(.segmented)
            }

            SectionCard(title: "Sicherheitszuschlag", systemImage: "shield.lefthalf.filled") {
                BigStepper(title: "Zuschlag auf die erforderliche Strecke",
                           systemImage: "shield.lefthalf.filled",
                           value: $conditions.safetyFactorPercent, range: 0...100, step: 5,
                           unit: "%")
            }
        }
    }
}
