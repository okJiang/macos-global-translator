import XCTest
@testable import GlobalTranslatorApp

final class TargetLanguageResolverTests: XCTestCase {
    func testResolvesCommonLanguageNamesForDeepL() throws {
        let resolver = TargetLanguageResolver()

        XCTAssertEqual(try resolver.resolve("Japanese", for: "deepl"), "JA")
        XCTAssertEqual(try resolver.resolve("en", for: "deepl"), "EN")
        XCTAssertEqual(try resolver.resolve("Chinese", for: "deepl"), "ZH")
    }

    func testPreservesSupportedDeepLVariantCodes() throws {
        let resolver = TargetLanguageResolver()

        XCTAssertEqual(try resolver.resolve("EN-US", for: "deepl"), "EN-US")
        XCTAssertEqual(try resolver.resolve("pt-br", for: "deepl"), "PT-BR")
        XCTAssertEqual(try resolver.resolve("ZH-HANT", for: "deepl"), "ZH-HANT")
    }

    func testRejectsUnsupportedTargetLanguage() {
        let resolver = TargetLanguageResolver()

        XCTAssertThrowsError(try resolver.resolve("Martian", for: "deepl")) { error in
            let resolutionError = error as? TargetLanguageResolutionError
            XCTAssertEqual(resolutionError, .unsupported(rawValue: "Martian", providerID: "deepl"))
        }
    }

    func testResolvesCommonLanguageNamesForGoogle() throws {
        let resolver = TargetLanguageResolver()

        XCTAssertEqual(try resolver.resolve("Spanish", for: "google"), "es")
        XCTAssertEqual(try resolver.resolve("ja", for: "google"), "ja")
        XCTAssertEqual(try resolver.resolve("ZH-HANS", for: "google"), "zh-CN")
    }
}
