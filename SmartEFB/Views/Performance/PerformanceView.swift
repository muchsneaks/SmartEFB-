import SwiftUI

/// The take-off / landing distance planning screen.
struct PerformanceView: View {
    @Environment(AircraftStore.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if let aircraft = store.selected {
                    PerformanceContentView(aircraft: aircraft)
                } else {
                    NoAircraftView()
                }
            }
            .background(Theme.background)
            .navigationTitle("Start & Landung")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// The scrollable calculation content for one selected aircraft.
private struct PerformanceContentView: View {
    let aircraft: Aircraft

    @Environment(FlightConditions.self) private var conditions
    @State private var mode: PerformanceMode = .takeoff

    private var result: PerformanceResult? {
        switch mode {
        case .takeoff:
            PerformanceCalculator.takeoff(aircraft: aircraft, conditions: conditions.snapshot)
        case .landing:
            PerformanceCalculator.landing(aircraft: aircraft, conditions: conditions.snapshot)
        }
    }

    /// A safe stepper range even if the stored weights are inconsistent.
    private var weightRange: ClosedRange<Double> {
        let lower = min(aircraft.emptyWeightKg, aircraft.maxTakeoffWeightKg)
        let upper = max(aircraft.emptyWeightKg, aircraft.maxTakeoffWeightKg)
        return lower < upper ? lower...upper : lower...(lower + 1)
    }

    var body: some View {
        @Bindable var conditions = conditions

        ScrollView {
            VStack(spacing: 16) {
                AircraftHeaderView(aircraft: aircraft)

                Picker("Modus", selection: $mode) {
                    ForEach(PerformanceMode.allCases) { mode in
                        Label(mode.displayName, systemImage: mode.symbolName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.large)

                SectionCard(title: "Beladung", systemImage: "scalemass") {
                    BigStepper(title: "Masse", systemImage: "scalemass",
                               value: $conditions.weightKg,
                               range: weightRange,
                               step: 5,
                               unit: "kg (MTOM \(Int(aircraft.maxTakeoffWeightKg)) kg)")
                }

                if let result {
                    PerformanceResultView(result: result)
                } else {
                    MissingDataView(
                        title: mode == .takeoff ? "Keine Startdaten" : "Keine Landedaten",
                        message: "Für dieses Flugzeug ist noch keine passende Tabelle hinterlegt. Bearbeite das Flugzeug und importiere die entsprechende POH-Seite."
                    )
                    .padding(.vertical)
                }

                ConditionsInputView()

                DisclaimerView()
            }
            .padding()
            .animation(.snappy, value: mode)
        }
        .onAppear { conditions.syncWeight(to: aircraft) }
        .onChange(of: aircraft) { _, newValue in
            conditions.syncWeight(to: newValue)
        }
    }
}
