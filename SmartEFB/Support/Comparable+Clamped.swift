import Foundation

extension Comparable {
    /// Clamps the value into a closed range.
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
