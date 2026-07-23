import SwiftUI

/// Central design tokens for SmartEFB.
///
/// The palette is intentionally high-contrast and dark-first so the app stays
/// legible in a bright cockpit, and the control sizes are generous so the app
/// remains operable in turbulence.
enum Theme {
    // MARK: Colours

    /// Primary brand / accent colour (aviation blue).
    static let accent = Color(red: 0.16, green: 0.55, blue: 0.98)

    /// Positive / within-limits colour.
    static let positive = Color(red: 0.20, green: 0.78, blue: 0.45)

    /// Caution colour.
    static let caution = Color(red: 0.98, green: 0.72, blue: 0.16)

    /// Warning / out-of-limits colour.
    static let warning = Color(red: 0.95, green: 0.29, blue: 0.29)

    /// App background — near-black for cockpit legibility.
    static let background = Color(red: 0.06, green: 0.07, blue: 0.09)

    // MARK: Layout

    /// Minimum tap target for turbulence-friendly controls.
    static let controlSize: CGFloat = 56

    /// Standard corner radius for cards and controls.
    static let cornerRadius: CGFloat = 16
}
