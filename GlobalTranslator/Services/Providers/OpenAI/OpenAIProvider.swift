import Foundation

struct OpenAIProvider: TranslationProvider {
    let descriptor = ProviderDescriptor(
        id: "openai",
        displayName: "OpenAI",
        credentialLabel: "API key",
        credentialPlaceholder: "OpenAI API key",
        supportsCustomModel: true,
        defaultModel: "gpt-4.1-mini"
    )

    private let session: any HTTPClient
    private let endpoint: URL

    init(
        session: any HTTPClient = URLSession.shared,
        endpoint: URL = URL(string: "https://api.openai.com/v1/chat/completions")!
    ) {
        self.session = session
        self.endpoint = endpoint
    }

    func translate(
        _ request: TranslationRequest,
        credential: ProviderCredential,
        preferences: ProviderPreferences
    ) async throws -> TranslationResponse {
        guard let model = preferences.model ?? descriptor.defaultModel else {
            throw URLError(.userAuthenticationRequired)
        }

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(credential.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(
            ChatCompletionRequest(
                model: model,
                messages: [
                    .init(
                        role: "system",
                        content: "Translate the provided text into \(request.targetLanguage). Return only the translated text."
                    ),
                    .init(role: "user", content: request.text),
                ]
            )
        )

        let (data, response) = try await session.data(for: urlRequest)
        guard
            let httpResponse = response as? HTTPURLResponse,
            (200 ..< 300).contains(httpResponse.statusCode)
        else {
            throw URLError(.badServerResponse)
        }

        let payload = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let translatedText = payload.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines), !translatedText.isEmpty else {
            throw URLError(.cannotDecodeContentData)
        }

        return TranslationResponse(translatedText: translatedText, detectedSourceLanguage: "auto")
    }
}

private struct ChatCompletionRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let messages: [Message]
}

private struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }

        let message: Message
    }

    let choices: [Choice]
}
