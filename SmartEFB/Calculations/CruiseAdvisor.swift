import Foundation

/// A cruise power setting adjusted for the current conditions, ready for display.
struct AdjustedCruiseSetting: Hashable, Identifiable {
    var id: UUID
    var base: CruiseSetting

    /// True airspeed corrected for the current temperature deviation.
    var adjustedTasKt: Double

    /// Whether this row best matches the current pressure altitude.
    var isRecommended: Bool
}

/// Selects and adjusts cruise power settings for the current conditions.
enum CruiseAdvisor {
    /// Returns all of an aircraft's cruise settings, TAS-corrected for the
    /// current conditions, with the row closest to the current pressure
    /// altitude flagged as recommended.
    static func adjustedSettings(
        for aircraft: Aircraft,
        conditions: FlightConditions
    ) -> [AdjustedCruiseSetting] {
        let pa = AtmosphereCalculator.pressureAltitude(
            elevationFt: conditions.fieldElevationFt,
            qnhHpa: conditions.qnhHpa
        )
        let settings = aircraft.sortedCruiseSettings
        guard let recommended = recommendedSetting(in: settings, pressureAltitudeFt: pa) else {
            return []
        }

        return settings.map { setting in
            let tas = AtmosphereCalculator.adjustedTrueAirspeed(
                publishedTasKt: setting.trueAirspeedKt,
                pressureAltitudeFt: setting.pressureAltitudeFt,
                temperatureC: conditions.temperatureC
            )
            return AdjustedCruiseSetting(
                id: setting.id,
                base: setting,
                adjustedTasKt: tas,
                isRecommended: setting.id == recommended.id
            )
        }
    }

    /// The cruise setting whose pressure altitude is nearest the current one.
    static func recommendedSetting(
        in settings: [CruiseSetting],
        pressureAltitudeFt: Double
    ) -> CruiseSetting? {
        settings.min { lhs, rhs in
            abs(lhs.pressureAltitudeFt - pressureAltitudeFt) < abs(rhs.pressureAltitudeFt - pressureAltitudeFt)
        }
    }
}
