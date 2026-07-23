import Foundation

/// The physical surface of a runway, affecting rolling resistance and
/// therefore take-off and landing distances.
enum RunwaySurface: String, Codable, Hashable, CaseIterable, Identifiable {
    case paved
    case grass

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .paved: "Asphalt / Beton"
        case .grass: "Gras"
        }
    }

    var shortName: String {
        switch self {
        case .paved: "Hart"
        case .grass: "Gras"
        }
    }
}

/// Whether the runway surface is dry or wet, which affects braking and
/// rolling performance (primarily on landing).
enum RunwayCondition: String, Codable, Hashable, CaseIterable, Identifiable {
    case dry
    case wet

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dry: "Trocken"
        case .wet: "Nass"
        }
    }
}
