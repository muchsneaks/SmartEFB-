import Foundation

/// Describes the propeller / power-management type of an aircraft.
///
/// This determines which power parameters are relevant when displaying
/// cruise and power settings to the pilot.
enum PropType: String, Codable, Hashable, CaseIterable {
    /// Fixed-pitch propeller — power is set purely via RPM.
    case fixedPitch

    /// Constant-speed propeller — power is set via a combination of
    /// manifold pressure (MP) and RPM.
    case constantSpeed

    var displayName: String {
        switch self {
        case .fixedPitch: "Festpropeller"
        case .constantSpeed: "Constant Speed"
        }
    }
}
