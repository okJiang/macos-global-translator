import Foundation

struct ProviderDescriptor: Equatable, Sendable, Identifiable {
    let id: String
    let displayName: String
    let credentialLabel: String
    let credentialPlaceholder: String
    let supportsCustomModel: Bool
    let defaultModel: String?
}

struct TranslationRequest: Equatable, Sendable {
    let text: String
    let targetLanguage: String
}

struct TranslationResponse: Equatable, Sendable {
    let translatedText: String
    let detectedSourceLanguage: String?
}

protocol TranslationProvider: Sendable {
    var descriptor: ProviderDescriptor { get }
    func translate(
        _ request: TranslationRequest,
        credential: ProviderCredential,
        preferences: ProviderPreferences
    ) async throws -> TranslationResponse
}

extension TranslationProvider {
    var id: String { descriptor.id }
    var displayName: String { descriptor.displayName }
}
