import Testing
@testable import SmartEFB

@MainActor
struct CruiseAdvisorTests {
    private func aircraft(propType: PropType = .fixedPitch) -> Aircraft {
        Aircraft(
            name: "Test", registration: "D-TEST", icaoType: "TEST",
            propType: propType,
            emptyWeightKg: 500, maxTakeoffWeightKg: 800, defaultPlanningWeightKg: 700,
            cruiseSettings: [
                CruiseSetting(pressureAltitudeFt: 2000, rpm: 2300, manifoldPressureInHg: nil,
                              percentPower: 70, trueAirspeedKt: 110, fuelFlowLph: 33),
                CruiseSetting(pressureAltitudeFt: 6000, rpm: 2500, manifoldPressureInHg: nil,
                              percentPower: 65, trueAirspeedKt: 116, fuelFlowLph: 30),
                CruiseSetting(pressureAltitudeFt: 10000, rpm: 2600, manifoldPressureInHg: nil,
                              percentPower: 57, trueAirspeedKt: 119, fuelFlowLph: 26)
            ]
        )
    }

    private func conditions(elevationFt: Double = 0, temperatureC: Double = 15) -> FlightConditions {
        let conditions = FlightConditions()
        conditions.fieldElevationFt = elevationFt
        conditions.qnhHpa = AtmosphereCalculator.standardPressureHpa
        conditions.temperatureC = temperatureC
        return conditions
    }

    @Test func returnsNothingWithoutCruiseData() {
        var subject = aircraft()
        subject.cruiseSettings = []
        let settings = CruiseAdvisor.adjustedSettings(for: subject, conditions: conditions().snapshot)
        #expect(settings.isEmpty)
    }

    @Test func recommendsTheRowNearestTheCurrentPressureAltitude() {
        let settings = CruiseAdvisor.adjustedSettings(
            for: aircraft(), conditions: conditions(elevationFt: 6000).snapshot
        )
        #expect(settings.first { $0.isRecommended }?.base.pressureAltitudeFt == 6000)
    }

    @Test func exactlyOneRowIsRecommended() {
        let settings = CruiseAdvisor.adjustedSettings(
            for: aircraft(), conditions: conditions(elevationFt: 7500).snapshot
        )
        #expect(settings.filter(\.isRecommended).count == 1)
    }

    @Test func higherTemperatureIncreasesTrueAirspeed() {
        let cold = CruiseAdvisor.adjustedSettings(
            for: aircraft(), conditions: conditions(temperatureC: -10).snapshot
        ).first?.adjustedTasKt ?? 0
        let warm = CruiseAdvisor.adjustedSettings(
            for: aircraft(), conditions: conditions(temperatureC: 30).snapshot
        ).first?.adjustedTasKt ?? 0

        #expect(warm > cold)
    }
}
