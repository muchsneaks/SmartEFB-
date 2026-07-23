import Foundation

/// Reference performance figures for a take-off or landing, valid at the
/// aircraft's certified reference conditions:
///
/// - Maximum take-off / landing weight
/// - Sea level pressure altitude
/// - ISA temperature (15 °C)
/// - No wind
/// - Level, dry, paved runway
///
/// All correction factors in ``PerformanceCalculator`` are applied relative
/// to these reference figures.
struct RunwayPerformance: Codable, Hashable {
    /// Pure ground roll in metres.
    var groundRollM: Double

    /// Total distance to clear a 50 ft (15 m) obstacle, in metres.
    var distanceOver50ftM: Double
}

/// Surface-dependent multipliers applied on top of the reference distances.
struct SurfaceFactors: Codable, Hashable {
    /// Multiplier applied when operating from a dry grass surface.
    var grassFactor: Double

    /// Additional multiplier applied to the landing distance on a wet surface.
    var wetLandingFactor: Double

    static let standard = SurfaceFactors(grassFactor: 1.15, wetLandingFactor: 1.15)
}
