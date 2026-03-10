import XCTest
@testable import GlobalTranslatorApp

final class DeepLProviderTests: XCTestCase {
    func testMapsRequestAndParsesResponseForFreeEndpoint() async throws {
        let recorder = RequestRecorder()
        let transport = MockHTTPClient(
            recorder: recorder,
            responseData: try XCTUnwrap(
                """
        {
          "translations": [
            {
              "detected_source_language": "EN",
              "text": "こんにちは"
            }
          ]
        }
        """.data(using: .utf8)
            )
        )

        let provider = DeepLProvider(session: transport)
        let response = try await provider.translate(
            TranslationRequest(text: "hello", targetLanguage: "Japanese"),
            credential: ProviderCredential(providerID: "deepl", apiKey: "secret:fx"),
            preferences: ProviderPreferences(model: nil)
        )
        let request = await recorder.lastRequest
        let payload = try XCTUnwrap(try XCTUnwrap(request?.httpBody).jsonObject() as? [String: Any])

        XCTAssertEqual(response.translatedText, "こんにちは")
        XCTAssertEqual(response.detectedSourceLanguage, "EN")
        XCTAssertEqual(request?.url?.absoluteString, "https://api-free.deepl.com/v2/translate")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "DeepL-Auth-Key secret:fx")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(payload["target_lang"] as? String, "JA")
        XCTAssertEqual(payload["text"] as? [String], ["hello"])
    }

    func testUsesProEndpointForNonFreeKeys() async throws {
        let recorder = RequestRecorder()
        let transport = MockHTTPClient(
            recorder: recorder,
            responseData: try XCTUnwrap(
                """
        {
          "translations": [
            {
              "detected_source_language": "EN",
              "text": "Hallo"
            }
          ]
        }
        """.data(using: .utf8)
            )
        )

        let provider = DeepLProvider(session: transport)
        _ = try await provider.translate(
            TranslationRequest(text: "hello", targetLanguage: "de"),
            credential: ProviderCredential(providerID: "deepl", apiKey: "secret"),
            preferences: ProviderPreferences(model: nil)
        )
        let request = await recorder.lastRequest

        XCTAssertEqual(request?.url?.absoluteString, "https://api.deepl.com/v2/translate")
    }
}
