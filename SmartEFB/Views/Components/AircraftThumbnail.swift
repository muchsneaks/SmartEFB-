import SwiftUI

/// A tinted icon tile representing an aircraft in lists and headers.
struct AircraftThumbnail: View {
    let aircraft: Aircraft

    var body: some View {
        ZStack {
            Theme.accent.opacity(0.15)
            Image(systemName: aircraft.symbolName)
                .font(.title2)
                .foregroundStyle(Theme.accent)
        }
        .clipShape(.rect(cornerRadius: Theme.cornerRadius))
    }
}
