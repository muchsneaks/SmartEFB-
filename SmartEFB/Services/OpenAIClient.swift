import Foundation

/// Errors surfaced by ``OpenAIClient`` in a form suitable for display.
enum OpenAIClientError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case api(String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "Kein OpenAI-API-Key hinterlegt. Bitte in den Einstellungen eintragen."
        case .invalidResponse:
            "Unerwartete Antwort vom Server."
        case .api(let message):
            "OpenAI-Fehler: \(message)"
        case .decoding:
            "Die Antwort konnte nicht gelesen werden. Bitte mit einem klareren Foto erneut versuchen."
        }
    }
}

/// A small client for OpenAI's vision-capable chat completions endpoint, used to
/// read performance figures from a photographed POH table.
struct OpenAIClient: Sendable {
    var apiKey: String
    var model: String = "gpt-4o"

    private var endpoint: URL {
        // Safe: a compile-time constant, valid URL.
        URL(string: "https://api.openai.com/v1/chat/completions") ?? URL(filePath: "/")
    }

    /// Sends the image to the model and decodes the extracted POH data.
    func extractPOH(imageData: Data, mimeType: String, kind: POHTableKind) async throws -> POHExtraction {
        guard !apiKey.isEmpty else { throw OpenAIClientError.missingAPIKey }

        let base64 = imageData.base64EncodedString()
        let dataURL = "data:\(mimeType);base64,\(base64)"

        let request = ChatRequest(
            model: model,
            messages: [
                ChatRequest.Message(role: "system", content: [.text(Self.systemPrompt)]),
                ChatRequest.Message(role: "user", content: [
                    .text(Self.userPrompt(for: kind)),
                    .imageURL(dataURL)
                ])
            ],
            responseFormat: .init(),
            maxTokens: 2000,
            temperature: 0
        )

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        urlRequest.timeoutInterval = 90

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse else {
            throw OpenAIClientError.invalidResponse
        }

        guard http.statusCode == 200 else {
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw OpenAIClientError.api(apiError.error.message)
            }
            throw OpenAIClientError.api("HTTP \(http.statusCode)")
        }

        guard let chat = try? JSONDecoder().decode(ChatResponse.self, from: data),
              let content = chat.choices.first?.message.content,
              let contentData = content.data(using: .utf8) else {
            throw OpenAIClientError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(POHExtraction.self, from: contentData)
        } catch {
            throw OpenAIClientError.decoding
        }
    }

    // MARK: - Prompts

    private static let systemPrompt = """
    You are an expert aviation flight-performance data extractor. You read a \
    photograph of a page from an aircraft's Pilot's Operating Handbook (POH) and \
    return the performance figures as strict JSON.

    Rules:
    - Output ONLY a JSON object, no prose, matching the schema the user describes.
    - Read only values actually visible in the image. Never invent numbers. Use \
    null for anything you cannot read with confidence.
    - Convert all units to: distances in metres, weights in kilograms, speeds in \
    knots, fuel flow in litres per hour, altitude in feet, temperature in Celsius, \
    manifold pressure in inches of mercury (inHg). Note every conversion you make \
    in the "warnings" array.
    - For take-off and landing, extract the single REFERENCE cell: sea-level \
    pressure altitude, +15 °C (ISA), maximum take-off weight, no wind, level, dry, \
    paved runway. "groundRollM" is the ground roll; "distanceOver50ftM" is the \
    total distance to clear a 50 ft (15 m) obstacle. If the reference cell is not \
    present, pick the closest and add a warning describing what you used.
    - For cruise, extract one entry per row of the power table with its pressure \
    altitude, RPM, manifold pressure (null for fixed-pitch engines), percent power, \
    true airspeed and fuel flow.
    - "confidence" is your overall confidence from 0 to 1. Add a "warnings" entry \
    for anything ambiguous, low quality, unit-converted or assumed.
    """

    private static func userPrompt(for kind: POHTableKind) -> String {
        let focus: String
        switch kind {
        case .runway:
            focus = "This image is primarily a TAKE-OFF and/or LANDING distance table. Focus on those; cruise data may be null."
        case .cruise:
            focus = "This image is primarily a CRUISE / power-setting table. Focus on cruiseSettings; take-off/landing may be null."
        case .both:
            focus = "This image may contain take-off/landing and/or cruise data. Extract whatever is present."
        }

        return """
        \(focus)

        Return JSON exactly in this shape (use null where unknown):
        {
          "aircraftName": string | null,
          "takeoff": { "groundRollM": number|null, "distanceOver50ftM": number|null } | null,
          "landing": { "groundRollM": number|null, "distanceOver50ftM": number|null } | null,
          "cruiseSettings": [
            { "pressureAltitudeFt": number, "rpm": number|null, "manifoldPressureInHg": number|null,
              "percentPower": number|null, "trueAirspeedKt": number|null, "fuelFlowLph": number|null }
          ] | null,
          "vSpeeds": {
            "rotateKt": number|null, "bestRateOfClimbKt": number|null, "bestAngleOfClimbKt": number|null,
            "approachKt": number|null, "stallLandingKt": number|null, "neverExceedKt": number|null
          } | null,
          "confidence": number,
          "warnings": [string],
          "notes": string | null
        }
        """
    }

    // MARK: - Wire types

    private struct ChatRequest: Encodable {
        let model: String
        let messages: [Message]
        let responseFormat: ResponseFormat
        let maxTokens: Int
        let temperature: Double

        enum CodingKeys: String, CodingKey {
            case model, messages, temperature
            case responseFormat = "response_format"
            case maxTokens = "max_tokens"
        }

        struct ResponseFormat: Encodable {
            let type = "json_object"
        }

        struct Message: Encodable {
            let role: String
            let content: [ContentPart]
        }

        enum ContentPart: Encodable {
            case text(String)
            case imageURL(String)

            enum CodingKeys: String, CodingKey {
                case type, text
                case imageURL = "image_url"
            }

            enum ImageKeys: String, CodingKey {
                case url, detail
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                case .text(let value):
                    try container.encode("text", forKey: .type)
                    try container.encode(value, forKey: .text)
                case .imageURL(let url):
                    try container.encode("image_url", forKey: .type)
                    var image = container.nestedContainer(keyedBy: ImageKeys.self, forKey: .imageURL)
                    try image.encode(url, forKey: .url)
                    try image.encode("high", forKey: .detail)
                }
            }
        }
    }

    private struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable { let content: String }
            let message: Message
        }
        let choices: [Choice]
    }

    private struct APIErrorResponse: Decodable {
        struct APIError: Decodable { let message: String }
        let error: APIError
    }
}
