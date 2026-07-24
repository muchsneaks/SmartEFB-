import SwiftUI

/// Displays the AI import confidence and any validation warnings so the pilot
/// can judge how much to trust the extracted values.
struct ImportStatusBanner: View {
    let confidence: Double?
    let warnings: [String]

    private var tint: Color {
        guard let confidence else { return Theme.accent }
        switch confidence {
        case ..<0.5: return Theme.warning
        case ..<0.8: return Theme.caution
        default: return Theme.positive
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let confidence {
                HStack {
                    Label("KI-Konfidenz", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(confidence, format: .percent.precision(.fractionLength(0)))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(tint)
                        .contentTransition(.numericText())
                }
                ProgressView(value: min(max(confidence, 0), 1))
                    .tint(tint)
            }

            if !warnings.isEmpty {
                Divider()
                ForEach(warnings.indices, id: \.self) { index in
                    Label {
                        Text(warnings[index])
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(Theme.caution)
                    }
                }
            }
        }
        .padding()
        .background(tint.opacity(0.12), in: .rect(cornerRadius: Theme.cornerRadius))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
