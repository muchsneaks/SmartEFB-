import SwiftUI

/// Lets the pilot manage their aircraft: create, select, edit and delete.
struct AircraftSelectionView: View {
    @Environment(AircraftStore.self) private var store
    @Environment(FlightConditions.self) private var conditions

    /// A single sheet destination: presenting several `.sheet` modifiers from one
    /// view is unreliable, so all of them are driven by this one value.
    private enum Destination: Identifiable {
        case create
        case edit(Aircraft)
        case settings

        var id: String {
            switch self {
            case .create: "create"
            case .edit(let aircraft): "edit-\(aircraft.id)"
            case .settings: "settings"
            }
        }
    }

    @State private var destination: Destination?
    @State private var aircraftToDelete: Aircraft?

    var body: some View {
        NavigationStack {
            Group {
                if store.isEmpty {
                    NoAircraftView(
                        onCreate: { destination = .create },
                        onLoadDemo: { loadDemo() }
                    )
                } else {
                    list
                }
            }
            .background(Theme.background)
            .navigationTitle("Flugzeug")
            .navigationDestination(for: Aircraft.self) { aircraft in
                AircraftDetailView(aircraft: aircraft)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Einstellungen", systemImage: "gearshape") { destination = .settings }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Flugzeug anlegen", systemImage: "plus") { destination = .create }
                        if !store.hasDemoAircraft {
                            Button("Beispielflieger laden", systemImage: "sparkles") {
                                loadDemo()
                            }
                        }
                    } label: {
                        Label("Hinzufügen", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $destination) { destination in
                switch destination {
                case .create:
                    CreateAircraftView()
                case .edit(let aircraft):
                    CreateAircraftView(editing: aircraft)
                case .settings:
                    SettingsView()
                }
            }
            .confirmationDialog(
                "Dieses Flugzeug löschen?",
                isPresented: Binding(
                    get: { aircraftToDelete != nil },
                    set: { if !$0 { aircraftToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Löschen", role: .destructive) {
                    if let aircraft = aircraftToDelete {
                        store.delete(aircraft)
                    }
                    aircraftToDelete = nil
                }
                Button("Abbrechen", role: .cancel) { aircraftToDelete = nil }
            } message: {
                Text(aircraftToDelete?.name ?? "")
            }
        }
    }

    /// Loads the example aircraft and aligns the planning weight with it.
    private func loadDemo() {
        withAnimation(.snappy) {
            store.loadDemoAircraft()
            conditions.syncWeight(to: store.selected)
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(store.aircraft) { aircraft in
                    aircraftCard(aircraft)
                }
            }
            .padding()
            .animation(.snappy, value: store.aircraft)
        }
    }

    private func aircraftCard(_ aircraft: Aircraft) -> some View {
        let isSelected = aircraft.id == store.selected?.id

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
                    Label("Details", systemImage: "info.circle")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.accent)

                Button {
                    destination = .edit(aircraft)
                } label: {
                    Label("Bearbeiten", systemImage: "square.and.pencil")
                        .labelStyle(.iconOnly)
                        .padding()
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.accent)

                Button(role: .destructive) {
                    aircraftToDelete = aircraft
                } label: {
                    Label("Löschen", systemImage: "trash")
                        .labelStyle(.iconOnly)
                        .padding()
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.warning)
            }
        }
        .background(
            isSelected ? Theme.accent.opacity(0.12) : Color.white.opacity(0.05),
            in: .rect(cornerRadius: Theme.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(isSelected ? Theme.accent : .clear, lineWidth: 2)
        }
    }
}
