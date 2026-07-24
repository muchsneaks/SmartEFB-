import Foundation

/// Which kind of POH table the user is importing, used to steer the prompt.
enum POHTableKind: String, CaseIterable, Identifiable, Sendable {
    case runway
    case cruise
    case both

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .runway: "Start- & Landestrecken"
        case .cruise: "Leistungseinstellungen (Cruise)"
        case .both: "Beides / gemischt"
        }
    }
}

/// The raw JSON structure returned by the vision model.
///
/// Every field is optional so that partial or noisy responses still decode; the
/// values are cleaned and range-checked afterwards by ``POHValidator``.
struct POHExtraction: Decodable, Sendable {
    var aircraftName: String?
    var takeoff: RunwayPerformanceDTO?
    var landing: RunwayPerformanceDTO?
    var cruiseSettings: [CruiseSettingDTO]?
    var vSpeeds: VSpeedsDTO?
    var confidence: Double?
    var warnings: [String]?
    var notes: String?

    struct RunwayPerformanceDTO: Decodable, Sendable {
        var groundRollM: Double?
        var distanceOver50ftM: Double?
    }

    struct CruiseSettingDTO: Decodable, Sendable {
        var pressureAltitudeFt: Double?
        var rpm: Double?
        var manifoldPressureInHg: Double?
        var percentPower: Double?
        var trueAirspeedKt: Double?
        var fuelFlowLph: Double?
    }

    struct VSpeedsDTO: Decodable, Sendable {
        var rotateKt: Double?
        var bestRateOfClimbKt: Double?
        var bestAngleOfClimbKt: Double?
        var approachKt: Double?
        var stallLandingKt: Double?
        var neverExceedKt: Double?
    }
}
