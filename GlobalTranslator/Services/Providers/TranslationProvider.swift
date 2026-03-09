import Foundation

struct TranslationRequest: Equatable, Sendable {
    let text: String
    let targetLanguage: String
}

struct TranslationResponse: Equatable, Sendable {
    let translatedText: String
    let detectedSourceLanguage: String?
}

protocol TranslationProvider: Sendable {
    var id: String { get }
    var displayName: String { get }
    func translate(
        _ request: TranslationRequest,
        credential: ProviderCredential,
        preferences: ProviderPreferences
    ) async throws -> TranslationResponse
}
