import Foundation

/// An immutable, `Sendable` value copy of the current ``FlightConditions``.
///
/// The performance and cruise calculators consume this snapshot rather than the
/// main-actor-isolated ``FlightConditions`` object, so the calculation logic
/// stays pure, `Sendable` and free of actor isolation.
struct ConditionsSnapshot: Sendable, Hashable {
    var fieldElevationFt: Double
    var qnhHpa: Double
    var temperatureC: Double

    var windDirectionDeg: Double
    var windSpeedKt: Double

    var runwayHeadingDeg: Double
    var runwayLengthM: Double
    var runwaySlopePercent: Double
    var surface: RunwaySurface
    var runwayCondition: RunwayCondition

    var weightKg: Double
    var safetyFactorPercent: Double
}
