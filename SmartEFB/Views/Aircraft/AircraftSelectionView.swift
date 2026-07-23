import SwiftUI

/// Lets the pilot browse the aircraft catalogue, select the active aircraft and
/// drill into detailed reference data.
struct AircraftSelectionView: View {
    @Environment(AircraftStore.self) private var store
    @Environment(FlightConditions.self) private var conditions

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(store.aircraft) { aircraft in
                        aircraftCard(aircraft)
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Flugzeug")
            .navigationDestination(for: Aircraft.self) { aircraft in
                AircraftDetailView(aircraft: aircraft)
            }
        }
    }

    private func aircraftCard(_ aircraft: Aircraft) -> some View {
        let isSelected = aircraft.id == store.selected.id
        return VStack(spacing: 0) {
            Button {
                store.select(aircraft)
                conditions.syncWeight(to: aircraft)
            } label: {
                AircraftRowView(aircraft: aircraft, isSelected: isSelected)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            .buttonStyle(.plain)

            NavigationLink(value: aircraft) {
                Label("Details & Geschwindigkeiten", systemImage: "info.circle")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.accent)
        }
        .background(
            (isSelected ? Theme.accent.opacity(0.12) : Color.white.opacity(0.05)),
            in: .rect(cornerRadius: Theme.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(isSelected ? Theme.accent : .clear, lineWidth: 2)
        }
    }
}
