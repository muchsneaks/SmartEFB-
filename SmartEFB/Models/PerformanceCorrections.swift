import Foundation

/// The correction factors a POH lists as notes beneath its performance chart,
/// applied on top of the interpolated chart value.
///
/// Values are expressed as *fractional* changes so they compose multiplicatively:
/// a `headwindPerKt` of `-0.013` shortens the distance by 1.3 % per knot of
/// headwind.
struct PerformanceCorrections: Codable, Hashable, Sendable {
    /// Fractional distance change per knot of headwind (negative shortens).
    var headwindPerKt: Double

    /// Fractional distance change per knot of tailwind (positive lengthens).
    var tailwindPerKt: Double

    /// Multiplier applied on a dry grass surface.
    var grassFactor: Double

    /// Additional multiplier applied when the surface is wet.
    var wetFactor: Double

    /// Fractional change per percent of runway slope. Applied as a penalty for
    /// uphill on take-off and for downhill on landing.
    var slopePerPercent: Double

    /// Conservative defaults for take-off, used when the POH notes are absent.
    static let takeoffDefaults = PerformanceCorrections(
        headwindPerKt: -0.013,
        tailwindPerKt: 0.05,
        grassFactor: 1.15,
        wetFactor: 1.0,
        slopePerPercent: 0.07
    )

    /// Conservative defaults for landing, used when the POH notes are absent.
    static let landingDefaults = PerformanceCorrections(
        headwindPerKt: -0.011,
        tailwindPerKt: 0.05,
        grassFactor: 1.15,
        wetFactor: 1.15,
        slopePerPercent: 0.05
    )
}
