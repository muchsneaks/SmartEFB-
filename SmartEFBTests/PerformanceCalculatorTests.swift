import Testing
@testable import SmartEFB

@MainActor
struct PerformanceCalculatorTests {
    /// Reference conditions: MTOM, sea level, ISA, no wind, level dry paved runway.
    private func referenceConditions(for aircraft: Aircraft) -> FlightConditions {
        let c = FlightConditions()
        c.fieldElevationFt = 0
        c.qnhHpa = 1013.25
        c.temperatureC = 15
        c.windSpeedKt = 0
        c.runwaySlopePercent = 0
        c.surface = .paved
        c.runwayCondition = .dry
        c.runwayLengthM = 5000
        c.weightKg = aircraft.maxTakeoffWeightKg
        return c
    }

    @Test func takeoffAtReferenceMatchesPublishedFigures() {
        let aircraft = AircraftLibrary.cessna172
        let result = PerformanceCalculator.takeoff(aircraft: aircraft, conditions: referenceConditions(for: aircraft))
        #expect(abs(result.groundRollM - aircraft.takeoff.groundRollM) < 1)
        #expect(abs(result.distanceOver50ftM - aircraft.takeoff.distanceOver50ftM) < 1)
    }

    @Test func higherDensityAltitudeIncreasesTakeoffDistance() {
        let aircraft = AircraftLibrary.cessna172
        let base = referenceConditions(for: aircraft)
        let hot = referenceConditions(for: aircraft)
        hot.fieldElevationFt = 5000
        hot.temperatureC = 35

        let baseResult = PerformanceCalculator.takeoff(aircraft: aircraft, conditions: base)
        let hotResult = PerformanceCalculator.takeoff(aircraft: aircraft, conditions: hot)
        #expect(hotResult.groundRollM > baseResult.groundRollM)
    }

    @Test func headwindReducesTakeoffDistance() {
        let aircraft = AircraftLibrary.cessna172
        let conditions = referenceConditions(for: aircraft)
        conditions.runwayHeadingDeg = 250
        conditions.windDirectionDeg = 250
        conditions.windSpeedKt = 15

        let calm = PerformanceCalculator.takeoff(aircraft: aircraft, conditions: referenceConditions(for: aircraft))
        let headwind = PerformanceCalculator.takeoff(aircraft: aircraft, conditions: conditions)
        #expect(headwind.groundRollM < calm.groundRollM)
    }

    @Test func tailwindIncreasesTakeoffDistance() {
        let aircraft = AircraftLibrary.cessna172
        let conditions = referenceConditions(for: aircraft)
        conditions.runwayHeadingDeg = 250
        conditions.windDirectionDeg = 70 // blowing from behind
        conditions.windSpeedKt = 8

        let calm = PerformanceCalculator.takeoff(aircraft: aircraft, conditions: referenceConditions(for: aircraft))
        let tailwind = PerformanceCalculator.takeoff(aircraft: aircraft, conditions: conditions)
        #expect(tailwind.groundRollM > calm.groundRollM)
    }

    @Test func lowerWeightReducesTakeoffDistance() {
        let aircraft = AircraftLibrary.cessna172
        let conditions = referenceConditions(for: aircraft)
        conditions.weightKg = aircraft.emptyWeightKg + 100

        let mtom = PerformanceCalculator.takeoff(aircraft: aircraft, conditions: referenceConditions(for: aircraft))
        let light = PerformanceCalculator.takeoff(aircraft: aircraft, conditions: conditions)
        #expect(light.groundRollM < mtom.groundRollM)
    }

    @Test func grassIncreasesTakeoffDistance() {
        let aircraft = AircraftLibrary.cessna172
        let conditions = referenceConditions(for: aircraft)
        conditions.surface = .grass

        let paved = PerformanceCalculator.takeoff(aircraft: aircraft, conditions: referenceConditions(for: aircraft))
        let grass = PerformanceCalculator.takeoff(aircraft: aircraft, conditions: conditions)
        #expect(grass.groundRollM > paved.groundRollM)
    }

    @Test func wetRunwayIncreasesLandingDistance() {
        let aircraft = AircraftLibrary.cessna172
        let conditions = referenceConditions(for: aircraft)
        conditions.runwayCondition = .wet

        let dry = PerformanceCalculator.landing(aircraft: aircraft, conditions: referenceConditions(for: aircraft))
        let wet = PerformanceCalculator.landing(aircraft: aircraft, conditions: conditions)
        #expect(wet.groundRollM > dry.groundRollM)
    }

    @Test func shortRunwayReportsNegativeMargin() {
        let aircraft = AircraftLibrary.cessna172
        let conditions = referenceConditions(for: aircraft)
        conditions.runwayLengthM = 100

        let result = PerformanceCalculator.takeoff(aircraft: aircraft, conditions: conditions)
        #expect(result.fitsOnRunway == false)
        #expect(result.marginM < 0)
    }
}
