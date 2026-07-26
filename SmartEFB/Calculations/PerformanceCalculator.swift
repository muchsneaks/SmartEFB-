import Foundation

/// The computed result of a take-off or landing performance calculation.
struct PerformanceResult: Hashable, Sendable {
    /// Ground roll from the chart, corrected for wind, slope and surface.
    var groundRollM: Double

    /// Distance over a 50 ft obstacle, corrected for wind, slope and surface.
    var distanceOver50ftM: Double

    /// ``distanceOver50ftM`` plus the pilot's safety factor — the figure to
    /// compare against the runway.
    var requiredDistanceM: Double

    var safetyFactorPercent: Double

    var pressureAltitudeFt: Double
    var densityAltitudeFt: Double
    var headwindKt: Double
    var crosswindKt: Double
    var crosswindFromLeft: Bool

    /// Runway length available minus ``requiredDistanceM``, in metres.
    var marginM: Double

    /// Notes the pilot must be aware of, e.g. clamped chart inputs.
    var warnings: [String]

    var fitsOnRunway: Bool { marginM >= 0 }
}

/// Computes take-off and landing distances from an aircraft's POH chart.
///
/// The chart itself provides the base distance for the current pressure
/// altitude, temperature and weight (see ``PerformanceInterpolator``); the POH's
/// correction notes then account for wind, runway slope and surface. Finally the
/// pilot's own safety factor is applied.
enum PerformanceCalculator {
    /// Computes take-off performance, or `nil` if the aircraft has no take-off chart.
    static func takeoff(aircraft: Aircraft, conditions: ConditionsSnapshot) -> PerformanceResult? {
        guard let table = aircraft.takeoffTable, !table.isEmpty else { return nil }
        return compute(table: table, conditions: conditions, isLanding: false)
    }

    /// Computes landing performance, or `nil` if the aircraft has no landing chart.
    static func landing(aircraft: Aircraft, conditions: ConditionsSnapshot) -> PerformanceResult? {
        guard let table = aircraft.landingTable, !table.isEmpty else { return nil }
        return compute(table: table, conditions: conditions, isLanding: true)
    }

    // MARK: - Core

    private static func compute(
        table: PerformanceTable,
        conditions: ConditionsSnapshot,
        isLanding: Bool
    ) -> PerformanceResult? {
        let pressureAltitude = AtmosphereCalculator.pressureAltitude(
            elevationFt: conditions.fieldElevationFt,
            qnhHpa: conditions.qnhHpa
        )
        let densityAltitude = AtmosphereCalculator.densityAltitude(
            pressureAltitudeFt: pressureAltitude,
            temperatureC: conditions.temperatureC
        )
        let wind = AtmosphereCalculator.windComponents(
            windFromDeg: conditions.windDirectionDeg,
            windSpeedKt: conditions.windSpeedKt,
            runwayHeadingDeg: conditions.runwayHeadingDeg
        )

        guard let base = PerformanceInterpolator.interpolate(
            points: table.points,
            pressureAltitudeFt: pressureAltitude,
            temperatureC: conditions.temperatureC,
            weightKg: conditions.weightKg
        ) else {
            return nil
        }

        var warnings = base.clampedQuantities.map {
            "\($0) liegt außerhalb der Tabelle – es wurde der Randwert verwendet (nicht extrapoliert)."
        }

        let factor = correctionFactor(
            corrections: table.corrections,
            conditions: conditions,
            headwindKt: wind.headwind,
            isLanding: isLanding
        )

        if wind.headwind < 0 {
            warnings.append("Rückenwindkomponente – Strecke deutlich verlängert. Startrichtung prüfen.")
        }

        let groundRoll = base.groundRollM * factor
        let over50 = base.distanceOver50ftM * factor
        let required = over50 * (1 + conditions.safetyFactorPercent / 100)

        return PerformanceResult(
            groundRollM: groundRoll,
            distanceOver50ftM: over50,
            requiredDistanceM: required,
            safetyFactorPercent: conditions.safetyFactorPercent,
            pressureAltitudeFt: pressureAltitude,
            densityAltitudeFt: densityAltitude,
            headwindKt: wind.headwind,
            crosswindKt: wind.crosswind,
            crosswindFromLeft: wind.crosswindFromLeft,
            marginM: conditions.runwayLengthM - required,
            warnings: warnings
        )
    }

    /// The combined wind / slope / surface multiplier applied to the chart value.
    static func correctionFactor(
        corrections: PerformanceCorrections,
        conditions: ConditionsSnapshot,
        headwindKt: Double,
        isLanding: Bool
    ) -> Double {
        // Wind: headwind shortens, tailwind lengthens. Floored so an extreme
        // headwind can never collapse the distance to an unrealistic value.
        let windFactor: Double
        if headwindKt >= 0 {
            windFactor = max(0.5, 1 + corrections.headwindPerKt * headwindKt)
        } else {
            windFactor = 1 + corrections.tailwindPerKt * (-headwindKt)
        }

        // Slope: uphill penalises take-off, downhill penalises landing.
        let slopeSign: Double = isLanding ? -1 : 1
        let slopeFactor = max(0.7, 1 + slopeSign * corrections.slopePerPercent * conditions.runwaySlopePercent)

        var surfaceFactor = 1.0
        if conditions.surface == .grass { surfaceFactor *= corrections.grassFactor }
        if conditions.runwayCondition == .wet { surfaceFactor *= corrections.wetFactor }

        return windFactor * slopeFactor * surfaceFactor
    }
}
