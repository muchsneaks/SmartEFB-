import SwiftUI

/// A slim progress indicator for the aircraft-creation wizard: one segment per
/// step, filled up to the current step, plus a step counter.
struct WizardProgressBar: View {
    let current: WizardStep

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(WizardStep.allCases) { step in
                    Capsule()
                        .fill(step.rawValue <= current.rawValue ? Theme.accent : Color.white.opacity(0.15))
                        .frame(height: 5)
                }
            }
            .animation(.snappy, value: current)

            HStack {
                Text("Schritt \(current.rawValue + 1) von \(WizardStep.allCases.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(current.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

/// The icon + title + subtitle header shown above each wizard step, giving the
/// flow its guided, onboarding-like feel.
struct WizardStepHeader: View {
    let step: WizardStep

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: step.systemImage)
                .font(.title2)
                .foregroundStyle(Theme.accent)
                .frame(width: 46, height: 46)
                .background(Theme.accent.opacity(0.15), in: .rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.headline)
                Text(step.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
