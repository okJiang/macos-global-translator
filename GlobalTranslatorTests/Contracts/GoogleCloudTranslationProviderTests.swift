import XCTest
@testable import GlobalTranslatorApp

final class GoogleCloudTranslationProviderTests: XCTestCase {
    func testMapsRequestAndParsesResponse() async throws {
        let recorder = RequestRecorder()
        let transport = MockHTTPClient(
            recorder: recorder,
            responseData: try XCTUnwrap(
                """
        {
          "data": {
            "translations": [
              {
                "translatedText": "Hola",
                "detectedSourceLanguage": "en"
              }
            ]
          }
        }
        """.data(using: .utf8)
            )
        )

        let provider = GoogleCloudTranslationProvider(session: transport)
        let response = try await provider.translate(
            TranslationRequest(text: "Hello", targetLanguage: "Spanish"),
            credential: ProviderCredential(providerID: "google", apiKey: "secret"),
            preferences: ProviderPreferences(model: nil)
        )
        let request = await recorder.lastRequest
        let payload = try XCTUnwrap(try XCTUnwrap(request?.httpBody).jsonObject() as? [String: Any])
        let components = try XCTUnwrap(request?.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) })

        XCTAssertEqual(response.translatedText, "Hola")
        XCTAssertEqual(response.detectedSourceLanguage, "en")
        XCTAssertEqual(request?.url?.scheme, "https")
        XCTAssertEqual(request?.url?.host, "translation.googleapis.com")
        XCTAssertEqual(request?.url?.path, "/language/translate/v2")
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "key" })?.value, "secret")
        XCTAssertEqual(payload["q"] as? String, "Hello")
        XCTAssertEqual(payload["target"] as? String, "es")
        XCTAssertEqual(payload["format"] as? String, "text")
    }
}
