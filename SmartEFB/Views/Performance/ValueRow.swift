import SwiftUI

/// A label-left / value-right row, the building block of the results panels.
///
/// Mirrors the layout of an airliner performance page — scannable at a glance,
/// with monospaced digits so numbers don't shift as they update.
struct ValueRow: View {
    let title: LocalizedStringKey
    let value: String
    var tint: Color = Theme.accent
    var isProminent: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(isProminent ? .subheadline.weight(.semibold) : .subheadline)
                .foregroundStyle(isProminent ? .primary : .secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(isProminent
                      ? .system(.title3, design: .rounded).weight(.bold)
                      : .system(.subheadline, design: .rounded).weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(tint)
                .contentTransition(.numericText())
                .lineLimit(1)
        }
        .padding(.vertical, isProminent ? 4 : 1)
    }
}
