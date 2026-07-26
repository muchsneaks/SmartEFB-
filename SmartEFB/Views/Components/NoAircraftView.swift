import SwiftUI

/// Shown whenever no aircraft exists yet. The app ships empty, so this is the
/// first thing a new pilot sees.
struct NoAircraftView: View {
    /// Called when the pilot wants to start the creation wizard. When `nil`, only
    /// the explanatory text is shown (e.g. on the calculation tabs).
    var onCreate: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label("Noch kein Flugzeug", systemImage: "airplane.circle")
        } description: {
            Text("Lege dein Flugzeug an und übernimm die Leistungsdaten aus dem Flughandbuch – per Foto oder von Hand.")
        } actions: {
            if let onCreate {
                Button("Flugzeug anlegen", systemImage: "plus") {
                    onCreate()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
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
