import Foundation

/// The computed result of a take-off or landing performance calculation.
struct PerformanceResult: Hashable {
    var groundRollM: Double
    var distanceOver50ftM: Double

    var pressureAltitudeFt: Double
    var densityAltitudeFt: Double
    var headwindKt: Double
    var crosswindKt: Double
    var crosswindFromLeft: Bool

    /// Runway length available minus the required 50 ft distance (metres).
    /// Positive means the runway is long enough.
    var marginM: Double

    /// Whether the required distance fits on the available runway.
    var fitsOnRunway: Bool { marginM >= 0 }
}

/// Applies standard planning correction factors to an aircraft's reference
/// take-off / landing distances.
///
/// The model corrects for density altitude, weight, wind, runway slope and
/// surface. These are the same influences taught in GA performance planning;
/// the coefficients are conservative approximations and are **not** a
/// replacement for the aircraft's certified performance charts.
enum PerformanceCalculator {
    /// Distance increase per 1000 ft of density altitude (compounding).
    static let densityGrowthPer1000ft: Double = 0.10

    /// Take-off distance reduction per knot of headwind.
    static let takeoffHeadwindFactor: Double = 0.013

    /// Landing distance reduction per knot of headwind.
    static let landingHeadwindFactor: Double = 0.011

    /// Distance increase per knot of tailwind (heavily penalised, per POH).
    static let tailwindFactor: Double = 0.05

    /// Take-off distance change per percent of runway slope (uphill = worse).
    static let takeoffSlopeFactor: Double = 0.07

    /// Landing distance change per percent of runway slope (downhill = worse).
    static let landingSlopeFactor: Double = 0.05

    /// Computes a take-off performance result.
    static func takeoff(aircraft: Aircraft, conditions: ConditionsSnapshot) -> PerformanceResult {
        compute(reference: aircraft.takeoff, aircraft: aircraft, conditions: conditions, isLanding: false)
    }

    /// Computes a landing performance result.
    static func landing(aircraft: Aircraft, conditions: ConditionsSnapshot) -> PerformanceResult {
        compute(reference: aircraft.landing, aircraft: aircraft, conditions: conditions, isLanding: true)
    }

    // MARK: - Core

    private static func compute(
        reference: RunwayPerformance,
        aircraft: Aircraft,
        conditions: ConditionsSnapshot,
        isLanding: Bool
    ) -> PerformanceResult {
        let pa = AtmosphereCalculator.pressureAltitude(
            elevationFt: conditions.fieldElevationFt,
            qnhHpa: conditions.qnhHpa
        )
        let da = AtmosphereCalculator.densityAltitude(
            pressureAltitudeFt: pa,
            temperatureC: conditions.temperatureC
        )
        let wind = AtmosphereCalculator.windComponents(
            windFromDeg: conditions.windDirectionDeg,
            windSpeedKt: conditions.windSpeedKt,
            runwayHeadingDeg: conditions.runwayHeadingDeg
        )

        let factor = totalFactor(
            aircraft: aircraft,
            conditions: conditions,
            densityAltitudeFt: da,
            headwind: wind.headwind,
            isLanding: isLanding
        )

        let groundRoll = reference.groundRollM * factor
        let over50 = reference.distanceOver50ftM * factor

        return PerformanceResult(
            groundRollM: groundRoll,
            distanceOver50ftM: over50,
            pressureAltitudeFt: pa,
            densityAltitudeFt: da,
            headwindKt: wind.headwind,
            crosswindKt: wind.crosswind,
            crosswindFromLeft: wind.crosswindFromLeft,
            marginM: conditions.runwayLengthM - over50
        )
    }

    /// The combined multiplier applied to the reference distance.
    private static func totalFactor(
        aircraft: Aircraft,
        conditions: ConditionsSnapshot,
        densityAltitudeFt: Double,
        headwind: Double,
        isLanding: Bool
    ) -> Double {
        // Density altitude — compounding growth per 1000 ft.
        let densityFactor = pow(1 + densityGrowthPer1000ft, densityAltitudeFt / 1000)

        // Weight — take-off distance is more weight-sensitive than landing.
        let weightRatio = conditions.weightKg / aircraft.maxTakeoffWeightKg
        let weightExponent = isLanding ? 1.6 : 2.0
        let weightFactor = pow(weightRatio, weightExponent)

        // Wind.
        let windFactor: Double
        if headwind >= 0 {
            let k = isLanding ? landingHeadwindFactor : takeoffHeadwindFactor
            windFactor = max(0.4, 1 - k * headwind)
        } else {
            windFactor = 1 + tailwindFactor * (-headwind)
        }

        // Slope.
        let slopeFactor: Double
        if isLanding {
            slopeFactor = 1 - landingSlopeFactor * conditions.runwaySlopePercent
        } else {
            slopeFactor = 1 + takeoffSlopeFactor * conditions.runwaySlopePercent
        }

        // Surface & wetness.
        var surfaceFactor = conditions.surface == .grass ? aircraft.surfaceFactors.grassFactor : 1.0
        if isLanding && conditions.runwayCondition == .wet {
            surfaceFactor *= aircraft.surfaceFactors.wetLandingFactor
        }

        return densityFactor * weightFactor * windFactor * max(0.4, slopeFactor) * surfaceFactor
    }
}
