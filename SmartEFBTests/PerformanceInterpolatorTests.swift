import Testing
@testable import SmartEFB

struct PerformanceInterpolatorTests {
    /// A small 2 × 2 × 2 grid: 0/4000 ft, 0/40 °C, 600/800 kg.
    private var grid: [PerformanceDataPoint] {
        var points: [PerformanceDataPoint] = []
        for altitude in [0.0, 4000.0] {
            for temperature in [0.0, 40.0] {
                for weight in [600.0, 800.0] {
                    // Deliberately simple, strictly increasing synthetic model.
                    let roll = 200 + altitude / 100 + temperature * 2 + (weight - 600) / 2
                    points.append(PerformanceDataPoint(
                        pressureAltitudeFt: altitude,
                        temperatureC: temperature,
                        weightKg: weight,
                        groundRollM: roll,
                        distanceOver50ftM: roll * 1.6
                    ))
                }
            }
        }
        return points
    }

    @Test func returnsNilForEmptyGrid() {
        #expect(PerformanceInterpolator.interpolate(
            points: [], pressureAltitudeFt: 0, temperatureC: 15, weightKg: 700
        ) == nil)
    }

    @Test func reproducesAnExactGridPoint() throws {
        let output = try #require(PerformanceInterpolator.interpolate(
            points: grid, pressureAltitudeFt: 4000, temperatureC: 40, weightKg: 800
        ))
        // 200 + 40 + 80 + 100 = 420
        #expect(abs(output.groundRollM - 420) < 0.001)
        #expect(output.clampedQuantities.isEmpty)
    }

    @Test func interpolatesTheGridCentre() throws {
        let output = try #require(PerformanceInterpolator.interpolate(
            points: grid, pressureAltitudeFt: 2000, temperatureC: 20, weightKg: 700
        ))
        // 200 + 20 + 40 + 50 = 310
        #expect(abs(output.groundRollM - 310) < 0.001)
    }

    @Test func distanceRisesWithAltitudeTemperatureAndWeight() throws {
        let base = try #require(PerformanceInterpolator.interpolate(
            points: grid, pressureAltitudeFt: 0, temperatureC: 0, weightKg: 600
        ))
        let higher = try #require(PerformanceInterpolator.interpolate(
            points: grid, pressureAltitudeFt: 3000, temperatureC: 0, weightKg: 600
        ))
        let hotter = try #require(PerformanceInterpolator.interpolate(
            points: grid, pressureAltitudeFt: 0, temperatureC: 30, weightKg: 600
        ))
        let heavier = try #require(PerformanceInterpolator.interpolate(
            points: grid, pressureAltitudeFt: 0, temperatureC: 0, weightKg: 750
        ))

        #expect(higher.groundRollM > base.groundRollM)
        #expect(hotter.groundRollM > base.groundRollM)
        #expect(heavier.groundRollM > base.groundRollM)
    }

    @Test func clampsInsteadOfExtrapolatingAndReportsIt() throws {
        let output = try #require(PerformanceInterpolator.interpolate(
            points: grid, pressureAltitudeFt: 12000, temperatureC: 60, weightKg: 950
        ))
        let atEdge = try #require(PerformanceInterpolator.interpolate(
            points: grid, pressureAltitudeFt: 4000, temperatureC: 40, weightKg: 800
        ))

        // Never extrapolated beyond the chart's own corner value.
        #expect(abs(output.groundRollM - atEdge.groundRollM) < 0.001)
        #expect(output.clampedQuantities.contains("Druckhöhe"))
        #expect(output.clampedQuantities.contains("Temperatur"))
        #expect(output.clampedQuantities.contains("Masse"))
    }

    @Test func worksWithASingleWeightLevel() throws {
        let singleWeight = grid.filter { $0.weightKg == 600 }
        let output = try #require(PerformanceInterpolator.interpolate(
            points: singleWeight, pressureAltitudeFt: 2000, temperatureC: 20, weightKg: 700
        ))
        // 200 + 20 + 40 = 260, weight clamped to the only level available.
        #expect(abs(output.groundRollM - 260) < 0.001)
        #expect(output.clampedQuantities.contains("Masse"))
    }

    @Test func bracketReturnsEdgesWhenOutOfRange() {
        let values = [0.0, 10.0, 20.0]
        let below = PerformanceInterpolator.bracket(values: values, target: -5)
        #expect(below.lower == 0 && below.upper == 0 && below.fraction == 0)

        let above = PerformanceInterpolator.bracket(values: values, target: 99)
        #expect(above.lower == 20 && above.upper == 20 && above.fraction == 0)

        let middle = PerformanceInterpolator.bracket(values: values, target: 15)
        #expect(middle.lower == 10 && middle.upper == 20)
        #expect(abs(middle.fraction - 0.5) < 0.001)
    }
}
