import Foundation

/// The ordered steps of the guided aircraft-creation flow.
enum WizardStep: Int, CaseIterable, Identifiable {
    case identity
    case weights
    case performance
    case review
    case summary

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .identity: "Basisdaten"
        case .weights: "Massen"
        case .performance: "Leistungsdaten"
        case .review: "Prüfen"
        case .summary: "Fertig"
        }
    }

    var subtitle: String {
        switch self {
        case .identity: "Wie heißt dein Flugzeug und welchen Antrieb hat es?"
        case .weights: "Leermasse und maximale Startmasse eintragen."
        case .performance: "POH-Tabelle fotografieren – die KI liest die Werte aus."
        case .review: "Erkannte Werte kontrollieren und bei Bedarf korrigieren."
        case .summary: "Alles bereit. Zum Abschluss speichern."
        }
    }

    var systemImage: String {
        switch self {
        case .identity: "airplane"
        case .weights: "scalemass"
        case .performance: "sparkles"
        case .review: "checklist"
        case .summary: "checkmark.seal"
        }
    }

    var previous: WizardStep? {
        WizardStep(rawValue: rawValue - 1)
    }

    var next: WizardStep? {
        WizardStep(rawValue: rawValue + 1)
    }
}
