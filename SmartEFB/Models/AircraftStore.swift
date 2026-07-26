import Foundation
import Observation

/// Owns the pilot's aircraft and the current selection.
///
/// The app ships with no aircraft: the catalogue starts empty and is filled
/// entirely by the pilot, so every calculation is based on their own POH data.
@MainActor
@Observable
final class AircraftStore {
    /// All aircraft the pilot has created, in creation order.
    private(set) var aircraft: [Aircraft]

    /// The currently selected aircraft, or `nil` while none exists.
    var selected: Aircraft?

    init(aircraft: [Aircraft]? = nil) {
        let loaded = aircraft ?? AircraftPersistence.load()
        self.aircraft = loaded
        self.selected = loaded.first
    }

    var isEmpty: Bool { aircraft.isEmpty }

    /// Selects an aircraft.
    func select(_ aircraft: Aircraft) {
        selected = aircraft
    }

    /// Adds a new aircraft, persists it and selects it.
    func add(_ aircraft: Aircraft) {
        self.aircraft.append(aircraft)
        persist()
        selected = aircraft
    }

    /// Replaces an existing aircraft, keeping its position in the list.
    func update(_ aircraft: Aircraft) {
        guard let index = self.aircraft.firstIndex(where: { $0.id == aircraft.id }) else { return }
        self.aircraft[index] = aircraft
        persist()
        if selected?.id == aircraft.id {
            selected = aircraft
        }
    }

    /// Deletes an aircraft, moving the selection to whatever remains.
    func delete(_ aircraft: Aircraft) {
        self.aircraft.removeAll { $0.id == aircraft.id }
        persist()
        if selected?.id == aircraft.id {
            selected = self.aircraft.first
        }
    }

    private func persist() {
        AircraftPersistence.save(aircraft)
    }
}
