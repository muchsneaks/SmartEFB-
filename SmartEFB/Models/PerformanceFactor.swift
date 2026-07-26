import Foundation

/// One named contribution to the corrected distance, so the pilot can see *why*
/// the required distance differs from the raw chart value.
///
/// This is the app's equivalent of the "Limitation" field on an airliner's
/// performance page: it names the dominant influence instead of only showing the
/// final number.
struct PerformanceFactor: Hashable, Sendable, Identifiable {
    var name: String
    var multiplier: Double

    var id: String { name }

    /// Change relative to the chart value, in percent (positive = longer).
    var percentChange: Double { (multiplier - 1) * 100 }

    var isPenalty: Bool { multiplier > 1.0005 }
    var isBenefit: Bool { multiplier < 0.9995 }
    var isNeutral: Bool { !isPenalty && !isBenefit }
}
