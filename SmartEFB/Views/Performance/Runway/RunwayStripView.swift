import SwiftUI

/// The runway itself, drawn vertically with the threshold at the bottom and the
/// departure end at the top — the orientation used on airliner performance pages.
struct RunwayStripView: View {
    let designator: String
    let lengthM: Double
    let surface: RunwaySurface
    let width: CGFloat
    let height: CGFloat

    /// One centreline dash per ~46 pt of runway, at least two.
    private var dashCount: Int {
        max(2, Int(height / 46))
    }

    private var surfaceGradient: LinearGradient {
        switch surface {
        case .paved:
            LinearGradient(
                colors: [Color(white: 0.24), Color(white: 0.16)],
                startPoint: .leading, endPoint: .trailing
            )
        case .grass:
            LinearGradient(
                colors: [Color(red: 0.18, green: 0.29, blue: 0.18),
                         Color(red: 0.12, green: 0.21, blue: 0.13)],
                startPoint: .leading, endPoint: .trailing
            )
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(surfaceGradient)
                .overlay {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                }

            centreline

            VStack {
                thresholdBars
                Spacer()
                Text(designator)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .padding(.bottom, 6)
                thresholdBars
            }
            .padding(.vertical, 6)

            lengthLabel
        }
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
    }

    private var centreline: some View {
        VStack(spacing: 16) {
            ForEach(0..<dashCount, id: \.self) { _ in
                Capsule()
                    .fill(.white.opacity(0.8))
                    .frame(width: 4)
            }
        }
        .padding(.vertical, 34)
    }

    /// The piano-key style bars at each end of the runway.
    private var thresholdBars: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { _ in
                Rectangle()
                    .fill(.white.opacity(0.75))
                    .frame(width: 4, height: 12)
            }
        }
    }

    /// The available length, printed along the runway like on a chart.
    private var lengthLabel: some View {
        Text("\(Int(lengthM)) m")
            .font(.system(.caption, design: .rounded).weight(.bold))
            .foregroundStyle(.white.opacity(0.9))
            .monospacedDigit()
            .fixedSize()
            .rotationEffect(.degrees(-90))
    }
}
