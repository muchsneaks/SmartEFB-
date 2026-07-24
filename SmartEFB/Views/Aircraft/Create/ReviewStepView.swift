import SwiftUI

/// Wizard step 4 – review and correct the performance data before saving.
struct ReviewStepView: View {
    @Bindable var vm: AircraftDraftViewModel

    var body: some View {
        Form {
            if vm.importState == .success {
                Section {
                    ImportStatusBanner(confidence: vm.confidence, warnings: vm.warnings)
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 4)
                }
            }

            PerformanceReviewSection(vm: vm)
        }
    }
}
