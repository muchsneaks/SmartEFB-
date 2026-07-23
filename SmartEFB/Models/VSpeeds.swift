import Foundation

/// Key operating speeds for an aircraft, in knots indicated airspeed (KIAS).
///
/// Only the most operationally relevant speeds are modelled here; they are
/// shown for quick reference on the aircraft detail screen.
struct VSpeeds: Codable, Hashable {
    /// Rotation speed (Vr).
    var rotateKt: Double

    /// Best rate of climb (Vy).
    var bestRateOfClimbKt: Double

    /// Best angle of climb (Vx).
    var bestAngleOfClimbKt: Double

    /// Approach / reference landing speed (Vref).
    var approachKt: Double

    /// Stall speed in landing configuration (Vs0).
    var stallLandingKt: Double

    /// Never-exceed speed (Vne).
    var neverExceedKt: Double
}
