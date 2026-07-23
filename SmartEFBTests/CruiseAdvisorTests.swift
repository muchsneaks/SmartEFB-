import Testing
@testable import SmartEFB

@MainActor
struct CruiseAdvisorTests {
    @Test func recommendsSettingNearestToPressureAltitude() {
        let aircraft = AircraftLibrary.cessna172
        let conditions = FlightConditions()
        conditions.fieldElevationFt = 6000
        conditions.qnhHpa = 1013.25

        let settings = CruiseAdvisor.adjustedSettings(for: aircraft, conditions: conditions)
        let recommended = settings.first { $0.isRecommended }
        #expect(recommended?.base.pressureAltitudeFt == 6000)
    }

    @Test func exactlyOneSettingIsRecommended() {
        let aircraft = AircraftLibrary.cirrusSR22
        let conditions = FlightConditions()
        conditions.fieldElevationFt = 7500
        conditions.qnhHpa = 1013.25

        let settings = CruiseAdvisor.adjustedSettings(for: aircraft, conditions: conditions)
        #expect(settings.filter(\.isRecommended).count == 1)
    }

    @Test func higherTemperatureIncreasesTrueAirspeed() {
        let aircraft = AircraftLibrary.diamondDA40
        let cold = FlightConditions()
        cold.temperatureC = -10
        let warm = FlightConditions()
        warm.temperatureC = 30

        let coldTas = CruiseAdvisor.adjustedSettings(for: aircraft, conditions: cold).first?.adjustedTasKt ?? 0
        let warmTas = CruiseAdvisor.adjustedSettings(for: aircraft, conditions: warm).first?.adjustedTasKt ?? 0
        #expect(warmTas > coldTas)
    }
}
