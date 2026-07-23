import SwiftUI

/// A persistent safety disclaimer reminding the pilot that the figures are
/// planning approximations, not certified performance data.
struct DisclaimerView: View {
    var body: some View {
        Label {
            Text("Planungswerte – kein Ersatz für das offizielle Flughandbuch (POH/AFM). Vor jedem Flug die zertifizierten Leistungsdaten prüfen.")
        } icon: {
            Image(systemName: "exclamationmark.shield")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.caution.opacity(0.12), in: .rect(cornerRadius: Theme.cornerRadius))
    }
}
