import Foundation

/// One sampled cell of an aircraft's take-off or landing performance chart.
///
/// A POH presents this data either as a printed table or as a nomogram (carpet
/// chart). Both are reduced to a set of these points, sampled at grid
/// intersections, which the app then interpolates between. All values are at the
/// chart's reference configuration: level, dry, paved runway and zero wind —
/// wind, slope and surface are applied afterwards via ``PerformanceCorrections``.
struct PerformanceDataPoint: Codable, Hashable, Identifiable, Sendable {
    var id: UUID = UUID()

    /// Pressure altitude in feet.
    var pressureAltitudeFt: Double

    /// Outside air temperature in degrees Celsius.
    var temperatureC: Double

    /// Aircraft mass in kilograms.
    var weightKg: Double

    /// Ground roll in metres.
    var groundRollM: Double

    /// Total distance to clear a 50 ft (15 m) obstacle, in metres.
    var distanceOver50ftM: Double
}
