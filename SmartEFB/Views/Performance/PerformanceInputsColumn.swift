import SwiftUI

/// The input column: aircraft, loading and every condition that feeds the
/// calculation. Keeps the large turbulence-friendly steppers.
struct PerformanceInputsColumn: View {
    let aircraft: Aircraft

    @Environment(FlightConditions.self) private var conditions

    /// A safe stepper range even if the stored weights are inconsistent.
    private var weightRange: ClosedRange<Double> {
        let lower = min(aircraft.emptyWeightKg, aircraft.maxTakeoffWeightKg)
        let upper = max(aircraft.emptyWeightKg, aircraft.maxTakeoffWeightKg)
        return lower < upper ? lower...upper : lower...(lower + 1)
    }

    var body: some View {
        @Bindable var conditions = conditions

        VStack(spacing: 16) {
            AircraftHeaderView(aircraft: aircraft)

            SectionCard(title: "Beladung", systemImage: "scalemass") {
                BigStepper(title: "Masse", systemImage: "scalemass",
                           value: $conditions.weightKg,
                           range: weightRange,
                           step: 5,
                           unit: "kg (MTOM \(Int(aircraft.maxTakeoffWeightKg)) kg)")
            }

            ConditionsInputView()

            DisclaimerView()
        }
    }
}
