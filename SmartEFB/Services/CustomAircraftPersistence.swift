import Foundation

/// Persists user-created aircraft as JSON in the app's documents directory.
enum CustomAircraftPersistence {
    private static var fileURL: URL {
        URL.documentsDirectory.appending(path: "custom_aircraft.json")
    }

    /// Loads the stored custom aircraft, or an empty array if none/invalid.
    static func load() -> [Aircraft] {
        guard let data = try? Data(contentsOf: fileURL),
              let aircraft = try? JSONDecoder().decode([Aircraft].self, from: data) else {
            return []
        }
        return aircraft
    }

    /// Saves the custom aircraft, ignoring write errors (non-critical cache).
    static func save(_ aircraft: [Aircraft]) {
        guard let data = try? JSONEncoder().encode(aircraft) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
