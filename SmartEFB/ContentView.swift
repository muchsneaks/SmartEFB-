import SwiftUI

/// Root tab layout wiring the three main areas of the app together.
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Start & Landung", systemImage: "airplane.departure") {
                PerformanceView()
            }

            Tab("Prop & Cruise", systemImage: "gauge.with.dots.needle.67percent") {
                PropSettingsView()
            }

            Tab("Flugzeug", systemImage: "airplane.circle") {
                AircraftSelectionView()
            }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    ContentView()
        .environment(AircraftStore())
        .environment(FlightConditions())
        .environment(APIKeyStore())
        .preferredColorScheme(.dark)
}
