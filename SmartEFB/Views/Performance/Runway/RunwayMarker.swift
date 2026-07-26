import SwiftUI

/// A distance annotation drawn across the runway diagram.
struct RunwayMarker: Identifiable, Equatable {
    var title: String
    var valueM: Double
    /// Position along the runway, 0 = threshold, 1 = departure end.
    var fraction: Double
    var color: Color
    var side: HorizontalEdge

    var id: String { title }
}

/// One marker: a labelled callout with a leader line crossing the runway.
struct RunwayMarkerRow: View {
    let marker: RunwayMarker
    let stripWidth: CGFloat
    let labelWidth: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            if marker.side == .leading {
                label
                    .frame(width: labelWidth, alignment: .trailing)
                leader
            } else {
                Spacer()
                    .frame(width: labelWidth)
            }

            Rectangle()
                .fill(marker.color)
                .frame(width: stripWidth, height: 2)

            if marker.side == .trailing {
                leader
                label
                    .frame(width: labelWidth, alignment: .leading)
            } else {
                Spacer()
                    .frame(width: labelWidth)
            }
        }
        // Pinning the row to the line's own height keeps the line exactly at the
        // marker's position; the labels simply overflow above and below it.
        .frame(height: 2)
    }

    /// The short tick joining the label to the runway edge.
    private var leader: some View {
        Rectangle()
            .fill(marker.color)
            .frame(width: 8, height: 2)
    }

    private var label: some View {
        VStack(alignment: marker.side == .leading ? .trailing : .leading, spacing: 1) {
            Text(marker.title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(Int(marker.valueM.rounded())) m")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(marker.color)
        }
        .padding(.horizontal, 4)
        .lineLimit(1)
    }
}
