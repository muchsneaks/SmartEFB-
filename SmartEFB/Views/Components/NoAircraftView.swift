import SwiftUI

/// Shown whenever no aircraft exists yet. The app ships empty, so this is the
/// first thing a new pilot sees.
struct NoAircraftView: View {
    /// Called when the pilot wants to start the creation wizard. When `nil`, only
    /// the explanatory text is shown (e.g. on the calculation tabs).
    var onCreate: (() -> Void)?

    /// Called to load the bundled example aircraft for a first look around.
    var onLoadDemo: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label("Noch kein Flugzeug", systemImage: "airplane.circle")
        } description: {
            Text("Lege dein Flugzeug an und übernimm die Leistungsdaten aus dem Flughandbuch – per Foto oder von Hand.")
        } actions: {
            if let onCreate {
                VStack(spacing: 12) {
                    Button("Flugzeug anlegen", systemImage: "plus") {
                        onCreate()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if let onLoadDemo {
                        Button("Beispielflieger laden", systemImage: "sparkles") {
                            onLoadDemo()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                        Text("Zum Ausprobieren – enthält erfundene Beispielwerte, nicht für echte Flüge.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            } else {
                Text("Im Tab „Flugzeug“ anlegen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Shown when an aircraft exists but lacks the chart needed for this screen.
struct MissingDataView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "tablecells.badge.ellipsis")
        } description: {
            Text(message)
        }
    }
}
