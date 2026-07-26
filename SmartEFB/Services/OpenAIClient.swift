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
            "Die Antwort konnte nicht gelesen werden. Bitte mit einem schärferen Foto erneut versuchen."
        }
    }
}

/// Reads performance data out of a photographed POH page — printed table or
/// nomogram — using OpenAI's vision-capable chat completions endpoint.
struct OpenAIClient: Sendable {
    var apiKey: String
    var model: String

    /// A safe, valid endpoint URL.
    private var endpoint: URL {
        URL(string: "https://api.openai.com/v1/chat/completions") ?? URL(filePath: "/")
    }

    /// First pass: read the page and return the extracted grid.
    func extractPOH(imageData: Data, mimeType: String, kind: POHTableKind) async throws -> POHExtraction {
        let messages = [
            ChatRequest.Message(role: "system", content: [.text(Self.systemPrompt)]),
            ChatRequest.Message(role: "user", content: [
                .text(Self.extractionPrompt(for: kind)),
                .imageURL(Self.dataURL(imageData: imageData, mimeType: mimeType))
            ])
        ]
        return try await send(messages: messages)
    }

    /// Second pass: show the model its own output next to the image and ask it to
    /// correct any misread value and re-check the worked example.
    ///
    /// Reading a nomogram by eye is error-prone, so this review step measurably
    /// improves the numbers before the pilot ever sees them.
    func refinePOH(
        imageData: Data,
        mimeType: String,
        kind: POHTableKind,
        previous: POHExtraction
    ) async throws -> POHExtraction {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let previousJSON = (try? encoder.encode(previous))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"

        let messages = [
            ChatRequest.Message(role: "system", content: [.text(Self.systemPrompt)]),
            ChatRequest.Message(role: "user", content: [
                .text(Self.refinementPrompt(for: kind, previousJSON: previousJSON)),
                .imageURL(Self.dataURL(imageData: imageData, mimeType: mimeType))
            ])
        ]
        return try await send(messages: messages)
    }

    // MARK: - Transport

    private func send(messages: [ChatRequest.Message]) async throws -> POHExtraction {
        guard !apiKey.isEmpty else { throw OpenAIClientError.missingAPIKey }

        // Neither `temperature` nor `max_tokens` is sent: several newer OpenAI
        // models reject them, and omitting both keeps the client usable with
        // whichever model the pilot selects.
        let request = ChatRequest(model: model, messages: messages, responseFormat: .init())

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        urlRequest.timeoutInterval = 180

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

    private static func dataURL(imageData: Data, mimeType: String) -> String {
        "data:\(mimeType);base64,\(imageData.base64EncodedString())"
    }

    // MARK: - Prompts

    private static let systemPrompt = """
    You are an expert aviation performance engineer who transcribes aircraft \
    Pilot's Operating Handbook (POH) performance data from photographs into \
    structured JSON.

    ABSOLUTE RULES
    - Output ONLY a single JSON object. No prose, no markdown fences.
    - Never invent a number. If you cannot read a value with confidence, use null \
      and say so in "warnings".
    - Units in the output are fixed: distances in METRES, mass in KILOGRAMS, \
      speeds in KNOTS, fuel flow in LITRES PER HOUR, altitude in FEET, \
      temperature in CELSIUS, manifold pressure in INHG. POH axes often carry two \
      scales (°F and °C, lbs and kg, ft and m) — read the metric scale where it \
      exists, otherwise convert and record the conversion in "warnings" \
      (1 ft = 0.3048 m, 1 lb = 0.45359 kg).

    HOW TO READ A NOMOGRAM (carpet / grid chart)
    Many POHs give take-off and landing performance as a multi-panel graph rather \
    than a table. Read every sample point by tracing the panels left to right:
    1. Enter the leftmost panel at the outside air temperature on its bottom axis.
    2. Move vertically to the curve for the desired PRESSURE ALTITUDE (curves are \
       labelled S.L., 2000 ft, 4000 ft, …).
    3. Move horizontally right to the reference line that starts the WEIGHT panel.
    4. Follow the panel's sloping guide lines until you reach the desired weight \
       on its axis, then continue horizontally.
    5. At the WIND panel, follow the guide lines to the headwind component. For \
       the sampled grid ALWAYS use 0 kt — the app applies wind itself.
    6. At the OBSTACLE panel, the 0 m (0 ft) line yields the GROUND ROLL and the \
       15 m (50 ft) line the DISTANCE OVER THE OBSTACLE.
    7. Read both distances off the right-hand distance axis.
    If the page prints a worked Example with a Result, trace it first and confirm \
    you reproduce the printed numbers; this calibrates how you read the panels.

    SAMPLING THE GRID
    Return one entry per (pressure altitude, temperature, weight) combination that \
    you can actually read, at 0 kt wind:
    - pressure altitudes: 0, 2000, 4000, 6000, 8000 ft (skip any beyond the chart)
    - temperatures: -20, 0, 10, 20, 30, 40 °C (skip any beyond the chart)
    - weights: the maximum take-off mass AND the lowest mass on the chart; add an \
      intermediate mass if the chart supports it
    For a printed table, transcribe its cells directly instead of resampling, \
    keeping the table's own altitudes, temperatures and weights.

    CORRECTION FACTORS
    Fill "takeoffCorrections" / "landingCorrections" from the notes under the \
    chart. If the chart has a wind panel instead of a note, derive \
    "headwindPercentPerKt" from it: read the distance over the obstacle at 0 kt \
    and at the highest headwind shown for a mid-range condition, then express the \
    average change as a NEGATIVE percent per knot. Leave a field null when the POH \
    gives no basis for it.

    CONFIDENCE
    "confidence" is your honest overall confidence from 0 to 1. Lower it for blurry \
    images, cramped axes or heavy interpolation. List every assumption, unit \
    conversion and unreadable region in "warnings".
    """

    private static let jsonSchemaDescription = """
    {
      "aircraftName": string | null,
      "maxTakeoffWeightKg": number | null,
      "emptyWeightKg": number | null,
      "sourceKind": "table" | "graph",
      "takeoffPoints": [ { "pressureAltitudeFt": number, "temperatureC": number,
                           "weightKg": number, "groundRollM": number,
                           "distanceOver50ftM": number } ] | null,
      "landingPoints":  [ { same shape as takeoffPoints } ] | null,
      "takeoffCorrections": { "headwindPercentPerKt": number|null,
                              "tailwindPercentPerKt": number|null,
                              "grassFactor": number|null, "wetFactor": number|null,
                              "slopePercentPerPercent": number|null } | null,
      "landingCorrections": { same shape as takeoffCorrections } | null,
      "takeoffConfiguration": string | null,
      "landingConfiguration": string | null,
      "cruiseSettings": [ { "pressureAltitudeFt": number, "rpm": number|null,
                            "manifoldPressureInHg": number|null,
                            "percentPower": number|null, "trueAirspeedKt": number|null,
                            "fuelFlowLph": number|null } ] | null,
      "vSpeeds": { "rotateKt": number|null, "bestRateOfClimbKt": number|null,
                   "bestAngleOfClimbKt": number|null, "approachKt": number|null,
                   "stallLandingKt": number|null, "neverExceedKt": number|null } | null,
      "verification": { "isTakeoff": boolean, "pressureAltitudeFt": number,
                        "temperatureC": number, "weightKg": number,
                        "headwindKt": number, "expectedGroundRollM": number,
                        "expectedDistanceOver50ftM": number } | null,
      "confidence": number,
      "warnings": [string],
      "notes": string | null
    }
    """

    private static func focus(for kind: POHTableKind) -> String {
        switch kind {
        case .takeoff:
            "This page is a TAKE-OFF distance chart. Fill takeoffPoints and takeoffCorrections; leave landing and cruise null."
        case .landing:
            "This page is a LANDING distance chart. Fill landingPoints and landingCorrections; leave take-off and cruise null."
        case .cruise:
            "This page is a CRUISE / power-setting table. Fill cruiseSettings; leave the runway charts null."
        case .auto:
            "Decide for yourself what this page contains and fill only the matching fields."
        }
    }

    private static func extractionPrompt(for kind: POHTableKind) -> String {
        """
        \(focus(for: kind))

        Transcribe the page into exactly this JSON shape (null where unknown):
        \(jsonSchemaDescription)

        If the page prints a worked Example with a Result, copy its inputs and its \
        printed result into "verification" — the app cross-checks your grid against it.
        """
    }

    private static func refinementPrompt(for kind: POHTableKind, previousJSON: String) -> String {
        """
        \(focus(for: kind))

        A first pass over this same image produced the JSON below. Review it \
        critically against the image:

        \(previousJSON)

        Do all of the following, then return the corrected JSON in the identical shape:
        - Re-trace several sample points on the chart and fix every value that is wrong.
        - Check that distances rise with pressure altitude, with temperature and with \
          weight; investigate and fix any point that breaks that pattern.
        - Confirm "distanceOver50ftM" always exceeds "groundRollM".
        - Re-trace the printed worked Example and make sure "verification" matches the \
          printed result exactly.
        - Re-check every unit: metres, kilograms, knots, feet, Celsius.
        - Set "confidence" to reflect the reviewed state and describe what you changed \
          in "warnings".

        Return ONLY the corrected JSON object:
        \(jsonSchemaDescription)
        """
    }

    // MARK: - Wire types

    private struct ChatRequest: Encodable {
        let model: String
        let messages: [Message]
        let responseFormat: ResponseFormat

        enum CodingKeys: String, CodingKey {
            case model, messages
            case responseFormat = "response_format"
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
                    // "high" detail is essential: chart axes are unreadable otherwise.
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
