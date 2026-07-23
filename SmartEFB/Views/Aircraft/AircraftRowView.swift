import SwiftUI

/// A selectable row representing one aircraft in the selection list.
struct AircraftRowView: View {
    let aircraft: Aircraft
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            AircraftThumbnail(aircraft: aircraft)
                .frame(width: 116, height: 60)

            VStack(alignment: .leading, spacing: 2) {
                Text(aircraft.name)
                    .font(.headline)
                Text("\(aircraft.icaoType) · \(aircraft.propType.displayName) · MTOM \(Int(aircraft.maxTakeoffWeightKg)) kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isSelected ? Theme.positive : .secondary)
        }
        .padding(.vertical, 6)
        .contentShape(.rect)
    }
}
