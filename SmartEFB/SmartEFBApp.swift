import SwiftUI

/// Application entry point.
///
/// The shared ``AircraftStore`` and ``FlightConditions`` are owned here and
/// injected into the environment so every screen sees the same aircraft
/// selection and conditions.
@main
struct SmartEFBApp: App {
    @State private var store = AircraftStore()
    @State private var conditions = FlightConditions()
    @State private var keyStore = APIKeyStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(conditions)
                .environment(keyStore)
                .preferredColorScheme(.dark)
        }
    }
}
