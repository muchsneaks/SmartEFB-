import SwiftUI

/// Lets the pilot browse the aircraft catalogue, select the active aircraft,
/// create their own aircraft and drill into detailed reference data.
struct AircraftSelectionView: View {
    @Environment(AircraftStore.self) private var store
    @Environment(FlightConditions.self) private var conditions

    @State private var showCreate = false
    @State private var showSettings = false
    @State private var aircraftToDelete: Aircraft?
    @State private var aircraftToEdit: Aircraft?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(store.aircraft) { aircraft in
                        aircraftCard(aircraft)
                    }
                }
                .padding()
                .animation(.snappy, value: store.aircraft)
            }
            .background(Theme.background)
            .navigationTitle("Flugzeug")
            .navigationDestination(for: Aircraft.self) { aircraft in
                AircraftDetailView(aircraft: aircraft)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Einstellungen", systemImage: "gearshape") {
                        showSettings = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Flieger anlegen", systemImage: "plus") {
                        showCreate = true
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateAircraftView()
            }
            .sheet(item: $aircraftToEdit) { aircraft in
                CreateAircraftView(editing: aircraft)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .confirmationDialog(
                "Diesen Flieger löschen?",
                isPresented: .init(get: { aircraftToDelete != nil }, set: { if !$0 { aircraftToDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Löschen", role: .destructive) {
                    if let aircraft = aircraftToDelete {
                        store.deleteCustom(aircraft)
                    }
                    aircraftToDelete = nil
                }
                Button("Abbrechen", role: .cancel) { aircraftToDelete = nil }
            } message: {
                Text(aircraftToDelete?.name ?? "")
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

            HStack(spacing: 0) {
                NavigationLink(value: aircraft) {
                    Label("Details & Geschwindigkeiten", systemImage: "info.circle")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.accent)

                if aircraft.isCustom {
                    Button {
                        aircraftToEdit = aircraft
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .padding()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.accent)

                    Button(role: .destructive) {
                        aircraftToDelete = aircraft
                    } label: {
                        Image(systemName: "trash")
                            .padding()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.warning)
                }
            }
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
