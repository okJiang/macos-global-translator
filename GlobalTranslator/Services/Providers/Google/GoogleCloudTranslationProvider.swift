import Foundation

struct GoogleCloudTranslationProvider: TranslationProvider {
    let descriptor = ProviderDescriptor(
        id: "google",
        displayName: "Google Cloud",
        credentialLabel: "API key",
        credentialPlaceholder: "Google Cloud API key",
        requiresStoredCredential: true,
        supportsCustomModel: false,
        defaultModel: nil
    )

    private let session: any HTTPClient
    private let endpoint: URL
    private let targetLanguageResolver: TargetLanguageResolver

    init(
        session: any HTTPClient = URLSession.shared,
        endpoint: URL = URL(string: "https://translation.googleapis.com/language/translate/v2")!,
        targetLanguageResolver: TargetLanguageResolver = TargetLanguageResolver()
    ) {
        self.session = session
        self.endpoint = endpoint
        self.targetLanguageResolver = targetLanguageResolver
    }

    func translate(
        _ request: TranslationRequest,
        credential: ProviderCredential?,
        preferences: ProviderPreferences
    ) async throws -> TranslationResponse {
        guard let credential else {
            throw URLError(.userAuthenticationRequired)
        }
        _ = preferences
        let targetLanguage = try targetLanguageResolver.resolve(request.targetLanguage, for: descriptor.id)
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "key", value: credential.apiKey)]
        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(
            GoogleTranslateRequest(text: request.text, target: targetLanguage)
        )

        let (data, response) = try await session.data(for: urlRequest)
        guard
            let httpResponse = response as? HTTPURLResponse,
            (200 ..< 300).contains(httpResponse.statusCode)
        else {
            throw URLError(.badServerResponse)
        }

        let payload = try JSONDecoder().decode(GoogleTranslateResponse.self, from: data)
        guard let translation = payload.data.translations.first, !translation.translatedText.isEmpty else {
            throw URLError(.cannotDecodeContentData)
        }

        return TranslationResponse(
            translatedText: translation.translatedText,
            detectedSourceLanguage: translation.detectedSourceLanguage
        )
    }
}

private struct GoogleTranslateRequest: Encodable {
    let q: String
    let target: String
    let format = "text"

    init(text: String, target: String) {
        q = text
        self.target = target
    }
}

private struct GoogleTranslateResponse: Decodable {
    struct Payload: Decodable {
        struct Translation: Decodable {
            let translatedText: String
            let detectedSourceLanguage: String?
        }

        let translations: [Translation]
    }

    let data: Payload
}
