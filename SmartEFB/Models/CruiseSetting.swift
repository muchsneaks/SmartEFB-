import Foundation

/// A single row from an aircraft's cruise-performance / power-setting table.
///
/// Values are given at a specific pressure altitude and ISA conditions, as
/// published in the aircraft's Pilot's Operating Handbook (POH). The app
/// adjusts true airspeed for the actual conditions at display time.
struct CruiseSetting: Codable, Hashable, Identifiable {
    var id: UUID = UUID()

    /// Pressure altitude for which this row is valid, in feet.
    var pressureAltitudeFt: Double

    /// Engine speed in RPM.
    var rpm: Int

    /// Manifold pressure in inches of mercury. `nil` for fixed-pitch aircraft.
    var manifoldPressureInHg: Double?

    /// Percentage of maximum continuous power (e.g. 65 for 65 %).
    var percentPower: Int

    /// True airspeed at ISA conditions, in knots.
    var trueAirspeedKt: Double

    /// Fuel flow in litres per hour.
    var fuelFlowLph: Double
}
