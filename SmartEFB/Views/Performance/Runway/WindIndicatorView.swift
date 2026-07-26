import SwiftUI

/// Shows the wind relative to the runway: an arrow in a runway-up frame plus the
/// resolved head/tail and crosswind components.
struct WindIndicatorView: View {
    let windDirectionDeg: Double
    let windSpeedKt: Double
    let runwayHeadingDeg: Double
    let headwindKt: Double
    let crosswindKt: Double
    let crosswindFromLeft: Bool

    /// Where the wind comes from, relative to the runway direction of travel.
    /// The arrow shows the direction the air moves, so 0° (wind from ahead)
    /// points down the page.
    private var relativeAngle: Double {
        windDirectionDeg - runwayHeadingDeg
    }

    private var isTailwind: Bool { headwindKt < 0 }

    var body: some View {
        VStack(spacing: 10) {
            dial
            components
        }
    }

    private var dial: some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.25))
            Circle()
                .stroke(.white.opacity(0.15), lineWidth: 1)

            // Runway reference: direction of travel is up.
            Capsule()
                .fill(.white.opacity(0.25))
                .frame(width: 3, height: 34)

            if windSpeedKt > 0 {
                Image(systemName: "arrow.down")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(isTailwind ? Theme.warning : Theme.accent)
                    .rotationEffect(.degrees(relativeAngle))
                    .animation(.snappy, value: relativeAngle)
            } else {
                Text("CALM")
                    .font(.system(size: 9, design: .rounded).weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 62, height: 62)
    }

    private var components: some View {
        VStack(spacing: 4) {
            componentRow(
                systemImage: isTailwind ? "arrow.up.to.line" : "arrow.down.to.line",
                value: abs(headwindKt),
                tint: isTailwind ? Theme.warning : Theme.positive
            )
            componentRow(
                systemImage: crosswindFromLeft ? "arrow.right" : "arrow.left",
                value: crosswindKt,
                tint: .primary
            )
        }
    }

    private func componentRow(systemImage: String, value: Double, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption2)
                .foregroundStyle(tint)
            Text(value, format: .number.precision(.fractionLength(0)))
                .font(.system(.caption, design: .rounded).weight(.bold))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text("kt")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
