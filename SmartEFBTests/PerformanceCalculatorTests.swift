import Testing
@testable import SmartEFB

@MainActor
struct PerformanceCalculatorTests {
    /// A test aircraft whose take-off chart is flat at 300 m / 500 m, so any
    /// change in the result is caused purely by the correction factors.
    private func aircraft(
        takeoffCorrections: PerformanceCorrections = .takeoffDefaults,
        landingCorrections: PerformanceCorrections = .landingDefaults
    ) -> Aircraft {
        let points = [
            PerformanceDataPoint(pressureAltitudeFt: 0, temperatureC: 15, weightKg: 800,
                                 groundRollM: 300, distanceOver50ftM: 500),
            PerformanceDataPoint(pressureAltitudeFt: 4000, temperatureC: 15, weightKg: 800,
                                 groundRollM: 420, distanceOver50ftM: 700)
        ]
        return Aircraft(
            name: "Test", registration: "D-TEST", icaoType: "TEST",
            propType: .fixedPitch,
            emptyWeightKg: 500, maxTakeoffWeightKg: 800, defaultPlanningWeightKg: 800,
            takeoffTable: PerformanceTable(points: points, corrections: takeoffCorrections, configurationNote: nil),
            landingTable: PerformanceTable(points: points, corrections: landingCorrections, configurationNote: nil)
        )
    }

    /// Reference conditions: sea level, ISA, no wind, level dry paved runway.
    private func referenceConditions() -> FlightConditions {
        let conditions = FlightConditions()
        conditions.fieldElevationFt = 0
        conditions.qnhHpa = AtmosphereCalculator.standardPressureHpa
        conditions.temperatureC = 15
        conditions.windSpeedKt = 0
        conditions.runwaySlopePercent = 0
        conditions.surface = .paved
        conditions.runwayCondition = .dry
        conditions.runwayLengthM = 5000
        conditions.weightKg = 800
        conditions.safetyFactorPercent = 0
        return conditions
    }

    @Test func returnsNilWithoutATable() {
        var subject = aircraft()
        subject.takeoffTable = nil
        #expect(PerformanceCalculator.takeoff(aircraft: subject, conditions: referenceConditions().snapshot) == nil)
    }

    @Test func matchesTheChartAtReferenceConditions() throws {
        let result = try #require(PerformanceCalculator.takeoff(
            aircraft: aircraft(), conditions: referenceConditions().snapshot
        ))
        #expect(abs(result.groundRollM - 300) < 0.01)
        #expect(abs(result.distanceOver50ftM - 500) < 0.01)
        #expect(result.warnings.isEmpty)
    }

    @Test func higherFieldElevationLengthensTheDistance() throws {
        let conditions = referenceConditions()
        conditions.fieldElevationFt = 4000

        let base = try #require(PerformanceCalculator.takeoff(aircraft: aircraft(), conditions: referenceConditions().snapshot))
        let high = try #require(PerformanceCalculator.takeoff(aircraft: aircraft(), conditions: conditions.snapshot))
        #expect(high.distanceOver50ftM > base.distanceOver50ftM)
    }

    @Test func headwindShortensAndTailwindLengthens() throws {
        let headwind = referenceConditions()
        headwind.runwayHeadingDeg = 250
        headwind.windDirectionDeg = 250
        headwind.windSpeedKt = 15

        let tailwind = referenceConditions()
        tailwind.runwayHeadingDeg = 250
        tailwind.windDirectionDeg = 70
        tailwind.windSpeedKt = 10

        let calm = try #require(PerformanceCalculator.takeoff(aircraft: aircraft(), conditions: referenceConditions().snapshot))
        let withHeadwind = try #require(PerformanceCalculator.takeoff(aircraft: aircraft(), conditions: headwind.snapshot))
        let withTailwind = try #require(PerformanceCalculator.takeoff(aircraft: aircraft(), conditions: tailwind.snapshot))

        #expect(withHeadwind.distanceOver50ftM < calm.distanceOver50ftM)
        #expect(withTailwind.distanceOver50ftM > calm.distanceOver50ftM)
        #expect(withTailwind.warnings.contains { $0.contains("Rückenwind") })
    }

    @Test func grassAndWetLengthenTheLanding() throws {
        let grass = referenceConditions()
        grass.surface = .grass

        let wet = referenceConditions()
        wet.runwayCondition = .wet

        let dry = try #require(PerformanceCalculator.landing(aircraft: aircraft(), conditions: referenceConditions().snapshot))
        let onGrass = try #require(PerformanceCalculator.landing(aircraft: aircraft(), conditions: grass.snapshot))
        let whenWet = try #require(PerformanceCalculator.landing(aircraft: aircraft(), conditions: wet.snapshot))

        #expect(onGrass.distanceOver50ftM > dry.distanceOver50ftM)
        #expect(whenWet.distanceOver50ftM > dry.distanceOver50ftM)
    }

    @Test func uphillPenalisesTakeoffAndDownhillPenalisesLanding() throws {
        let uphill = referenceConditions()
        uphill.runwaySlopePercent = 2

        let downhill = referenceConditions()
        downhill.runwaySlopePercent = -2

        let levelTakeoff = try #require(PerformanceCalculator.takeoff(aircraft: aircraft(), conditions: referenceConditions().snapshot))
        let uphillTakeoff = try #require(PerformanceCalculator.takeoff(aircraft: aircraft(), conditions: uphill.snapshot))
        #expect(uphillTakeoff.distanceOver50ftM > levelTakeoff.distanceOver50ftM)

        let levelLanding = try #require(PerformanceCalculator.landing(aircraft: aircraft(), conditions: referenceConditions().snapshot))
        let downhillLanding = try #require(PerformanceCalculator.landing(aircraft: aircraft(), conditions: downhill.snapshot))
        #expect(downhillLanding.distanceOver50ftM > levelLanding.distanceOver50ftM)
    }

    @Test func safetyFactorOnlyAffectsTheRequiredDistance() throws {
        let conditions = referenceConditions()
        conditions.safetyFactorPercent = 43

        let result = try #require(PerformanceCalculator.takeoff(aircraft: aircraft(), conditions: conditions.snapshot))
        #expect(abs(result.distanceOver50ftM - 500) < 0.01)
        #expect(abs(result.requiredDistanceM - 715) < 0.01)
        #expect(abs(result.marginM - (5000 - 715)) < 0.01)
    }

    @Test func shortRunwayIsReportedAsNotFitting() throws {
        let conditions = referenceConditions()
        conditions.runwayLengthM = 300

        let result = try #require(PerformanceCalculator.takeoff(aircraft: aircraft(), conditions: conditions.snapshot))
        #expect(result.fitsOnRunway == false)
        #expect(result.marginM < 0)
    }

    @Test func warnsWhenTheChartHadToBeClamped() throws {
        let conditions = referenceConditions()
        conditions.fieldElevationFt = 12000

        let result = try #require(PerformanceCalculator.takeoff(aircraft: aircraft(), conditions: conditions.snapshot))
        #expect(result.warnings.contains { $0.contains("Druckhöhe") })
    }
}
