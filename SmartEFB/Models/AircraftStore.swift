import Foundation
import Observation

/// Owns the catalogue of available aircraft (built-in plus user-created) and the
/// pilot's current selection.
@MainActor
@Observable
final class AircraftStore {
    /// The bundled sample aircraft.
    private let builtIn: [Aircraft]

    /// User-created aircraft, persisted between launches.
    private(set) var custom: [Aircraft]

    /// The currently selected aircraft used across all screens.
    var selected: Aircraft

    init(builtIn: [Aircraft] = AircraftLibrary.all, custom: [Aircraft]? = nil) {
        let base = builtIn.isEmpty ? [AircraftLibrary.cessna172] : builtIn
        self.builtIn = base
        self.custom = custom ?? CustomAircraftPersistence.load()
        self.selected = base[0]
    }

    /// All aircraft available for selection: built-in first, then custom.
    var aircraft: [Aircraft] {
        builtIn + custom
    }

    /// Selects an aircraft.
    func select(_ aircraft: Aircraft) {
        selected = aircraft
    }

    /// Adds a user-created aircraft, persists it and selects it.
    func addCustom(_ aircraft: Aircraft) {
        var new = aircraft
        new.isCustom = true
        custom.append(new)
        persist()
        selected = new
    }

    /// Deletes a user-created aircraft. Built-in aircraft are ignored.
    func deleteCustom(_ aircraft: Aircraft) {
        guard aircraft.isCustom else { return }
        custom.removeAll { $0.id == aircraft.id }
        persist()
        if selected.id == aircraft.id {
            selected = self.aircraft.first ?? builtIn[0]
        }
    }

    private func persist() {
        CustomAircraftPersistence.save(custom)
    }
}
