import Foundation

/// A ready-made example aircraft so the app can be tried out before the pilot has
/// entered their own handbook data.
///
/// The figures are **synthetic demonstration values** for a generic light
/// single-engine aeroplane — deliberately not attributed to any real type, so they
/// can never be mistaken for certified performance data. The grid is generated from
/// the documented sensitivities below, which keeps it self-consistent and strictly
/// increasing with altitude, temperature and mass.
enum DemoAircraft {
    /// Stable identity, so loading the demo twice cannot create a duplicate.
    static let id = UUID(uuidString: "0E110000-0000-4000-8000-000000000001") ?? UUID()

    static let name = "Demo – Musterflugzeug"

    // MARK: Reference values at sea level, 15 °C, MTOM, zero wind, level dry paved

    private static let maxTakeoffWeightKg: Double = 800
    private static let takeoffRollM: Double = 260
    private static let takeoffOver50M: Double = 430
    private static let landingRollM: Double = 180
    private static let landingOver50M: Double = 400

    // MARK: Documented sensitivities used to generate the grid

    /// Distance growth per 1000 ft of pressure altitude (compounding).
    private static let altitudeGrowthPer1000ft: Double = 0.10

    /// Distance growth per °C above 15 °C.
    private static let temperatureGrowthPerDegree: Double = 0.01

    /// Take-off distance scales with mass to this power; landing is less sensitive.
    private static let takeoffWeightExponent: Double = 2.0
    private static let landingWeightExponent: Double = 1.5

    // MARK: Sampled grid

    private static let altitudes: [Double] = [0, 2000, 4000, 6000, 8000]
    private static let temperatures: [Double] = [-20, 0, 15, 30, 40]
    private static let weights: [Double] = [650, 800]

    /// Builds the example aircraft.
    static func make() -> Aircraft {
        Aircraft(
            id: id,
            name: name,
            registration: "D-DEMO",
            icaoType: "DEMO",
            propType: .fixedPitch,
            emptyWeightKg: 530,
            maxTakeoffWeightKg: maxTakeoffWeightKg,
            defaultPlanningWeightKg: 700,
            takeoffTable: PerformanceTable(
                points: grid(
                    rollAtReference: takeoffRollM,
                    over50AtReference: takeoffOver50M,
                    weightExponent: takeoffWeightExponent
                ),
                corrections: .takeoffDefaults,
                configurationNote: "Beispielwerte: Startklappen, Vollgas, ebene trockene Hartbahn."
            ),
            landingTable: PerformanceTable(
                points: grid(
                    rollAtReference: landingRollM,
                    over50AtReference: landingOver50M,
                    weightExponent: landingWeightExponent
                ),
                corrections: .landingDefaults,
                configurationNote: "Beispielwerte: Landeklappen, Leerlauf, ebene trockene Hartbahn."
            ),
            cruiseSettings: cruiseSettings,
            vSpeeds: VSpeeds(
                rotateKt: 50,
                bestRateOfClimbKt: 70,
                bestAngleOfClimbKt: 60,
                approachKt: 62,
                stallLandingKt: 40,
                neverExceedKt: 160
            )
        )
    }

    /// Generates the full grid from the reference values and sensitivities.
    private static func grid(
        rollAtReference: Double,
        over50AtReference: Double,
        weightExponent: Double
    ) -> [PerformanceDataPoint] {
        var points: [PerformanceDataPoint] = []

        for weight in weights {
            let weightFactor = pow(weight / maxTakeoffWeightKg, weightExponent)

            for altitude in altitudes {
                let altitudeFactor = pow(1 + altitudeGrowthPer1000ft, altitude / 1000)

                for temperature in temperatures {
                    let temperatureFactor = 1 + temperatureGrowthPerDegree * (temperature - 15)
                    let factor = altitudeFactor * temperatureFactor * weightFactor

                    points.append(PerformanceDataPoint(
                        pressureAltitudeFt: altitude,
                        temperatureC: temperature,
                        weightKg: weight,
                        groundRollM: (rollAtReference * factor).rounded(),
                        distanceOver50ftM: (over50AtReference * factor).rounded()
                    ))
                }
            }
        }

        return points
    }

    private static let cruiseSettings: [CruiseSetting] = [
        CruiseSetting(pressureAltitudeFt: 2000, rpm: 2200, manifoldPressureInHg: nil,
                      percentPower: 75, trueAirspeedKt: 108, fuelFlowLph: 24),
        CruiseSetting(pressureAltitudeFt: 4000, rpm: 2300, manifoldPressureInHg: nil,
                      percentPower: 71, trueAirspeedKt: 112, fuelFlowLph: 22),
        CruiseSetting(pressureAltitudeFt: 6000, rpm: 2400, manifoldPressureInHg: nil,
                      percentPower: 66, trueAirspeedKt: 115, fuelFlowLph: 20),
        CruiseSetting(pressureAltitudeFt: 8000, rpm: 2450, manifoldPressureInHg: nil,
                      percentPower: 61, trueAirspeedKt: 117, fuelFlowLph: 19),
        CruiseSetting(pressureAltitudeFt: 10000, rpm: 2500, manifoldPressureInHg: nil,
                      percentPower: 57, trueAirspeedKt: 118, fuelFlowLph: 17)
    ]
}
