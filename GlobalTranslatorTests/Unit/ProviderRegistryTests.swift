import XCTest
@testable import GlobalTranslatorApp

final class ProviderRegistryTests: XCTestCase {
    func testAvailableProvidersExposeMetadataForBuiltInProviders() throws {
        let registry = ProviderRegistry()
        let providers = registry.availableProviders

        XCTAssertEqual(providers.map(\.id), ["deepl", "google", "openai"])

        let deepl = try XCTUnwrap(providers.first(where: { $0.id == "deepl" }))
        XCTAssertEqual(deepl.displayName, "DeepL")
        XCTAssertEqual(deepl.credentialLabel, "API key")
        XCTAssertEqual(deepl.credentialPlaceholder, "DeepL API key")
        XCTAssertFalse(deepl.supportsCustomModel)
        XCTAssertNil(deepl.defaultModel)

        let google = try XCTUnwrap(providers.first(where: { $0.id == "google" }))
        XCTAssertEqual(google.displayName, "Google Cloud")
        XCTAssertEqual(google.credentialPlaceholder, "Google Cloud API key")
        XCTAssertFalse(google.supportsCustomModel)
        XCTAssertNil(google.defaultModel)

        let openAI = try XCTUnwrap(providers.first(where: { $0.id == "openai" }))
        XCTAssertEqual(openAI.displayName, "OpenAI")
        XCTAssertEqual(openAI.credentialPlaceholder, "OpenAI API key")
        XCTAssertTrue(openAI.supportsCustomModel)
        XCTAssertEqual(openAI.defaultModel, "gpt-4.1-mini")
    }
}
