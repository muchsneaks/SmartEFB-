import SwiftUI

/// Detailed reference information for a single aircraft: weights, reference
/// distances and key operating speeds.
struct AircraftDetailView: View {
    let aircraft: Aircraft

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AircraftHeaderView(aircraft: aircraft)

                SectionCard(title: "Massen", systemImage: "scalemass") {
                    infoRow("Leermasse", "\(Int(aircraft.emptyWeightKg)) kg")
                    infoRow("Max. Startmasse (MTOM)", "\(Int(aircraft.maxTakeoffWeightKg)) kg")
                    infoRow("Antrieb", aircraft.propType.displayName)
                }

                SectionCard(title: "Referenzstrecken (MTOM, MSL, ISA)", systemImage: "ruler") {
                    infoRow("Start Rollstrecke", "\(Int(aircraft.takeoff.groundRollM)) m")
                    infoRow("Start über 50 ft", "\(Int(aircraft.takeoff.distanceOver50ftM)) m")
                    Divider()
                    infoRow("Landung Rollstrecke", "\(Int(aircraft.landing.groundRollM)) m")
                    infoRow("Landung über 50 ft", "\(Int(aircraft.landing.distanceOver50ftM)) m")
                }

                SectionCard(title: "Geschwindigkeiten (KIAS)", systemImage: "speedometer") {
                    infoRow("Vr (Rotation)", speed(aircraft.vSpeeds.rotateKt))
                    infoRow("Vx (bester Winkel)", speed(aircraft.vSpeeds.bestAngleOfClimbKt))
                    infoRow("Vy (beste Rate)", speed(aircraft.vSpeeds.bestRateOfClimbKt))
                    infoRow("Vref (Anflug)", speed(aircraft.vSpeeds.approachKt))
                    infoRow("Vs0 (Überziehen)", speed(aircraft.vSpeeds.stallLandingKt))
                    infoRow("Vne (nie überschreiten)", speed(aircraft.vSpeeds.neverExceedKt))
                }

                DisclaimerView()
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(aircraft.icaoType)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func speed(_ value: Double) -> String {
        "\(Int(value)) kt"
    }

    private func infoRow(_ title: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .bold()
                .monospacedDigit()
        }
        .font(.subheadline)
    }
}
