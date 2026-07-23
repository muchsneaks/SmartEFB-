import SwiftUI

/// A compact banner showing which aircraft the current calculation applies to.
struct AircraftHeaderView: View {
    let aircraft: Aircraft

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: aircraft.symbolName)
                .font(.title2)
                .foregroundStyle(Theme.accent)
                .frame(width: Theme.controlSize, height: Theme.controlSize)
                .background(Theme.accent.opacity(0.15), in: .rect(cornerRadius: Theme.cornerRadius))

            VStack(alignment: .leading, spacing: 2) {
                Text(aircraft.name)
                    .font(.headline)
                Text("\(aircraft.icaoType) · \(aircraft.registration)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: Theme.cornerRadius))
    }
}
