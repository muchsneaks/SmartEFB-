import SwiftUI

/// Editable input for the shared atmospheric, wind and runway conditions.
///
/// Uses ``BigStepper`` controls throughout so values can be adjusted with
/// large tap targets under turbulence.
struct ConditionsInputView: View {
    @Environment(FlightConditions.self) private var conditions

    var body: some View {
        @Bindable var conditions = conditions

        VStack(spacing: 16) {
            SectionCard(title: "Atmosphäre", systemImage: "thermometer.medium") {
                BigStepper(title: "Platzhöhe", systemImage: "mountain.2",
                           value: $conditions.fieldElevationFt, range: -1000...15000, step: 100,
                           unit: "ft MSL")
                BigStepper(title: "QNH", systemImage: "barometer",
                           value: $conditions.qnhHpa, range: 950...1050, step: 1,
                           unit: "hPa")
                BigStepper(title: "Temperatur (OAT)", systemImage: "thermometer.medium",
                           value: $conditions.temperatureC, range: -40...50, step: 1,
                           unit: "°C")
            }

            SectionCard(title: "Wind", systemImage: "wind") {
                BigStepper(title: "Windrichtung", systemImage: "location.north.line",
                           value: $conditions.windDirectionDeg, range: 0...360, step: 10,
                           unit: "° (von)")
                BigStepper(title: "Windgeschwindigkeit", systemImage: "wind",
                           value: $conditions.windSpeedKt, range: 0...60, step: 1,
                           unit: "kt")
            }

            SectionCard(title: "Piste", systemImage: "road.lanes") {
                BigStepper(title: "Pistenrichtung", systemImage: "arrow.up.forward",
                           value: $conditions.runwayHeadingDeg, range: 0...360, step: 10,
                           unit: "°")
                BigStepper(title: "Verfügbare Länge", systemImage: "ruler",
                           value: $conditions.runwayLengthM, range: 200...5000, step: 50,
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
        }
    }
}
