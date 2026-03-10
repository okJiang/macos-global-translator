import Foundation

struct DeepLProvider: TranslationProvider {
    let descriptor = ProviderDescriptor(
        id: "deepl",
        displayName: "DeepL",
        credentialLabel: "API key",
        credentialPlaceholder: "DeepL API key",
        requiresStoredCredential: true,
        supportsCustomModel: false,
        defaultModel: nil
    )

    private let session: any HTTPClient
    private let proEndpoint: URL
    private let freeEndpoint: URL
    private let targetLanguageResolver: TargetLanguageResolver

    init(
        session: any HTTPClient = URLSession.shared,
        proEndpoint: URL = URL(string: "https://api.deepl.com/v2/translate")!,
        freeEndpoint: URL = URL(string: "https://api-free.deepl.com/v2/translate")!,
        targetLanguageResolver: TargetLanguageResolver = TargetLanguageResolver()
    ) {
        self.session = session
        self.proEndpoint = proEndpoint
        self.freeEndpoint = freeEndpoint
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
        var urlRequest = URLRequest(url: credential.apiKey.hasSuffix(":fx") ? freeEndpoint : proEndpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("DeepL-Auth-Key \(credential.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(
            DeepLTranslateRequest(text: [request.text], targetLanguage: targetLanguage)
        )

        let (data, response) = try await session.data(for: urlRequest)
        guard
            let httpResponse = response as? HTTPURLResponse,
            (200 ..< 300).contains(httpResponse.statusCode)
        else {
            throw URLError(.badServerResponse)
        }

        let payload = try JSONDecoder().decode(DeepLTranslateResponse.self, from: data)
        guard let translation = payload.translations.first, !translation.text.isEmpty else {
            throw URLError(.cannotDecodeContentData)
        }

        return TranslationResponse(
            translatedText: translation.text,
            detectedSourceLanguage: translation.detectedSourceLanguage
        )
    }
}

private struct DeepLTranslateRequest: Encodable {
    let text: [String]
    let targetLanguage: String

    enum CodingKeys: String, CodingKey {
        case text
        case targetLanguage = "target_lang"
    }
}

private struct DeepLTranslateResponse: Decodable {
    struct Translation: Decodable {
        let detectedSourceLanguage: String?
        let text: String

        enum CodingKeys: String, CodingKey {
            case detectedSourceLanguage = "detected_source_language"
            case text
        }
    }

    let translations: [Translation]
}
