import SwiftUI

/// A selectable row representing one aircraft in the selection list.
struct AircraftRowView: View {
    let aircraft: Aircraft
    let isSelected: Bool

    private var summary: String {
        var parts = [aircraft.propType.displayName, "MTOM \(Int(aircraft.maxTakeoffWeightKg)) kg"]
        if !aircraft.icaoType.isEmpty {
            parts.insert(aircraft.icaoType, at: 0)
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 14) {
            AircraftThumbnail(aircraft: aircraft)
                .frame(width: Theme.controlSize, height: Theme.controlSize)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(aircraft.name)
                        .font(.headline)
                    if aircraft.id == DemoAircraft.id {
                        Text("BEISPIEL")
                            .font(.caption2.weight(.heavy))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Theme.caution.opacity(0.22), in: .capsule)
                            .foregroundStyle(Theme.caution)
                    }
                }
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    dataBadge("Start", available: !(aircraft.takeoffTable?.isEmpty ?? true))
                    dataBadge("Landung", available: !(aircraft.landingTable?.isEmpty ?? true))
                    dataBadge("Cruise", available: !aircraft.cruiseSettings.isEmpty)
                }
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isSelected ? Theme.positive : .secondary)
        }
        .padding(.vertical, 6)
        .contentShape(.rect)
    }

    private func dataBadge(_ title: String, available: Bool) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                (available ? Theme.positive : Color.secondary).opacity(available ? 0.22 : 0.15),
                in: .capsule
            )
            .foregroundStyle(available ? Theme.positive : .secondary)
    }
}
