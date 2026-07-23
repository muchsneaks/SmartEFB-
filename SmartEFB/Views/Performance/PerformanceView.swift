import SwiftUI

/// The take-off / landing distance planning screen.
struct PerformanceView: View {
    @Environment(AircraftStore.self) private var store
    @Environment(FlightConditions.self) private var conditions

    @State private var mode: PerformanceMode = .takeoff

    private var result: PerformanceResult {
        switch mode {
        case .takeoff: PerformanceCalculator.takeoff(aircraft: store.selected, conditions: conditions)
        case .landing: PerformanceCalculator.landing(aircraft: store.selected, conditions: conditions)
        }
    }

    var body: some View {
        @Bindable var conditions = conditions

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    AircraftHeaderView(aircraft: store.selected)

                    Picker("Modus", selection: $mode) {
                        ForEach(PerformanceMode.allCases) { mode in
                            Label(mode.displayName, systemImage: mode.symbolName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.large)

                    SectionCard(title: "Beladung", systemImage: "scalemass") {
                        BigStepper(title: "Abflugmasse", systemImage: "scalemass",
                                   value: $conditions.weightKg,
                                   range: store.selected.emptyWeightKg...store.selected.maxTakeoffWeightKg,
                                   step: 10, unit: "kg (MTOM \(Int(store.selected.maxTakeoffWeightKg)) kg)")
                    }

                    PerformanceResultView(mode: mode, result: result)

                    ConditionsInputView()

                    DisclaimerView()
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Start & Landung")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { conditions.syncWeight(to: store.selected) }
            .onChange(of: store.selected) { _, newValue in
                conditions.syncWeight(to: newValue)
            }
        }
    }
}
