import Foundation

/// Pure, stateless atmospheric calculations shared by the performance and
/// cruise logic.
///
/// All formulas use the standard rules of thumb taught in general-aviation
/// theory. They are accurate enough for planning but are approximations, not
/// the full ISA equations.
enum AtmosphereCalculator {
    /// Standard sea-level pressure in hectopascals.
    static let standardPressureHpa: Double = 1013.25

    /// Approximate change in pressure altitude per hectopascal, in feet.
    static let feetPerHpa: Double = 27

    /// ISA temperature lapse rate in °C per 1000 ft.
    static let lapseRatePer1000ft: Double = 1.98

    /// Density-altitude correction: feet added per °C above ISA.
    static let densityFeetPerDegree: Double = 118.8

    /// Converts field elevation and QNH into pressure altitude (feet).
    static func pressureAltitude(elevationFt: Double, qnhHpa: Double) -> Double {
        elevationFt + (standardPressureHpa - qnhHpa) * feetPerHpa
    }

    /// ISA standard temperature (°C) at a given pressure altitude.
    static func isaTemperature(pressureAltitudeFt: Double) -> Double {
        15 - lapseRatePer1000ft * (pressureAltitudeFt / 1000)
    }

    /// Density altitude (feet) from pressure altitude and outside air temperature.
    static func densityAltitude(pressureAltitudeFt: Double, temperatureC: Double) -> Double {
        let isaDeviation = temperatureC - isaTemperature(pressureAltitudeFt: pressureAltitudeFt)
        return pressureAltitudeFt + densityFeetPerDegree * isaDeviation
    }

    /// Wind components relative to a runway.
    struct WindComponents {
        /// Positive = headwind, negative = tailwind (knots).
        var headwind: Double
        /// Absolute crosswind component (knots).
        var crosswind: Double
        /// Side the crosswind comes from, for display.
        var crosswindFromLeft: Bool
    }

    /// Resolves wind into headwind and crosswind components for a runway.
    ///
    /// - Parameters:
    ///   - windFromDeg: direction the wind blows *from*, degrees.
    ///   - windSpeedKt: wind speed in knots.
    ///   - runwayHeadingDeg: runway direction of travel, degrees.
    static func windComponents(
        windFromDeg: Double,
        windSpeedKt: Double,
        runwayHeadingDeg: Double
    ) -> WindComponents {
        let angle = (windFromDeg - runwayHeadingDeg) * .pi / 180
        let headwind = windSpeedKt * cos(angle)
        let signedCross = windSpeedKt * sin(angle)
        return WindComponents(
            headwind: headwind,
            crosswind: abs(signedCross),
            crosswindFromLeft: signedCross < 0
        )
    }

    /// Estimates true airspeed from a published (ISA) TAS by correcting for the
    /// current temperature deviation from ISA — roughly 1 % TAS per 5 °C.
    static func adjustedTrueAirspeed(
        publishedTasKt: Double,
        pressureAltitudeFt: Double,
        temperatureC: Double
    ) -> Double {
        let deviation = temperatureC - isaTemperature(pressureAltitudeFt: pressureAltitudeFt)
        return publishedTasKt * (1 + 0.002 * deviation)
    }
}
