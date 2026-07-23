import Foundation

/// The bundled catalogue of sample aircraft.
///
/// - Important: All figures are realistic planning values intended for
///   demonstration and training. Always verify against the official POH /
///   AFM before real-world use.
enum AircraftLibrary {
    static let all: [Aircraft] = [cessna172, piperArcher, diamondDA40, cirrusSR22]

    // MARK: - Cessna 172S Skyhawk (fixed pitch)

    static let cessna172 = Aircraft(
        name: "Cessna 172S Skyhawk",
        registration: "D-EABC",
        icaoType: "C172",
        symbolName: "airplane",
        propType: .fixedPitch,
        emptyWeightKg: 767,
        maxTakeoffWeightKg: 1157,
        defaultPlanningWeightKg: 1050,
        takeoff: RunwayPerformance(groundRollM: 290, distanceOver50ftM: 500),
        landing: RunwayPerformance(groundRollM: 175, distanceOver50ftM: 415),
        surfaceFactors: .standard,
        cruiseSettings: [
            CruiseSetting(pressureAltitudeFt: 2000, rpm: 2300, manifoldPressureInHg: nil, percentPower: 70, trueAirspeedKt: 110, fuelFlowLph: 33),
            CruiseSetting(pressureAltitudeFt: 4000, rpm: 2400, manifoldPressureInHg: nil, percentPower: 68, trueAirspeedKt: 114, fuelFlowLph: 32),
            CruiseSetting(pressureAltitudeFt: 6000, rpm: 2500, manifoldPressureInHg: nil, percentPower: 65, trueAirspeedKt: 116, fuelFlowLph: 30),
            CruiseSetting(pressureAltitudeFt: 8000, rpm: 2550, manifoldPressureInHg: nil, percentPower: 61, trueAirspeedKt: 118, fuelFlowLph: 28),
            CruiseSetting(pressureAltitudeFt: 10000, rpm: 2600, manifoldPressureInHg: nil, percentPower: 57, trueAirspeedKt: 119, fuelFlowLph: 26)
        ],
        vSpeeds: VSpeeds(rotateKt: 55, bestRateOfClimbKt: 74, bestAngleOfClimbKt: 62, approachKt: 65, stallLandingKt: 40, neverExceedKt: 163)
    )

    // MARK: - Piper PA-28-181 Archer III (fixed pitch)

    static let piperArcher = Aircraft(
        name: "Piper PA-28-181 Archer III",
        registration: "D-EPAA",
        icaoType: "P28A",
        symbolName: "airplane",
        propType: .fixedPitch,
        emptyWeightKg: 771,
        maxTakeoffWeightKg: 1157,
        defaultPlanningWeightKg: 1050,
        takeoff: RunwayPerformance(groundRollM: 300, distanceOver50ftM: 490),
        landing: RunwayPerformance(groundRollM: 180, distanceOver50ftM: 420),
        surfaceFactors: .standard,
        cruiseSettings: [
            CruiseSetting(pressureAltitudeFt: 2000, rpm: 2400, manifoldPressureInHg: nil, percentPower: 72, trueAirspeedKt: 118, fuelFlowLph: 38),
            CruiseSetting(pressureAltitudeFt: 4000, rpm: 2450, manifoldPressureInHg: nil, percentPower: 69, trueAirspeedKt: 121, fuelFlowLph: 36),
            CruiseSetting(pressureAltitudeFt: 6000, rpm: 2500, manifoldPressureInHg: nil, percentPower: 65, trueAirspeedKt: 123, fuelFlowLph: 34),
            CruiseSetting(pressureAltitudeFt: 8000, rpm: 2550, manifoldPressureInHg: nil, percentPower: 61, trueAirspeedKt: 124, fuelFlowLph: 31),
            CruiseSetting(pressureAltitudeFt: 10000, rpm: 2600, manifoldPressureInHg: nil, percentPower: 57, trueAirspeedKt: 125, fuelFlowLph: 29)
        ],
        vSpeeds: VSpeeds(rotateKt: 57, bestRateOfClimbKt: 76, bestAngleOfClimbKt: 64, approachKt: 66, stallLandingKt: 45, neverExceedKt: 154)
    )

    // MARK: - Diamond DA40 NG (constant speed)

    static let diamondDA40 = Aircraft(
        name: "Diamond DA40 NG",
        registration: "D-EDGN",
        icaoType: "DA40",
        symbolName: "airplane",
        propType: .constantSpeed,
        emptyWeightKg: 940,
        maxTakeoffWeightKg: 1310,
        defaultPlanningWeightKg: 1180,
        takeoff: RunwayPerformance(groundRollM: 350, distanceOver50ftM: 560),
        landing: RunwayPerformance(groundRollM: 250, distanceOver50ftM: 470),
        surfaceFactors: SurfaceFactors(grassFactor: 1.18, wetLandingFactor: 1.15),
        cruiseSettings: [
            CruiseSetting(pressureAltitudeFt: 4000, rpm: 2200, manifoldPressureInHg: 30, percentPower: 75, trueAirspeedKt: 138, fuelFlowLph: 24),
            CruiseSetting(pressureAltitudeFt: 6000, rpm: 2100, manifoldPressureInHg: 28, percentPower: 70, trueAirspeedKt: 140, fuelFlowLph: 22),
            CruiseSetting(pressureAltitudeFt: 8000, rpm: 2000, manifoldPressureInHg: 26, percentPower: 65, trueAirspeedKt: 142, fuelFlowLph: 20),
            CruiseSetting(pressureAltitudeFt: 10000, rpm: 1900, manifoldPressureInHg: 24, percentPower: 60, trueAirspeedKt: 143, fuelFlowLph: 18),
            CruiseSetting(pressureAltitudeFt: 12000, rpm: 1900, manifoldPressureInHg: 22, percentPower: 55, trueAirspeedKt: 144, fuelFlowLph: 17)
        ],
        vSpeeds: VSpeeds(rotateKt: 59, bestRateOfClimbKt: 72, bestAngleOfClimbKt: 66, approachKt: 72, stallLandingKt: 49, neverExceedKt: 178)
    )

    // MARK: - Cirrus SR22 G3 (constant speed)

    static let cirrusSR22 = Aircraft(
        name: "Cirrus SR22 G3",
        registration: "D-ESRB",
        icaoType: "SR22",
        symbolName: "airplane",
        propType: .constantSpeed,
        emptyWeightKg: 1020,
        maxTakeoffWeightKg: 1542,
        defaultPlanningWeightKg: 1400,
        takeoff: RunwayPerformance(groundRollM: 320, distanceOver50ftM: 520),
        landing: RunwayPerformance(groundRollM: 260, distanceOver50ftM: 500),
        surfaceFactors: SurfaceFactors(grassFactor: 1.25, wetLandingFactor: 1.20),
        cruiseSettings: [
            CruiseSetting(pressureAltitudeFt: 4000, rpm: 2500, manifoldPressureInHg: 28, percentPower: 75, trueAirspeedKt: 168, fuelFlowLph: 62),
            CruiseSetting(pressureAltitudeFt: 6000, rpm: 2500, manifoldPressureInHg: 27, percentPower: 72, trueAirspeedKt: 172, fuelFlowLph: 58),
            CruiseSetting(pressureAltitudeFt: 8000, rpm: 2500, manifoldPressureInHg: 25, percentPower: 68, trueAirspeedKt: 176, fuelFlowLph: 54),
            CruiseSetting(pressureAltitudeFt: 10000, rpm: 2500, manifoldPressureInHg: 24, percentPower: 65, trueAirspeedKt: 179, fuelFlowLph: 50),
            CruiseSetting(pressureAltitudeFt: 12000, rpm: 2500, manifoldPressureInHg: 22, percentPower: 60, trueAirspeedKt: 181, fuelFlowLph: 46)
        ],
        vSpeeds: VSpeeds(rotateKt: 70, bestRateOfClimbKt: 101, bestAngleOfClimbKt: 78, approachKt: 79, stallLandingKt: 60, neverExceedKt: 205)
    )
}
