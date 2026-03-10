import XCTest
@testable import GlobalTranslatorApp

final class OpenAIProviderTests: XCTestCase {
    func testMapsRequestAndParsesResponse() async throws {
        let recorder = RequestRecorder()
        let transport = MockHTTPClient(
            recorder: recorder,
            responseData: try XCTUnwrap(
                """
        {
          "choices": [
            {
              "message": {
                "content": "bonjour"
              }
            }
          ]
        }
        """.data(using: .utf8)
            )
        )

        let provider = OpenAIProvider(
            session: transport,
            endpoint: URL(string: "https://api.openai.com/v1/chat/completions")!
        )
        let response = try await provider.translate(
            TranslationRequest(text: "hello", targetLanguage: "French"),
            credential: ProviderCredential(providerID: "openai", apiKey: "secret"),
            preferences: ProviderPreferences(model: "gpt-4.1-mini")
        )
        let request = await recorder.lastRequest

        XCTAssertEqual(response.translatedText, "bonjour")
        XCTAssertEqual(request?.url?.absoluteString, "https://api.openai.com/v1/chat/completions")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "Bearer secret")
        let body = try XCTUnwrap(request?.httpBody).utf8String()
        XCTAssertTrue(body.contains("\"model\":\"gpt-4.1-mini\""))
        XCTAssertTrue(body.contains("Translate the provided text into French"))
    }
}
