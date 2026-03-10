import XCTest
@testable import GlobalTranslatorApp

final class ProviderRegistryTests: XCTestCase {
    func testAvailableProvidersExposeMetadataForBuiltInProviders() throws {
        let registry = ProviderRegistry()
        let providers = registry.availableProviders

        XCTAssertEqual(providers.map(\.id), ["deepl", "copilot", "google", "openai"])

        let deepl = try XCTUnwrap(providers.first(where: { $0.id == "deepl" }))
        XCTAssertEqual(deepl.displayName, "DeepL")
        XCTAssertEqual(deepl.credentialLabel, "API key")
        XCTAssertEqual(deepl.credentialPlaceholder, "DeepL API key")
        XCTAssertTrue(deepl.requiresStoredCredential)
        XCTAssertFalse(deepl.supportsCustomModel)
        XCTAssertNil(deepl.defaultModel)

        let copilot = try XCTUnwrap(providers.first(where: { $0.id == "copilot" }))
        XCTAssertEqual(copilot.displayName, "GitHub Copilot")
        XCTAssertEqual(copilot.credentialPlaceholder, "")
        XCTAssertFalse(copilot.requiresStoredCredential)
        XCTAssertTrue(copilot.supportsCustomModel)
        XCTAssertNil(copilot.defaultModel)

        let google = try XCTUnwrap(providers.first(where: { $0.id == "google" }))
        XCTAssertEqual(google.displayName, "Google Cloud")
        XCTAssertEqual(google.credentialPlaceholder, "Google Cloud API key")
        XCTAssertTrue(google.requiresStoredCredential)
        XCTAssertFalse(google.supportsCustomModel)
        XCTAssertNil(google.defaultModel)

        let openAI = try XCTUnwrap(providers.first(where: { $0.id == "openai" }))
        XCTAssertEqual(openAI.displayName, "OpenAI")
        XCTAssertEqual(openAI.credentialPlaceholder, "OpenAI API key")
        XCTAssertTrue(openAI.requiresStoredCredential)
        XCTAssertTrue(openAI.supportsCustomModel)
        XCTAssertEqual(openAI.defaultModel, "gpt-4.1-mini")
    }
}
