import Foundation
import Observation

/// Shared, observable environmental and runway conditions used across the
/// performance and cruise screens.
///
/// A single instance is owned by the app and injected into the environment so
/// that entering conditions once (e.g. on the ground before departure) is
/// reflected everywhere.
@MainActor
@Observable
final class FlightConditions {
    // MARK: Atmosphere

    /// Airfield elevation in feet above mean sea level.
    var fieldElevationFt: Double = 1200

    /// Altimeter setting (QNH) in hectopascals.
    var qnhHpa: Double = 1013

    /// Outside air temperature at the field, in degrees Celsius.
    var temperatureC: Double = 15

    // MARK: Wind

    /// Direction the wind is coming *from*, in degrees true.
    var windDirectionDeg: Double = 270

    /// Wind speed in knots.
    var windSpeedKt: Double = 8

    // MARK: Runway

    /// Runway magnetic heading in degrees (direction of travel).
    var runwayHeadingDeg: Double = 250

    /// Usable runway length in metres, used to show the safety margin.
    var runwayLengthM: Double = 800

    /// Runway slope in percent. Positive = uphill in the direction of travel.
    var runwaySlopePercent: Double = 0

    var surface: RunwaySurface = .paved
    var runwayCondition: RunwayCondition = .dry

    // MARK: Aircraft loading

    /// Planned take-off / landing weight in kilograms.
    var weightKg: Double = 1000

    /// An immutable, `Sendable` copy for use by the pure calculators.
    var snapshot: ConditionsSnapshot {
        ConditionsSnapshot(
            fieldElevationFt: fieldElevationFt,
            qnhHpa: qnhHpa,
            temperatureC: temperatureC,
            windDirectionDeg: windDirectionDeg,
            windSpeedKt: windSpeedKt,
            runwayHeadingDeg: runwayHeadingDeg,
            runwayLengthM: runwayLengthM,
            runwaySlopePercent: runwaySlopePercent,
            surface: surface,
            runwayCondition: runwayCondition,
            weightKg: weightKg
        )
    }

    /// Aligns the mutable weight with the currently selected aircraft, clamping
    /// it to the aircraft's maximum take-off weight.
    func syncWeight(to aircraft: Aircraft) {
        if weightKg > aircraft.maxTakeoffWeightKg || weightKg < aircraft.emptyWeightKg {
            weightKg = aircraft.defaultPlanningWeightKg
        }
    }
}
