import XCTest
@testable import GlobalTranslatorApp

final class ProviderRegistryTests: XCTestCase {
    func testAvailableProvidersExposeMetadataForOpenAIAndDeepL() throws {
        let registry = ProviderRegistry()
        let providers = registry.availableProviders

        XCTAssertEqual(providers.map(\.id), ["deepl", "openai"])

        let deepl = try XCTUnwrap(providers.first(where: { $0.id == "deepl" }))
        XCTAssertEqual(deepl.displayName, "DeepL")
        XCTAssertEqual(deepl.credentialLabel, "API key")
        XCTAssertEqual(deepl.credentialPlaceholder, "DeepL API key")
        XCTAssertFalse(deepl.supportsCustomModel)
        XCTAssertNil(deepl.defaultModel)

        let openAI = try XCTUnwrap(providers.first(where: { $0.id == "openai" }))
        XCTAssertEqual(openAI.displayName, "OpenAI")
        XCTAssertEqual(openAI.credentialPlaceholder, "OpenAI API key")
        XCTAssertTrue(openAI.supportsCustomModel)
        XCTAssertEqual(openAI.defaultModel, "gpt-4.1-mini")
    }
}
