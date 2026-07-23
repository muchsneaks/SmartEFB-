import Foundation

/// A selectable aircraft with all data needed for performance planning and
/// power-setting display.
///
/// The performance figures included with the bundled sample aircraft are
/// realistic planning values but are **not** a substitute for the official
/// Pilot's Operating Handbook (POH) / Aircraft Flight Manual.
struct Aircraft: Codable, Hashable, Identifiable {
    var id: UUID = UUID()

    /// Full marketing name, e.g. "Cessna 172S Skyhawk".
    var name: String

    /// Sample registration used for display, e.g. "D-EABC".
    var registration: String

    /// ICAO type designator, e.g. "C172".
    var icaoType: String

    /// SF Symbol name used to represent the aircraft in lists.
    var symbolName: String

    /// Propeller / power-management type.
    var propType: PropType

    // MARK: Weights (kilograms)

    /// Basic empty weight.
    var emptyWeightKg: Double

    /// Maximum take-off weight (also used as landing reference weight).
    var maxTakeoffWeightKg: Double

    /// A sensible default planning weight, pre-filled in the calculator.
    var defaultPlanningWeightKg: Double

    // MARK: Performance references

    var takeoff: RunwayPerformance
    var landing: RunwayPerformance
    var surfaceFactors: SurfaceFactors

    // MARK: Cruise & speeds

    var cruiseSettings: [CruiseSetting]
    var vSpeeds: VSpeeds

    /// Cruise settings sorted by pressure altitude (ascending).
    var sortedCruiseSettings: [CruiseSetting] {
        cruiseSettings.sorted { $0.pressureAltitudeFt < $1.pressureAltitudeFt }
    }
}
