import Testing
@testable import SmartEFB

struct AtmosphereCalculatorTests {
    @Test func pressureAltitudeEqualsElevationAtStandardQNH() {
        let pa = AtmosphereCalculator.pressureAltitude(elevationFt: 1200, qnhHpa: 1013.25)
        #expect(abs(pa - 1200) < 0.01)
    }

    @Test func lowerQNHRaisesPressureAltitude() {
        let high = AtmosphereCalculator.pressureAltitude(elevationFt: 0, qnhHpa: 993.25)
        // 20 hPa below standard -> ~540 ft higher.
        #expect(abs(high - 540) < 1)
    }

    @Test func isaTemperatureDropsWithAltitude() {
        #expect(abs(AtmosphereCalculator.isaTemperature(pressureAltitudeFt: 0) - 15) < 0.01)
        #expect(AtmosphereCalculator.isaTemperature(pressureAltitudeFt: 5000) < 15)
    }

    @Test func hotTemperatureRaisesDensityAltitude() {
        let isaDA = AtmosphereCalculator.densityAltitude(pressureAltitudeFt: 0, temperatureC: 15)
        let hotDA = AtmosphereCalculator.densityAltitude(pressureAltitudeFt: 0, temperatureC: 30)
        #expect(abs(isaDA) < 0.01)
        #expect(hotDA > isaDA)
    }

    @Test func directHeadwindHasNoCrosswind() {
        let wind = AtmosphereCalculator.windComponents(windFromDeg: 250, windSpeedKt: 10, runwayHeadingDeg: 250)
        #expect(abs(wind.headwind - 10) < 0.01)
        #expect(wind.crosswind < 0.01)
    }

    @Test func directTailwindIsNegativeHeadwind() {
        let wind = AtmosphereCalculator.windComponents(windFromDeg: 70, windSpeedKt: 10, runwayHeadingDeg: 250)
        #expect(wind.headwind < 0)
    }

    @Test func pureCrosswindFromRight() {
        let wind = AtmosphereCalculator.windComponents(windFromDeg: 340, windSpeedKt: 10, runwayHeadingDeg: 250)
        #expect(abs(wind.headwind) < 0.01)
        #expect(abs(wind.crosswind - 10) < 0.01)
        #expect(wind.crosswindFromLeft == false)
    }
}
