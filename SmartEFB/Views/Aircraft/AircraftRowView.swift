import SwiftUI

/// A selectable row representing one aircraft in the selection list.
struct AircraftRowView: View {
    let aircraft: Aircraft
    let isSelected: Bool

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
