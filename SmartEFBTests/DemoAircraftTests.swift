import Testing
@testable import SmartEFB

@MainActor
struct DemoAircraftTests {
    @Test func hasCompleteDataForEveryScreen() throws {
        let demo = DemoAircraft.make()
        let takeoff = try #require(demo.takeoffTable)
        let landing = try #require(demo.landingTable)

        #expect(demo.hasRunwayData)
        #expect(takeoff.points.count == 50)
        #expect(landing.points.count == 50)
        #expect(demo.cruiseSettings.isEmpty == false)
        #expect(demo.vSpeeds != nil)
        #expect(demo.emptyWeightKg < demo.maxTakeoffWeightKg)
    }

    /// The generated grid must satisfy the same physics the validator enforces on
    /// imported data: distance grows with altitude, temperature and mass.
    @Test func gridIsStrictlyIncreasingOnEveryAxis() throws {
        let points = try #require(DemoAircraft.make().takeoffTable?.points)

        func assertIncreasing<Key: Hashable>(
            groupBy key: (PerformanceDataPoint) -> Key,
            sortBy value: (PerformanceDataPoint) -> Double
        ) {
            for group in Dictionary(grouping: points, by: key).values where group.count > 1 {
                let sorted = group.sorted { value($0) < value($1) }
                for index in 1..<sorted.count {
                    #expect(sorted[index].distanceOver50ftM > sorted[index - 1].distanceOver50ftM)
                    #expect(sorted[index].groundRollM > sorted[index - 1].groundRollM)
                }
            }
        }

        assertIncreasing(groupBy: { "\($0.weightKg)|\($0.temperatureC)" }, sortBy: \.pressureAltitudeFt)
        assertIncreasing(groupBy: { "\($0.weightKg)|\($0.pressureAltitudeFt)" }, sortBy: \.temperatureC)
        assertIncreasing(groupBy: { "\($0.pressureAltitudeFt)|\($0.temperatureC)" }, sortBy: \.weightKg)
    }

    @Test func obstacleDistanceAlwaysExceedsGroundRoll() throws {
        let demo = DemoAircraft.make()
        for table in [demo.takeoffTable, demo.landingTable].compactMap(\.self) {
            for point in table.points {
                #expect(point.distanceOver50ftM > point.groundRollM)
            }
        }
    }

    @Test func producesUsableTakeoffAndLandingResults() throws {
        let demo = DemoAircraft.make()
        let conditions = FlightConditions()
        conditions.fieldElevationFt = 1000
        conditions.qnhHpa = AtmosphereCalculator.standardPressureHpa
        conditions.temperatureC = 20
        conditions.weightKg = 700
        conditions.runwayLengthM = 900

        let takeoff = try #require(PerformanceCalculator.takeoff(aircraft: demo, conditions: conditions.snapshot))
        let landing = try #require(PerformanceCalculator.landing(aircraft: demo, conditions: conditions.snapshot))

        // Nothing was clamped: the conditions sit inside the sampled grid.
        #expect(takeoff.warnings.isEmpty)
        #expect(takeoff.distanceOver50ftM > takeoff.groundRollM)
        #expect(landing.distanceOver50ftM > landing.groundRollM)
        #expect(takeoff.fitsOnRunway)
    }

    @Test func cruiseAdviceWorks() {
        let conditions = FlightConditions()
        conditions.fieldElevationFt = 6000
        conditions.qnhHpa = AtmosphereCalculator.standardPressureHpa

        let settings = CruiseAdvisor.adjustedSettings(
            for: DemoAircraft.make(), conditions: conditions.snapshot
        )
        #expect(settings.filter(\.isRecommended).count == 1)
    }

    @Test func loadingTheDemoTwiceDoesNotDuplicateIt() {
        let store = AircraftStore(aircraft: [], persistsChanges: false)
        store.loadDemoAircraft()
        store.loadDemoAircraft()

        #expect(store.aircraft.count == 1)
        #expect(store.hasDemoAircraft)
        #expect(store.selected?.id == DemoAircraft.id)
    }
}
