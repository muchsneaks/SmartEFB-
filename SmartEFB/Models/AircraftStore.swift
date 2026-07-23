import Foundation
import Observation

/// Owns the catalogue of available aircraft and the pilot's current selection.
@MainActor
@Observable
final class AircraftStore {
    /// All aircraft available for selection.
    private(set) var aircraft: [Aircraft]

    /// The currently selected aircraft used across all screens.
    var selected: Aircraft

    init(aircraft: [Aircraft] = AircraftLibrary.all) {
        // The catalogue is guaranteed non-empty; fall back defensively.
        let list = aircraft.isEmpty ? [AircraftLibrary.cessna172] : aircraft
        self.aircraft = list
        self.selected = list[0]
    }

    /// Selects an aircraft by identity.
    func select(_ aircraft: Aircraft) {
        selected = aircraft
    }
}
