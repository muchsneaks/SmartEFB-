import Foundation

/// Whether the performance screen is computing a take-off or a landing.
enum PerformanceMode: String, CaseIterable, Identifiable {
    case takeoff
    case landing

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .takeoff: "Start"
        case .landing: "Landung"
        }
    }

    var symbolName: String {
        switch self {
        case .takeoff: "airplane.departure"
        case .landing: "airplane.arrival"
        }
    }
}
