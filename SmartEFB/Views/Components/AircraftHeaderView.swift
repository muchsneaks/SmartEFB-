import SwiftUI

/// A compact banner showing which aircraft the current calculation applies to.
struct AircraftHeaderView: View {
    let aircraft: Aircraft

    /// Type and registration, omitting whichever the pilot left blank.
    private var subtitle: String {
        [aircraft.icaoType, aircraft.registration]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 14) {
            AircraftThumbnail(aircraft: aircraft)
                .frame(width: Theme.controlSize, height: Theme.controlSize)

            VStack(alignment: .leading, spacing: 2) {
                Text(aircraft.name)
                    .font(.headline)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: Theme.cornerRadius))
    }
}
