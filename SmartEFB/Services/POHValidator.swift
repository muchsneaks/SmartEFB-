import Foundation

/// The cleaned, range-checked result of importing a POH table.
struct POHImportResult: Sendable {
    var suggestedName: String?
    var takeoff: RunwayPerformance?
    var landing: RunwayPerformance?
    var cruiseSettings: [CruiseSetting]
    var vSpeeds: VSpeeds?

    /// Model confidence (0–1) plus any human-readable warnings, shown to the
    /// pilot so questionable values can be reviewed before saving.
    var confidence: Double?
    var warnings: [String]

    var isEmpty: Bool {
        takeoff == nil && landing == nil && cruiseSettings.isEmpty && vSpeeds == nil
    }
}

/// Turns a raw ``POHExtraction`` into a validated ``POHImportResult``.
///
/// Values outside plausible ranges are dropped and reported as warnings rather
/// than silently trusted, because bad performance data is a safety risk.
enum POHValidator {
    private static let altitudeRange = -2000.0...30000.0
    private static let rpmRange = 500.0...4000.0
    private static let manifoldRange = 10.0...35.0
    private static let powerRange = 20.0...120.0
    private static let tasRange = 20.0...500.0
    private static let fuelRange = 1.0...500.0
    private static let distanceRange = 30.0...5000.0
    private static let speedRange = 20.0...400.0

    static func validate(_ extraction: POHExtraction) -> POHImportResult {
        var warnings = extraction.warnings ?? []

        let takeoff = runway(from: extraction.takeoff, label: "Start", warnings: &warnings)
        let landing = runway(from: extraction.landing, label: "Landung", warnings: &warnings)
        let cruise = cruiseSettings(from: extraction.cruiseSettings, warnings: &warnings)
        let speeds = vSpeeds(from: extraction.vSpeeds, warnings: &warnings)

        if takeoff == nil && landing == nil && cruise.isEmpty {
            warnings.append("Es konnten keine belastbaren Leistungsdaten erkannt werden. Bitte ein schärferes Foto verwenden.")
        }

        return POHImportResult(
            suggestedName: extraction.aircraftName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            takeoff: takeoff,
            landing: landing,
            cruiseSettings: cruise,
            vSpeeds: speeds,
            confidence: extraction.confidence,
            warnings: warnings
        )
    }

    // MARK: - Field validation

    private static func runway(
        from dto: POHExtraction.RunwayPerformanceDTO?,
        label: String,
        warnings: inout [String]
    ) -> RunwayPerformance? {
        guard let dto,
              let ground = dto.groundRollM,
              let over50 = dto.distanceOver50ftM,
              distanceRange.contains(ground),
              distanceRange.contains(over50) else {
            return nil
        }

        if over50 < ground {
            warnings.append("\(label): Strecke über 50 ft war kleiner als die Rollstrecke – Werte wurden getauscht.")
            return RunwayPerformance(groundRollM: over50, distanceOver50ftM: ground)
        }
        return RunwayPerformance(groundRollM: ground, distanceOver50ftM: over50)
    }

    private static func cruiseSettings(
        from dtos: [POHExtraction.CruiseSettingDTO]?,
        warnings: inout [String]
    ) -> [CruiseSetting] {
        guard let dtos else { return [] }

        var result: [CruiseSetting] = []
        var dropped = 0

        for dto in dtos {
            guard let altitude = dto.pressureAltitudeFt, altitudeRange.contains(altitude) else {
                dropped += 1
                continue
            }

            let rpm = dto.rpm.flatMap { rpmRange.contains($0) ? Int($0.rounded()) : nil } ?? 0
            let manifold = dto.manifoldPressureInHg.flatMap { manifoldRange.contains($0) ? $0 : nil }
            let power = dto.percentPower.flatMap { powerRange.contains($0) ? Int($0.rounded()) : nil } ?? 0
            let tas = dto.trueAirspeedKt.flatMap { tasRange.contains($0) ? $0 : nil } ?? 0
            let fuel = dto.fuelFlowLph.flatMap { fuelRange.contains($0) ? $0 : nil } ?? 0

            result.append(CruiseSetting(
                pressureAltitudeFt: altitude,
                rpm: rpm,
                manifoldPressureInHg: manifold,
                percentPower: power,
                trueAirspeedKt: tas,
                fuelFlowLph: fuel
            ))
        }

        if dropped > 0 {
            warnings.append("\(dropped) Cruise-Zeile(n) mit unplausiblen Werten wurden verworfen.")
        }

        return result.sorted { $0.pressureAltitudeFt < $1.pressureAltitudeFt }
    }

    private static func vSpeeds(
        from dto: POHExtraction.VSpeedsDTO?,
        warnings: inout [String]
    ) -> VSpeeds? {
        guard let dto else { return nil }

        func clean(_ value: Double?) -> Double? {
            value.flatMap { speedRange.contains($0) ? $0 : nil }
        }

        // Only build V-speeds if at least the core ones are present.
        guard let vr = clean(dto.rotateKt) ?? clean(dto.bestRateOfClimbKt) else { return nil }

        return VSpeeds(
            rotateKt: clean(dto.rotateKt) ?? vr,
            bestRateOfClimbKt: clean(dto.bestRateOfClimbKt) ?? vr,
            bestAngleOfClimbKt: clean(dto.bestAngleOfClimbKt) ?? vr,
            approachKt: clean(dto.approachKt) ?? vr,
            stallLandingKt: clean(dto.stallLandingKt) ?? 0,
            neverExceedKt: clean(dto.neverExceedKt) ?? 0
        )
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
