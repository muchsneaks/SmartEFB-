import SwiftUI

/// Editor for one performance chart: its sampled grid points plus the POH's
/// correction factors. Every imported value can be corrected here.
struct PerformancePointsEditor: View {
    let title: LocalizedStringKey
    @Binding var points: [PerformanceDataPoint]
    @Binding var corrections: PerformanceCorrections

    /// Used to seed a new row with plausible values.
    let isLanding: Bool

    var body: some View {
        Section {
            if points.isEmpty {
                Text("Keine Stützpunkte. Importiere die POH-Seite oder füge Werte von Hand hinzu.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach($points) { $point in
                    PerformancePointRow(point: $point)
                }
                .onDelete { offsets in
                    points.remove(atOffsets: offsets)
                }
            }

            Button {
                withAnimation(.snappy) { points.append(newPoint()) }
            } label: {
                Label("Stützpunkt hinzufügen", systemImage: "plus.circle")
            }
        } header: {
            Text(title)
        } footer: {
            if points.isEmpty {
                Text("Werte gelten bei 0 kt Wind auf ebener, trockener Hartbahn.")
            } else {
                Text("\(points.count) Stützpunkt(e) · Werte bei 0 kt Wind, ebener trockener Hartbahn. Zum Löschen nach links wischen.")
            }
        }

        Section("Korrekturfaktoren (\(isLanding ? "Landung" : "Start"))") {
            percentRow("Gegenwind", value: $corrections.headwindPerKt,
                       range: -5...0, hint: "% pro kt (negativ = kürzer)")
            percentRow("Rückenwind", value: $corrections.tailwindPerKt,
                       range: 0...20, hint: "% pro kt")
            percentRow("Neigung", value: $corrections.slopePerPercent,
                       range: 0...30, hint: "% pro % Neigung")
            factorRow("Faktor Gras", value: $corrections.grassFactor)
            factorRow("Faktor nass", value: $corrections.wetFactor)
        }
    }

    private func newPoint() -> PerformanceDataPoint {
        // Reuse the last row's weight so adding a grid line stays quick.
        let weight = points.last?.weightKg ?? 0
        return PerformanceDataPoint(
            pressureAltitudeFt: 0,
            temperatureC: 15,
            weightKg: weight,
            groundRollM: isLanding ? 200 : 300,
            distanceOver50ftM: isLanding ? 450 : 500
        )
    }

    /// Edits a fractional factor as a percentage, which is how POHs express it.
    private func percentRow(
        _ title: LocalizedStringKey,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        hint: String
    ) -> some View {
        let percentBinding = Binding(
            get: { value.wrappedValue * 100 },
            set: { value.wrappedValue = ($0 / 100).clamped(to: range.lowerBound / 100...range.upperBound / 100) }
        )

        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                TextField(title, value: percentBinding, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("%")
                    .foregroundStyle(.secondary)
            }
            Text(hint)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func factorRow(_ title: LocalizedStringKey, value: Binding<Double>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, value: value, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text("×")
                .foregroundStyle(.secondary)
        }
    }
}

/// One editable grid point: its conditions and the two resulting distances.
struct PerformancePointRow: View {
    @Binding var point: PerformanceDataPoint

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                field("Höhe", value: $point.pressureAltitudeFt, unit: "ft")
                field("OAT", value: $point.temperatureC, unit: "°C", allowsNegative: true)
                field("Masse", value: $point.weightKg, unit: "kg")
            }
            HStack(spacing: 10) {
                field("Rollstrecke", value: $point.groundRollM, unit: "m")
                field("Über 50 ft", value: $point.distanceOver50ftM, unit: "m")
            }

            if point.distanceOver50ftM < point.groundRollM {
                Label("Die 50-ft-Strecke muss größer als die Rollstrecke sein.", systemImage: "exclamationmark.triangle")
                    .font(.caption2)
                    .foregroundStyle(Theme.caution)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 6)
    }

    private func field(
        _ title: LocalizedStringKey,
        value: Binding<Double>,
        unit: String,
        allowsNegative: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 3) {
                TextField(title, value: value, format: .number)
                    .keyboardType(allowsNegative ? .numbersAndPunctuation : .numberPad)
                    .textFieldStyle(.roundedBorder)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
