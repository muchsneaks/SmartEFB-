import Foundation
import Observation

/// Drives the "create a new aircraft" flow, including the AI-assisted import of
/// performance data from a photographed POH table.
@MainActor
@Observable
final class AircraftDraftViewModel {
    /// The state of the photo-analysis step.
    enum ImportState: Equatable {
        case idle
        case analyzing
        case success
        case failed(String)
    }

    // MARK: Basic data

    var name: String = ""
    var registration: String = ""
    var icaoType: String = ""
    var propType: PropType = .fixedPitch

    var emptyWeightKg: Double = 500
    var maxTakeoffWeightKg: Double = 1000
    var defaultPlanningWeightKg: Double = 900

    // MARK: Imported / editable performance data

    var hasTakeoff = false
    var takeoff = RunwayPerformance(groundRollM: 0, distanceOver50ftM: 0)

    var hasLanding = false
    var landing = RunwayPerformance(groundRollM: 0, distanceOver50ftM: 0)

    var cruiseSettings: [CruiseSetting] = []
    var vSpeeds = VSpeeds(rotateKt: 0, bestRateOfClimbKt: 0, bestAngleOfClimbKt: 0, approachKt: 0, stallLandingKt: 0, neverExceedKt: 0)
    var hasVSpeeds = false

    // MARK: Import status

    var importState: ImportState = .idle
    var importKind: POHTableKind = .both
    var warnings: [String] = []
    var confidence: Double?
    var hasImportedData = false

    /// The id of the aircraft being edited, or `nil` when creating a new one.
    private(set) var editingAircraftID: UUID? = nil

    /// Whether the flow is editing an existing aircraft.
    var isEditing: Bool { editingAircraftID != nil }

    // MARK: Init

    init() {}

    /// Pre-fills the draft from an existing aircraft for later correction.
    init(editing aircraft: Aircraft) {
        editingAircraftID = aircraft.id
        name = aircraft.name
        registration = aircraft.registration
        icaoType = aircraft.icaoType == "USER" ? "" : aircraft.icaoType
        propType = aircraft.propType
        emptyWeightKg = aircraft.emptyWeightKg
        maxTakeoffWeightKg = aircraft.maxTakeoffWeightKg
        defaultPlanningWeightKg = aircraft.defaultPlanningWeightKg
        takeoff = aircraft.takeoff
        hasTakeoff = true
        landing = aircraft.landing
        hasLanding = true
        cruiseSettings = aircraft.cruiseSettings
        vSpeeds = aircraft.vSpeeds
        hasVSpeeds = true
        hasImportedData = true
    }

    /// True when the draft has the minimum data needed to be saved.
    var canSave: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasPerformance = hasTakeoff || hasLanding || !cruiseSettings.isEmpty
        return !trimmed.isEmpty
            && maxTakeoffWeightKg > emptyWeightKg
            && hasPerformance
    }

    // MARK: - AI analysis

    /// Sends an image to OpenAI, validates the result and fills the draft.
    func analyze(imageData: Data, mimeType: String, apiKey: String?) async {
        guard let apiKey, !apiKey.isEmpty else {
            importState = .failed(OpenAIClientError.missingAPIKey.errorDescription ?? "Kein API-Key")
            return
        }

        importState = .analyzing
        warnings = []

        let client = OpenAIClient(apiKey: apiKey)
        do {
            let extraction = try await client.extractPOH(imageData: imageData, mimeType: mimeType, kind: importKind)
            let result = POHValidator.validate(extraction)
            apply(result)
            importState = .success
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            importState = .failed(message)
        }
    }

    /// Merges a validated import result into the editable draft.
    private func apply(_ result: POHImportResult) {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let suggested = result.suggestedName {
            name = suggested
        }

        if let takeoff = result.takeoff {
            self.takeoff = takeoff
            hasTakeoff = true
        }
        if let landing = result.landing {
            self.landing = landing
            hasLanding = true
        }
        if !result.cruiseSettings.isEmpty {
            cruiseSettings = result.cruiseSettings
            if result.cruiseSettings.contains(where: { $0.manifoldPressureInHg != nil }) {
                propType = .constantSpeed
            }
        }
        if let speeds = result.vSpeeds {
            vSpeeds = speeds
            hasVSpeeds = true
        }

        confidence = result.confidence
        warnings = result.warnings
        hasImportedData = !result.isEmpty
    }

    // MARK: - Building

    /// Assembles the final aircraft from the draft.
    func buildAircraft() -> Aircraft {
        let trimmedType = icaoType.trimmingCharacters(in: .whitespacesAndNewlines)
        return Aircraft(
            id: editingAircraftID ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            registration: registration.trimmingCharacters(in: .whitespacesAndNewlines),
            icaoType: trimmedType.isEmpty ? "USER" : trimmedType.uppercased(),
            symbolName: "airplane",
            imageName: nil,
            isCustom: true,
            propType: propType,
            emptyWeightKg: emptyWeightKg,
            maxTakeoffWeightKg: maxTakeoffWeightKg,
            defaultPlanningWeightKg: min(max(defaultPlanningWeightKg, emptyWeightKg), maxTakeoffWeightKg),
            takeoff: hasTakeoff ? takeoff : RunwayPerformance(groundRollM: 300, distanceOver50ftM: 500),
            landing: hasLanding ? landing : RunwayPerformance(groundRollM: 200, distanceOver50ftM: 450),
            surfaceFactors: .standard,
            cruiseSettings: cruiseSettings,
            vSpeeds: hasVSpeeds ? vSpeeds : VSpeeds(rotateKt: 55, bestRateOfClimbKt: 74, bestAngleOfClimbKt: 62, approachKt: 65, stallLandingKt: 45, neverExceedKt: 160)
        )
    }
}
