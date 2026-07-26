import Foundation

/// Persists the pilot's aircraft as JSON in the app's documents directory.
enum AircraftPersistence {
    private static var fileURL: URL {
        URL.documentsDirectory.appending(path: "aircraft.json")
    }

    /// Loads the stored aircraft, or an empty array if none exist or the file
    /// cannot be read.
    static func load() -> [Aircraft] {
        guard let data = try? Data(contentsOf: fileURL),
              let aircraft = try? JSONDecoder().decode([Aircraft].self, from: data) else {
            return []
        }
        return aircraft
    }

    /// Saves the aircraft, ignoring write errors.
    static func save(_ aircraft: [Aircraft]) {
        guard let data = try? JSONEncoder().encode(aircraft) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
