import SwiftUI

/// The visual runway view: the available runway with the computed ground roll and
/// required distance drawn onto it, the remaining margin highlighted, and any
/// overrun shown beyond the departure end.
struct RunwayDiagramView: View {
    let result: PerformanceResult
    let mode: PerformanceMode
    let runwayLengthM: Double
    let runwayHeadingDeg: Double
    let surface: RunwaySurface
    let windDirectionDeg: Double
    let windSpeedKt: Double

    private let stripWidth: CGFloat = 74
    private let stripHeight: CGFloat = 340
    private let labelWidth: CGFloat = 84

    /// Runway number derived from the heading, e.g. 250° → "25".
    private var designator: String {
        var number = Int((runwayHeadingDeg / 10).rounded())
        if number > 36 { number -= 36 }
        if number <= 0 { number = 36 }
        return number < 10 ? "0\(number)" : "\(number)"
    }

    private var rollFraction: Double {
        guard runwayLengthM > 0 else { return 0 }
        return (result.groundRollM / runwayLengthM).clamped(to: 0...1)
    }

    private var requiredFraction: Double {
        guard runwayLengthM > 0 else { return 0 }
        return (result.requiredDistanceM / runwayLengthM).clamped(to: 0...1)
    }

    /// How far the required distance runs past the end, as a fraction of the strip.
    private var overrunFraction: Double {
        guard runwayLengthM > 0, result.requiredDistanceM > runwayLengthM else { return 0 }
        let excess = (result.requiredDistanceM - runwayLengthM) / runwayLengthM
        // Capped so a gross overshoot still renders inside the card.
        return min(excess, 0.28)
    }

    private var markers: [RunwayMarker] {
        [
            RunwayMarker(
                title: mode == .takeoff ? "Abheben" : "Stillstand",
                valueM: result.groundRollM,
                fraction: rollFraction,
                color: Theme.accent,
                side: .leading
            ),
            RunwayMarker(
                title: "Erforderlich",
                valueM: result.requiredDistanceM,
                fraction: requiredFraction,
                color: result.fitsOnRunway ? Theme.positive : Theme.warning,
                side: .trailing
            )
        ]
    }

    var body: some View {
        VStack(spacing: 14) {
            header

            ZStack(alignment: .bottom) {
                if overrunFraction > 0 {
                    overrunBand
                }

                RunwayStripView(
                    designator: designator,
                    lengthM: runwayLengthM,
                    surface: surface,
                    width: stripWidth,
                    height: stripHeight
                )

                marginBand

                ForEach(markers) { marker in
                    RunwayMarkerRow(marker: marker, stripWidth: stripWidth, labelWidth: labelWidth)
                        .offset(y: -marker.fraction * stripHeight)
                }
            }
            .frame(width: stripWidth + 2 * labelWidth, height: stripHeight + overrunFraction * stripHeight)
            .animation(.snappy, value: requiredFraction)
            .animation(.snappy, value: rollFraction)

            WindIndicatorView(
                windDirectionDeg: windDirectionDeg,
                windSpeedKt: windSpeedKt,
                runwayHeadingDeg: runwayHeadingDeg,
                headwindKt: result.headwindKt,
                crosswindKt: result.crosswindKt,
                crosswindFromLeft: result.crosswindFromLeft
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(.regularMaterial, in: .rect(cornerRadius: Theme.cornerRadius))
    }

    private var header: some View {
        HStack {
            Label("PISTE \(designator)", systemImage: mode.symbolName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.accent)
            Spacer()
            Text(surface.shortName.uppercased())
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.white.opacity(0.1), in: .capsule)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    /// The unused runway beyond the required distance — the reserve.
    private var marginBand: some View {
        let bandHeight = max(0, (1 - requiredFraction) * stripHeight)

        return VStack(spacing: 3) {
            if result.fitsOnRunway && bandHeight > 26 {
                Text("Reserve")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(Int(result.marginM.rounded())) m")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.positive)
            }
        }
        .frame(width: stripWidth, height: bandHeight, alignment: .center)
        .background(
            Theme.positive.opacity(result.fitsOnRunway ? 0.22 : 0),
            in: .rect(cornerRadius: 3)
        )
        .offset(y: -requiredFraction * stripHeight)
    }

    /// The distance still needed past the end of the runway.
    private var overrunBand: some View {
        VStack(spacing: 2) {
            Text("Fehlend")
                .font(.caption2)
                .foregroundStyle(Theme.warning)
            Text("\(Int(abs(result.marginM).rounded())) m")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Theme.warning)
        }
        .frame(width: stripWidth, height: overrunFraction * stripHeight)
        .background(
            Theme.warning.opacity(0.28),
            in: .rect(cornerRadius: 3)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 3)
                .stroke(Theme.warning, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
        .offset(y: -stripHeight)
    }
}
