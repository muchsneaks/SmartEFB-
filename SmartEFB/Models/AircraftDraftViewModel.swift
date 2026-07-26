import Foundation
import Observation

/// Drives the guided "create or edit an aircraft" flow, including the AI-assisted
/// import of performance charts from photographed POH pages.
@MainActor
@Observable
final class AircraftDraftViewModel {
    /// The state of the photo-analysis step.
    enum ImportState: Equatable {
        case idle
        /// First pass: reading the page.
        case extracting
        /// Second pass: the model reviewing and correcting its own reading.
        case refining
        case success
        case failed(String)

        var isBusy: Bool { self == .extracting || self == .refining }
    }

    // MARK: Identity

    var name = ""
    var registration = ""
    var icaoType = ""
    var propType: PropType = .fixedPitch

    // MARK: Weights

    var emptyWeightKg: Double = 500
    var maxTakeoffWeightKg: Double = 1000
    var defaultPlanningWeightKg: Double = 900

    // MARK: Performance charts

    var takeoffPoints: [PerformanceDataPoint] = []
    var landingPoints: [PerformanceDataPoint] = []
    var takeoffCorrections: PerformanceCorrections = .takeoffDefaults
    var landingCorrections: PerformanceCorrections = .landingDefaults
    var takeoffConfiguration: String?
    var landingConfiguration: String?

    var cruiseSettings: [CruiseSetting] = []
    var vSpeeds: VSpeeds?

    // MARK: Import status

    var importState: ImportState = .idle
    var importKind: POHTableKind = .takeoff
    var refineEnabled = true
    var warnings: [String] = []
    var confidence: Double?
    var verification: VerificationOutcome?

    /// The id of the aircraft being edited, or `nil` when creating a new one.
    private(set) var editingAircraftID: UUID?

    var isEditing: Bool { editingAircraftID != nil }

    // MARK: Init

    init() {}

    /// Pre-fills the draft from an existing aircraft so it can be corrected later.
    init(editing aircraft: Aircraft) {
        editingAircraftID = aircraft.id
        name = aircraft.name
        registration = aircraft.registration
        icaoType = aircraft.icaoType
        propType = aircraft.propType
        emptyWeightKg = aircraft.emptyWeightKg
        maxTakeoffWeightKg = aircraft.maxTakeoffWeightKg
        defaultPlanningWeightKg = aircraft.defaultPlanningWeightKg
        takeoffPoints = aircraft.takeoffTable?.points ?? []
        landingPoints = aircraft.landingTable?.points ?? []
        takeoffCorrections = aircraft.takeoffTable?.corrections ?? .takeoffDefaults
        landingCorrections = aircraft.landingTable?.corrections ?? .landingDefaults
        takeoffConfiguration = aircraft.takeoffTable?.configurationNote
        landingConfiguration = aircraft.landingTable?.configurationNote
        cruiseSettings = aircraft.cruiseSettings
        vSpeeds = aircraft.vSpeeds
    }

    // MARK: Derived state

    var hasAnyPerformanceData: Bool {
        !takeoffPoints.isEmpty || !landingPoints.isEmpty || !cruiseSettings.isEmpty
    }

    /// True when the draft has the minimum data needed to be saved.
    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && maxTakeoffWeightKg > emptyWeightKg
            && hasAnyPerformanceData
    }

    // MARK: - AI analysis

    /// Sends an image to OpenAI, optionally lets the model review its own reading,
    /// validates the result and merges it into the draft.
    func analyze(imageData: Data, mimeType: String, apiKey: String?, model: String) async {
        guard let apiKey, !apiKey.isEmpty else {
            importState = .failed(OpenAIClientError.missingAPIKey.errorDescription ?? "Kein API-Key")
            return
        }

        importState = .extracting
        warnings = []
        verification = nil

        let client = OpenAIClient(apiKey: apiKey, model: model)

        do {
            var extraction = try await client.extractPOH(
                imageData: imageData, mimeType: mimeType, kind: importKind
            )

            if refineEnabled {
                importState = .refining
                // A failed review pass must not discard a usable first reading.
                if let refined = try? await client.refinePOH(
                    imageData: imageData, mimeType: mimeType, kind: importKind, previous: extraction
                ) {
                    extraction = refined
                } else {
                    warnings.append("Der Prüfdurchgang der KI ist fehlgeschlagen – es werden die Werte des ersten Durchgangs verwendet.")
                }
            }

            apply(POHValidator.validate(extraction))
            importState = .success
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            importState = .failed(message)
        }
    }

    /// Merges a validated import result into the editable draft.
    private func apply(_ result: POHImportResult) {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let suggested = result.suggestedName {
            name = suggested
        }
        if let mtom = result.maxTakeoffWeightKg { maxTakeoffWeightKg = mtom }
        if let empty = result.emptyWeightKg { emptyWeightKg = empty }
        if defaultPlanningWeightKg > maxTakeoffWeightKg || defaultPlanningWeightKg < emptyWeightKg {
            defaultPlanningWeightKg = (emptyWeightKg + maxTakeoffWeightKg) / 2
        }

        if let table = result.takeoffTable {
            takeoffPoints = table.points
            takeoffCorrections = table.corrections
            takeoffConfiguration = table.configurationNote
        }
        if let table = result.landingTable {
            landingPoints = table.points
            landingCorrections = table.corrections
            landingConfiguration = table.configurationNote
        }
        if !result.cruiseSettings.isEmpty {
            cruiseSettings = result.cruiseSettings
            if result.cruiseSettings.contains(where: { $0.manifoldPressureInHg != nil }) {
                propType = .constantSpeed
            }
        }
        if let speeds = result.vSpeeds { vSpeeds = speeds }

        confidence = result.confidence
        verification = result.verification
        warnings.append(contentsOf: result.warnings)
    }

    // MARK: - Building

    /// Assembles the final aircraft from the draft.
    func buildAircraft() -> Aircraft {
        let trimmedType = icaoType.trimmingCharacters(in: .whitespacesAndNewlines)

        // Guard the range: a ClosedRange traps if its bounds are inverted, which
        // can happen while the pilot is still typing the weights.
        let weightBounds = min(emptyWeightKg, maxTakeoffWeightKg)...max(emptyWeightKg, maxTakeoffWeightKg)

        return Aircraft(
            id: editingAircraftID ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            registration: registration.trimmingCharacters(in: .whitespacesAndNewlines),
            icaoType: trimmedType.uppercased(),
            propType: propType,
            emptyWeightKg: emptyWeightKg,
            maxTakeoffWeightKg: maxTakeoffWeightKg,
            defaultPlanningWeightKg: defaultPlanningWeightKg.clamped(to: weightBounds),
            takeoffTable: takeoffPoints.isEmpty ? nil : PerformanceTable(
                points: takeoffPoints,
                corrections: takeoffCorrections,
                configurationNote: takeoffConfiguration
            ),
            landingTable: landingPoints.isEmpty ? nil : PerformanceTable(
                points: landingPoints,
                corrections: landingCorrections,
                configurationNote: landingConfiguration
            ),
            cruiseSettings: cruiseSettings,
            vSpeeds: vSpeeds
        )
    }
}
