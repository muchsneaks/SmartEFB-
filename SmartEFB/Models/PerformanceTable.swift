import Foundation

/// A complete take-off or landing performance chart: the sampled grid points
/// plus the POH's correction notes.
struct PerformanceTable: Codable, Hashable, Sendable {
    var points: [PerformanceDataPoint]
    var corrections: PerformanceCorrections

    /// Free-text configuration the chart assumes (flap setting, power, technique).
    var configurationNote: String?

    var isEmpty: Bool { points.isEmpty }

    /// The distinct weights the chart was sampled at, ascending.
    var weights: [Double] {
        Set(points.map(\.weightKg)).sorted()
    }

    /// The distinct pressure altitudes the chart was sampled at, ascending.
    var pressureAltitudes: [Double] {
        Set(points.map(\.pressureAltitudeFt)).sorted()
    }

    /// The distinct temperatures the chart was sampled at, ascending.
    var temperatures: [Double] {
        Set(points.map(\.temperatureC)).sorted()
    }
}
