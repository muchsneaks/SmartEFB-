import SwiftUI

/// Root tab layout wiring the three main areas of the app together.
///
/// With no aircraft yet, the aircraft tab is preselected so a new pilot lands
/// directly on the creation flow.
struct ContentView: View {
    @Environment(AircraftStore.self) private var store

    @State private var selection: Tabs = .aircraft

    private enum Tabs: Hashable {
        case performance, cruise, aircraft
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Start & Landung", systemImage: "airplane.departure", value: Tabs.performance) {
                PerformanceView()
            }

            Tab("Prop & Cruise", systemImage: "gauge.with.dots.needle.67percent", value: Tabs.cruise) {
                PropSettingsView()
            }

            Tab("Flugzeug", systemImage: "airplane.circle", value: Tabs.aircraft) {
                AircraftSelectionView()
            }
        }
        .tint(Theme.accent)
        .onAppear {
            // Once an aircraft exists, open on the calculation the pilot needs.
            if !store.isEmpty {
                selection = .performance
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AircraftStore(aircraft: []))
        .environment(FlightConditions())
        .environment(APIKeyStore())
        .preferredColorScheme(.dark)
}
