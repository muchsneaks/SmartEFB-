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

/// The calculation for one selected aircraft.
///
/// On a wide screen the layout follows an airliner performance page — inputs,
/// results and the runway view side by side. On a phone the same panels stack,
/// with the runway view directly under the phase selector where it is most useful.
private struct PerformanceContentView: View {
    let aircraft: Aircraft

    @Environment(FlightConditions.self) private var conditions
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var mode: PerformanceMode = .takeoff

    private var result: PerformanceResult? {
        switch mode {
        case .takeoff:
            PerformanceCalculator.takeoff(aircraft: aircraft, conditions: conditions.snapshot)
        case .landing:
            PerformanceCalculator.landing(aircraft: aircraft, conditions: conditions.snapshot)
        }
    }

    private var isWide: Bool { horizontalSizeClass == .regular }

    var body: some View {
        VStack(spacing: 0) {
            modeSelector

            if isWide {
                wideLayout
            } else {
                compactLayout
            }
        }
        .animation(.snappy, value: mode)
        .onAppear { conditions.syncWeight(to: aircraft) }
        .onChange(of: aircraft) { _, newValue in
            conditions.syncWeight(to: newValue)
        }
    }

    // MARK: Phase selector

    private var modeSelector: some View {
        Picker("Modus", selection: $mode) {
            ForEach(PerformanceMode.allCases) { mode in
                Label(mode.displayName, systemImage: mode.symbolName).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: Layouts

    private var compactLayout: some View {
        ScrollView {
            VStack(spacing: 16) {
                diagramOrPlaceholder

                if let result {
                    PerformanceResultsPanel(result: result, mode: mode, vSpeeds: aircraft.vSpeeds)
                }

                PerformanceInputsColumn(aircraft: aircraft)
            }
            .padding()
        }
    }

    private var wideLayout: some View {
        HStack(alignment: .top, spacing: 16) {
            ScrollView {
                PerformanceInputsColumn(aircraft: aircraft)
                    .padding(.vertical)
            }
            .frame(maxWidth: 380)

            ScrollView {
                Group {
                    if let result {
                        PerformanceResultsPanel(result: result, mode: mode, vSpeeds: aircraft.vSpeeds)
                    } else {
                        missingData
                    }
                }
                .padding(.vertical)
            }

            ScrollView {
                diagramOrPlaceholder
                    .padding(.vertical)
            }
            .frame(maxWidth: 300)
        }
        .padding(.horizontal)
    }

    // MARK: Pieces

    @ViewBuilder
    private var diagramOrPlaceholder: some View {
        if let result {
            RunwayDiagramView(
                result: result,
                mode: mode,
                runwayLengthM: conditions.runwayLengthM,
                runwayHeadingDeg: conditions.runwayHeadingDeg,
                surface: conditions.surface,
                windDirectionDeg: conditions.windDirectionDeg,
                windSpeedKt: conditions.windSpeedKt
            )
        } else if !isWide {
            missingData
        }
    }

    private var missingData: some View {
        MissingDataView(
            title: mode == .takeoff ? "Keine Startdaten" : "Keine Landedaten",
            message: "Für dieses Flugzeug ist noch keine passende Tabelle hinterlegt. Bearbeite das Flugzeug und importiere die entsprechende POH-Seite."
        )
        .padding(.vertical)
    }
}
