import SwiftUI

/// A compact banner showing which aircraft the current calculation applies to.
struct AircraftHeaderView: View {
    let aircraft: Aircraft

    var body: some View {
        HStack(spacing: 14) {
            AircraftThumbnail(aircraft: aircraft)
                .frame(width: 92, height: 56)

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
