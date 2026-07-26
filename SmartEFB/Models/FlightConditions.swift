import Foundation
import Observation

/// Shared, observable environmental, runway and loading conditions used across
/// the performance and cruise screens.
///
/// A single instance is owned by the app and injected into the environment so
/// that entering the conditions once is reflected everywhere.
@MainActor
@Observable
final class FlightConditions {
    // MARK: Atmosphere

    /// Airfield elevation in feet above mean sea level.
    var fieldElevationFt: Double = 1000

    /// Altimeter setting (QNH) in hectopascals.
    var qnhHpa: Double = 1013

    /// Outside air temperature at the field, in degrees Celsius.
    var temperatureC: Double = 15

    // MARK: Wind

    /// Direction the wind is coming *from*, in degrees.
    var windDirectionDeg: Double = 270

    /// Wind speed in knots.
    var windSpeedKt: Double = 8

    // MARK: Runway

    /// Runway heading in degrees (direction of travel).
    var runwayHeadingDeg: Double = 250

    /// Usable runway length in metres, used to show the safety margin.
    var runwayLengthM: Double = 800

    /// Runway slope in percent. Positive = uphill in the direction of travel.
    var runwaySlopePercent: Double = 0

    var surface: RunwaySurface = .paved
    var runwayCondition: RunwayCondition = .dry

    // MARK: Loading & safety

    /// Planned take-off / landing mass in kilograms.
    var weightKg: Double = 900

    /// Additional safety margin applied to the required distance, in percent.
    /// Many operators and clubs require a fixed factor (e.g. 15 % or 43 %).
    var safetyFactorPercent: Double = 0

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
            weightKg: weightKg,
            safetyFactorPercent: safetyFactorPercent
        )
    }

    /// Aligns the planning weight with the selected aircraft, resetting it to
    /// that aircraft's default when it falls outside its usable range.
    func syncWeight(to aircraft: Aircraft?) {
        guard let aircraft else { return }
        if weightKg > aircraft.maxTakeoffWeightKg || weightKg < aircraft.emptyWeightKg {
            weightKg = aircraft.defaultPlanningWeightKg
        }
    }
}
