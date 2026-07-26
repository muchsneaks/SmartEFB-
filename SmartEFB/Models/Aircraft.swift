import Foundation

/// A user-created aircraft with the data needed for performance planning and
/// power-setting display.
///
/// All performance data originates from the pilot's own POH — either typed in or
/// imported from a photographed table or chart. The app ships without any
/// aircraft, so nothing is ever computed from figures the pilot did not supply.
struct Aircraft: Codable, Hashable, Identifiable {
    var id: UUID = UUID()

    /// Full type name, e.g. "Diamond DA20-C1".
    var name: String

    /// Registration used for display, e.g. "D-EUMM".
    var registration: String

    /// ICAO type designator, e.g. "DA20".
    var icaoType: String

    /// SF Symbol used to represent the aircraft in lists.
    var symbolName: String = "airplane"

    /// Propeller / power-management type.
    var propType: PropType

    // MARK: Weights (kilograms)

    var emptyWeightKg: Double
    var maxTakeoffWeightKg: Double

    /// Default planning weight, pre-filled in the calculator.
    var defaultPlanningWeightKg: Double

    // MARK: Performance charts

    /// Sampled take-off chart, or `nil` if the pilot has not entered one.
    var takeoffTable: PerformanceTable?

    /// Sampled landing chart, or `nil` if the pilot has not entered one.
    var landingTable: PerformanceTable?

    // MARK: Cruise & speeds

    var cruiseSettings: [CruiseSetting] = []
    var vSpeeds: VSpeeds?

    /// Cruise settings sorted by pressure altitude (ascending).
    var sortedCruiseSettings: [CruiseSetting] {
        cruiseSettings.sorted { $0.pressureAltitudeFt < $1.pressureAltitudeFt }
    }

    /// Whether any runway performance data is available at all.
    var hasRunwayData: Bool {
        !(takeoffTable?.isEmpty ?? true) || !(landingTable?.isEmpty ?? true)
    }
}
