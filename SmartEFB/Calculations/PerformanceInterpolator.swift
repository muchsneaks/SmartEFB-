import Foundation

/// Interpolates a take-off or landing distance out of a sampled POH chart.
///
/// The sampled points form a grid over pressure altitude, temperature and
/// weight. A value is produced by bilinear interpolation over pressure altitude
/// and temperature at each bracketing weight, followed by linear interpolation
/// between those two weights.
///
/// Inputs outside the sampled range are **clamped**, never extrapolated, and the
/// affected quantity is reported so the pilot can be warned — extrapolating a
/// performance chart is not safe.
enum PerformanceInterpolator {
    /// The interpolated distances plus the names of any clamped input quantities.
    struct Output: Hashable, Sendable {
        var groundRollM: Double
        var distanceOver50ftM: Double
        var clampedQuantities: [String]
    }

    /// Interpolates the chart at the given conditions.
    ///
    /// - Returns: `nil` if the chart contains no points.
    static func interpolate(
        points: [PerformanceDataPoint],
        pressureAltitudeFt: Double,
        temperatureC: Double,
        weightKg: Double
    ) -> Output? {
        guard !points.isEmpty else { return nil }

        var clamped: Set<String> = []

        let weights = Set(points.map(\.weightKg)).sorted()
        // `weights` is non-empty because `points` is non-empty.
        let lowestWeight = weights[0]
        let highestWeight = weights[weights.count - 1]

        let targetWeight = weightKg.clamped(to: lowestWeight...highestWeight)
        if targetWeight != weightKg { clamped.insert("Masse") }

        let (w0, w1, weightFraction) = bracket(values: weights, target: targetWeight)

        guard let lower = interpolateAtWeight(
            points: points, weight: w0,
            pressureAltitudeFt: pressureAltitudeFt,
            temperatureC: temperatureC,
            clamped: &clamped
        ) else {
            return nil
        }

        guard w1 != w0, let upper = interpolateAtWeight(
            points: points, weight: w1,
            pressureAltitudeFt: pressureAltitudeFt,
            temperatureC: temperatureC,
            clamped: &clamped
        ) else {
            return Output(
                groundRollM: lower.groundRoll,
                distanceOver50ftM: lower.over50,
                clampedQuantities: clamped.sorted()
            )
        }

        return Output(
            groundRollM: lerp(lower.groundRoll, upper.groundRoll, weightFraction),
            distanceOver50ftM: lerp(lower.over50, upper.over50, weightFraction),
            clampedQuantities: clamped.sorted()
        )
    }

    // MARK: - Bilinear interpolation at one weight

    private static func interpolateAtWeight(
        points: [PerformanceDataPoint],
        weight: Double,
        pressureAltitudeFt: Double,
        temperatureC: Double,
        clamped: inout Set<String>
    ) -> (groundRoll: Double, over50: Double)? {
        let group = points.filter { $0.weightKg == weight }
        guard !group.isEmpty else { return nil }

        let altitudes = Set(group.map(\.pressureAltitudeFt)).sorted()
        let temperatures = Set(group.map(\.temperatureC)).sorted()

        let targetAltitude = pressureAltitudeFt.clamped(to: altitudes[0]...altitudes[altitudes.count - 1])
        if targetAltitude != pressureAltitudeFt { clamped.insert("Druckhöhe") }

        let targetTemperature = temperatureC.clamped(to: temperatures[0]...temperatures[temperatures.count - 1])
        if targetTemperature != temperatureC { clamped.insert("Temperatur") }

        let (a0, a1, altitudeFraction) = bracket(values: altitudes, target: targetAltitude)
        let (t0, t1, temperatureFraction) = bracket(values: temperatures, target: targetTemperature)

        // Each corner falls back to the nearest sampled point so an incomplete
        // grid still produces a usable — and conservative — answer.
        guard let c00 = corner(in: group, altitude: a0, temperature: t0),
              let c10 = corner(in: group, altitude: a1, temperature: t0),
              let c01 = corner(in: group, altitude: a0, temperature: t1),
              let c11 = corner(in: group, altitude: a1, temperature: t1) else {
            return nil
        }

        let rollAtT0 = lerp(c00.groundRollM, c10.groundRollM, altitudeFraction)
        let rollAtT1 = lerp(c01.groundRollM, c11.groundRollM, altitudeFraction)
        let over50AtT0 = lerp(c00.distanceOver50ftM, c10.distanceOver50ftM, altitudeFraction)
        let over50AtT1 = lerp(c01.distanceOver50ftM, c11.distanceOver50ftM, altitudeFraction)

        return (
            groundRoll: lerp(rollAtT0, rollAtT1, temperatureFraction),
            over50: lerp(over50AtT0, over50AtT1, temperatureFraction)
        )
    }

    /// The sampled point at an exact grid corner, or the nearest one available.
    private static func corner(
        in group: [PerformanceDataPoint],
        altitude: Double,
        temperature: Double
    ) -> PerformanceDataPoint? {
        if let exact = group.first(where: {
            $0.pressureAltitudeFt == altitude && $0.temperatureC == temperature
        }) {
            return exact
        }

        // Normalised distance: 1000 ft of altitude is weighted like 10 °C.
        func squaredDistance(_ point: PerformanceDataPoint) -> Double {
            let altitudeTerm = (point.pressureAltitudeFt - altitude) / 1000
            let temperatureTerm = (point.temperatureC - temperature) / 10
            return altitudeTerm * altitudeTerm + temperatureTerm * temperatureTerm
        }

        return group.min { squaredDistance($0) < squaredDistance($1) }
    }

    // MARK: - Helpers

    /// Finds the two sampled values bracketing `target` and the fraction between
    /// them. Returns the edge value twice (fraction 0) when out of range.
    static func bracket(values: [Double], target: Double) -> (lower: Double, upper: Double, fraction: Double) {
        guard let first = values.first, let last = values.last else {
            return (target, target, 0)
        }
        if target <= first { return (first, first, 0) }
        if target >= last { return (last, last, 0) }

        for index in 1..<values.count where target <= values[index] {
            let lower = values[index - 1]
            let upper = values[index]
            let span = upper - lower
            return (lower, upper, span == 0 ? 0 : (target - lower) / span)
        }

        return (last, last, 0)
    }

    static func lerp(_ a: Double, _ b: Double, _ fraction: Double) -> Double {
        a + (b - a) * fraction
    }
}
