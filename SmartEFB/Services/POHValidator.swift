import Foundation

/// The outcome of cross-checking the extracted grid against the worked example
/// printed in the POH.
///
/// This is the strongest validation available: if the app's own interpolation
/// reproduces the handbook's printed result, the transcription is trustworthy.
struct VerificationOutcome: Hashable, Sendable {
    var isTakeoff: Bool
    var conditionsSummary: String
    var expectedGroundRollM: Double
    var expectedDistanceOver50ftM: Double
    var computedGroundRollM: Double
    var computedDistanceOver50ftM: Double

    /// The larger of the two relative deviations, in percent.
    var maxDeviationPercent: Double

    /// Whether the deviation is small enough to consider the grid confirmed.
    var passed: Bool { maxDeviationPercent <= 12 }
}

/// The cleaned, range-checked result of importing a POH page.
struct POHImportResult: Sendable {
    var suggestedName: String?
    var maxTakeoffWeightKg: Double?
    var emptyWeightKg: Double?

    var takeoffTable: PerformanceTable?
    var landingTable: PerformanceTable?

    var cruiseSettings: [CruiseSetting]
    var vSpeeds: VSpeeds?

    var verification: VerificationOutcome?
    var confidence: Double?
    var warnings: [String]

    var isEmpty: Bool {
        takeoffTable == nil && landingTable == nil && cruiseSettings.isEmpty
    }
}

/// Turns a raw ``POHExtraction`` into a validated ``POHImportResult``.
///
/// Values outside plausible ranges are dropped, physically inconsistent points
/// are reported, and the extracted grid is cross-checked against the handbook's
/// worked example — because wrong performance data is a safety risk, not a
/// cosmetic defect.
enum POHValidator {
    // Plausible ranges for a light single-engine aeroplane.
    private static let altitudeRange = -2000.0...30000.0
    private static let temperatureRange = -60.0...60.0
    private static let weightRange = 200.0...10000.0
    private static let distanceRange = 20.0...5000.0
    private static let rpmRange = 500.0...4000.0
    private static let manifoldRange = 10.0...35.0
    private static let powerRange = 20.0...120.0
    private static let tasRange = 20.0...500.0
    private static let fuelRange = 1.0...500.0
    private static let speedRange = 20.0...400.0

    static func validate(_ extraction: POHExtraction) -> POHImportResult {
        var warnings = extraction.warnings ?? []

        let takeoffPoints = points(from: extraction.takeoffPoints, label: "Start", warnings: &warnings)
        let landingPoints = points(from: extraction.landingPoints, label: "Landung", warnings: &warnings)

        checkMonotonicity(takeoffPoints, label: "Start", warnings: &warnings)
        checkMonotonicity(landingPoints, label: "Landung", warnings: &warnings)

        let takeoffTable = takeoffPoints.isEmpty ? nil : PerformanceTable(
            points: takeoffPoints,
            corrections: corrections(from: extraction.takeoffCorrections, defaults: .takeoffDefaults),
            configurationNote: extraction.takeoffConfiguration
        )

        let landingTable = landingPoints.isEmpty ? nil : PerformanceTable(
            points: landingPoints,
            corrections: corrections(from: extraction.landingCorrections, defaults: .landingDefaults),
            configurationNote: extraction.landingConfiguration
        )

        let cruise = cruiseSettings(from: extraction.cruiseSettings, warnings: &warnings)
        let speeds = vSpeeds(from: extraction.vSpeeds)

        let verification = verify(
            extraction.verification,
            takeoffTable: takeoffTable,
            landingTable: landingTable,
            warnings: &warnings
        )

        if takeoffTable == nil && landingTable == nil && cruise.isEmpty {
            warnings.append("Es konnten keine belastbaren Leistungsdaten erkannt werden. Bitte ein schärferes, gerade ausgerichtetes Foto verwenden.")
        }

        return POHImportResult(
            suggestedName: extraction.aircraftName?.trimmed.nilIfEmpty,
            maxTakeoffWeightKg: extraction.maxTakeoffWeightKg.flatMap { weightRange.contains($0) ? $0 : nil },
            emptyWeightKg: extraction.emptyWeightKg.flatMap { weightRange.contains($0) ? $0 : nil },
            takeoffTable: takeoffTable,
            landingTable: landingTable,
            cruiseSettings: cruise,
            vSpeeds: speeds,
            verification: verification,
            confidence: extraction.confidence,
            warnings: warnings
        )
    }

    // MARK: - Grid points

    private static func points(
        from dtos: [POHExtraction.PointDTO]?,
        label: String,
        warnings: inout [String]
    ) -> [PerformanceDataPoint] {
        guard let dtos else { return [] }

        var result: [PerformanceDataPoint] = []
        var dropped = 0
        var swapped = 0

        for dto in dtos {
            guard let altitude = dto.pressureAltitudeFt, altitudeRange.contains(altitude),
                  let temperature = dto.temperatureC, temperatureRange.contains(temperature),
                  let weight = dto.weightKg, weightRange.contains(weight),
                  var roll = dto.groundRollM, distanceRange.contains(roll),
                  var over50 = dto.distanceOver50ftM, distanceRange.contains(over50) else {
                dropped += 1
                continue
            }

            // The obstacle distance must exceed the ground roll; a swap is a
            // common transcription error and is safe to repair.
            if over50 < roll {
                swap(&roll, &over50)
                swapped += 1
            }

            result.append(PerformanceDataPoint(
                pressureAltitudeFt: altitude,
                temperatureC: temperature,
                weightKg: weight,
                groundRollM: roll,
                distanceOver50ftM: over50
            ))
        }

        if dropped > 0 {
            warnings.append("\(label): \(dropped) Stützpunkt(e) mit unplausiblen Werten verworfen.")
        }
        if swapped > 0 {
            warnings.append("\(label): Bei \(swapped) Stützpunkt(en) waren Roll- und 50-ft-Strecke vertauscht – korrigiert.")
        }

        return deduplicate(result)
    }

    /// Removes duplicate grid cells, keeping the more conservative (longer) one.
    private static func deduplicate(_ points: [PerformanceDataPoint]) -> [PerformanceDataPoint] {
        var best: [String: PerformanceDataPoint] = [:]
        for point in points {
            let key = "\(point.pressureAltitudeFt)|\(point.temperatureC)|\(point.weightKg)"
            if let existing = best[key], existing.distanceOver50ftM >= point.distanceOver50ftM {
                continue
            }
            best[key] = point
        }
        return best.values.sorted {
            ($0.weightKg, $0.pressureAltitudeFt, $0.temperatureC)
                < ($1.weightKg, $1.pressureAltitudeFt, $1.temperatureC)
        }
    }

    /// Flags points that break the physics of a performance chart: distance must
    /// grow with pressure altitude, with temperature and with weight.
    private static func checkMonotonicity(
        _ points: [PerformanceDataPoint],
        label: String,
        warnings: inout [String]
    ) {
        guard points.count > 1 else { return }
        var violations = 0

        func scan<Key: Hashable>(
            groupBy key: (PerformanceDataPoint) -> Key,
            sortBy value: (PerformanceDataPoint) -> Double
        ) {
            let groups = Dictionary(grouping: points, by: key)
            for group in groups.values where group.count > 1 {
                let sorted = group.sorted { value($0) < value($1) }
                for index in 1..<sorted.count
                where sorted[index].distanceOver50ftM < sorted[index - 1].distanceOver50ftM {
                    violations += 1
                }
            }
        }

        scan(groupBy: { "\($0.weightKg)|\($0.temperatureC)" }, sortBy: \.pressureAltitudeFt)
        scan(groupBy: { "\($0.weightKg)|\($0.pressureAltitudeFt)" }, sortBy: \.temperatureC)
        scan(groupBy: { "\($0.pressureAltitudeFt)|\($0.temperatureC)" }, sortBy: \.weightKg)

        if violations > 0 {
            warnings.append("\(label): \(violations) Stützpunkt(e) widersprechen dem erwarteten Verlauf (Strecke muss mit Höhe, Temperatur und Masse zunehmen). Bitte diese Werte besonders prüfen.")
        }
    }

    // MARK: - Corrections

    /// Converts the model's correction notes into fractional factors.
    ///
    /// The model is asked for percent-per-knot, but may answer with a fraction.
    /// A magnitude above 0.5 can only be a percentage, which disambiguates the
    /// two without silently accepting a 100× error.
    private static func corrections(
        from dto: POHExtraction.CorrectionsDTO?,
        defaults: PerformanceCorrections
    ) -> PerformanceCorrections {
        guard let dto else { return defaults }
        var result = defaults

        if let raw = dto.headwindPercentPerKt {
            let fraction = asFraction(raw)
            // Headwind must shorten the distance.
            let signed = -abs(fraction)
            if (-0.05...0).contains(signed) { result.headwindPerKt = signed }
        }

        if let raw = dto.tailwindPercentPerKt {
            let fraction = abs(asFraction(raw))
            if (0...0.20).contains(fraction) { result.tailwindPerKt = fraction }
        }

        if let raw = dto.slopePercentPerPercent {
            let fraction = abs(asFraction(raw))
            if (0...0.30).contains(fraction) { result.slopePerPercent = fraction }
        }

        if let grass = dto.grassFactor, (1.0...2.0).contains(grass) {
            result.grassFactor = grass
        }
        if let wet = dto.wetFactor, (1.0...2.0).contains(wet) {
            result.wetFactor = wet
        }

        return result
    }

    private static func asFraction(_ raw: Double) -> Double {
        abs(raw) > 0.5 ? raw / 100 : raw
    }

    // MARK: - Cruise & speeds

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

            result.append(CruiseSetting(
                pressureAltitudeFt: altitude,
                rpm: dto.rpm.flatMap { rpmRange.contains($0) ? Int($0.rounded()) : nil } ?? 0,
                manifoldPressureInHg: dto.manifoldPressureInHg.flatMap { manifoldRange.contains($0) ? $0 : nil },
                percentPower: dto.percentPower.flatMap { powerRange.contains($0) ? Int($0.rounded()) : nil } ?? 0,
                trueAirspeedKt: dto.trueAirspeedKt.flatMap { tasRange.contains($0) ? $0 : nil } ?? 0,
                fuelFlowLph: dto.fuelFlowLph.flatMap { fuelRange.contains($0) ? $0 : nil } ?? 0
            ))
        }

        if dropped > 0 {
            warnings.append("\(dropped) Cruise-Zeile(n) mit unplausiblen Werten verworfen.")
        }

        return result.sorted { $0.pressureAltitudeFt < $1.pressureAltitudeFt }
    }

    private static func vSpeeds(from dto: POHExtraction.VSpeedsDTO?) -> VSpeeds? {
        guard let dto else { return nil }

        func clean(_ value: Double?) -> Double? {
            value.flatMap { speedRange.contains($0) ? $0 : nil }
        }

        guard let reference = clean(dto.rotateKt) ?? clean(dto.bestRateOfClimbKt) ?? clean(dto.approachKt) else {
            return nil
        }

        return VSpeeds(
            rotateKt: clean(dto.rotateKt) ?? reference,
            bestRateOfClimbKt: clean(dto.bestRateOfClimbKt) ?? reference,
            bestAngleOfClimbKt: clean(dto.bestAngleOfClimbKt) ?? reference,
            approachKt: clean(dto.approachKt) ?? reference,
            stallLandingKt: clean(dto.stallLandingKt) ?? 0,
            neverExceedKt: clean(dto.neverExceedKt) ?? 0
        )
    }

    // MARK: - Cross-check against the POH's worked example

    private static func verify(
        _ dto: POHExtraction.VerificationDTO?,
        takeoffTable: PerformanceTable?,
        landingTable: PerformanceTable?,
        warnings: inout [String]
    ) -> VerificationOutcome? {
        guard let dto,
              let altitude = dto.pressureAltitudeFt,
              let temperature = dto.temperatureC,
              let weight = dto.weightKg,
              let expectedRoll = dto.expectedGroundRollM, distanceRange.contains(expectedRoll),
              let expectedOver50 = dto.expectedDistanceOver50ftM, distanceRange.contains(expectedOver50) else {
            return nil
        }

        let isTakeoff = dto.isTakeoff ?? true
        guard let table = isTakeoff ? takeoffTable : landingTable else { return nil }

        guard let interpolated = PerformanceInterpolator.interpolate(
            points: table.points,
            pressureAltitudeFt: altitude,
            temperatureC: temperature,
            weightKg: weight
        ) else {
            return nil
        }

        // The example usually includes a headwind; apply the same correction the
        // app would use so the comparison is like-for-like.
        let headwind = dto.headwindKt ?? 0
        let snapshot = ConditionsSnapshot(
            fieldElevationFt: altitude, qnhHpa: AtmosphereCalculator.standardPressureHpa,
            temperatureC: temperature, windDirectionDeg: 0, windSpeedKt: abs(headwind),
            runwayHeadingDeg: 0, runwayLengthM: 0, runwaySlopePercent: 0,
            surface: .paved, runwayCondition: .dry, weightKg: weight, safetyFactorPercent: 0
        )
        let factor = PerformanceCalculator.correctionFactor(
            corrections: table.corrections,
            conditions: snapshot,
            headwindKt: headwind,
            isLanding: !isTakeoff
        )

        let computedRoll = interpolated.groundRollM * factor
        let computedOver50 = interpolated.distanceOver50ftM * factor

        let rollDeviation = deviationPercent(computed: computedRoll, expected: expectedRoll)
        let over50Deviation = deviationPercent(computed: computedOver50, expected: expectedOver50)
        let maxDeviation = max(rollDeviation, over50Deviation)

        let outcome = VerificationOutcome(
            isTakeoff: isTakeoff,
            conditionsSummary: "\(Int(altitude)) ft · \(Int(temperature)) °C · \(Int(weight)) kg · \(Int(headwind)) kt",
            expectedGroundRollM: expectedRoll,
            expectedDistanceOver50ftM: expectedOver50,
            computedGroundRollM: computedRoll,
            computedDistanceOver50ftM: computedOver50,
            maxDeviationPercent: maxDeviation
        )

        if !outcome.passed {
            warnings.append("Die Gegenrechnung zum POH-Beispiel weicht um \(Int(maxDeviation.rounded())) % ab. Die erkannten Werte sind vermutlich fehlerhaft – bitte genau prüfen.")
        }

        return outcome
    }

    private static func deviationPercent(computed: Double, expected: Double) -> Double {
        guard expected != 0 else { return 0 }
        return abs(computed - expected) / expected * 100
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
