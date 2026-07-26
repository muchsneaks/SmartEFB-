import Foundation

/// Which chart the pilot is importing, used to steer the prompt.
enum POHTableKind: String, CaseIterable, Identifiable, Sendable, Codable {
    case takeoff
    case landing
    case cruise
    case auto

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .takeoff: "Startstrecke"
        case .landing: "Landestrecke"
        case .cruise: "Cruise / Leistung"
        case .auto: "Automatisch erkennen"
        }
    }

    var systemImage: String {
        switch self {
        case .takeoff: "airplane.departure"
        case .landing: "airplane.arrival"
        case .cruise: "gauge.with.dots.needle.67percent"
        case .auto: "wand.and.stars"
        }
    }
}

/// The raw JSON structure returned by the vision model.
///
/// Every field is optional so partial or noisy responses still decode; values are
/// cleaned, range-checked and cross-verified afterwards by ``POHValidator``.
struct POHExtraction: Codable, Sendable {
    var aircraftName: String?
    var maxTakeoffWeightKg: Double?
    var emptyWeightKg: Double?

    /// Whether the source was a printed table or a nomogram / carpet chart.
    var sourceKind: String?

    /// Sampled grid of the take-off chart.
    var takeoffPoints: [PointDTO]?

    /// Sampled grid of the landing chart.
    var landingPoints: [PointDTO]?

    var takeoffCorrections: CorrectionsDTO?
    var landingCorrections: CorrectionsDTO?

    var takeoffConfiguration: String?
    var landingConfiguration: String?

    var cruiseSettings: [CruiseSettingDTO]?
    var vSpeeds: VSpeedsDTO?

    /// The worked example printed on the POH page, used to self-check the
    /// extracted grid.
    var verification: VerificationDTO?

    var confidence: Double?
    var warnings: [String]?
    var notes: String?

    struct PointDTO: Codable, Sendable {
        var pressureAltitudeFt: Double?
        var temperatureC: Double?
        var weightKg: Double?
        var groundRollM: Double?
        var distanceOver50ftM: Double?
    }

    struct CorrectionsDTO: Codable, Sendable {
        var headwindPercentPerKt: Double?
        var tailwindPercentPerKt: Double?
        var grassFactor: Double?
        var wetFactor: Double?
        var slopePercentPerPercent: Double?
    }

    struct CruiseSettingDTO: Codable, Sendable {
        var pressureAltitudeFt: Double?
        var rpm: Double?
        var manifoldPressureInHg: Double?
        var percentPower: Double?
        var trueAirspeedKt: Double?
        var fuelFlowLph: Double?
    }

    struct VSpeedsDTO: Codable, Sendable {
        var rotateKt: Double?
        var bestRateOfClimbKt: Double?
        var bestAngleOfClimbKt: Double?
        var approachKt: Double?
        var stallLandingKt: Double?
        var neverExceedKt: Double?
    }

    struct VerificationDTO: Codable, Sendable {
        var isTakeoff: Bool?
        var pressureAltitudeFt: Double?
        var temperatureC: Double?
        var weightKg: Double?
        var headwindKt: Double?
        var expectedGroundRollM: Double?
        var expectedDistanceOver50ftM: Double?
    }
}
