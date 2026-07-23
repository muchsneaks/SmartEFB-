import SwiftUI
import UIKit

/// Shows an aircraft's transparent side-profile photo when one is available in
/// the asset catalogue, otherwise falls back to a tinted SF Symbol.
///
/// The `UIImage(named:)` lookup lets the view degrade gracefully: if the photo
/// asset has not been added yet, the symbol is shown instead of a blank space.
struct AircraftThumbnail: View {
    let aircraft: Aircraft

    var body: some View {
        ZStack {
            if let name = aircraft.imageName, let image = UIImage(named: name) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(6)
            } else {
                Theme.accent.opacity(0.15)
                Image(systemName: aircraft.symbolName)
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
            }
        }
        .clipShape(.rect(cornerRadius: Theme.cornerRadius))
    }
}
