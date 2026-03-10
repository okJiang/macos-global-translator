import XCTest
@testable import GlobalTranslatorApp

final class TranslationQueueTests: XCTestCase {
    func testProcessesJobsSerially() async throws {
        let provider = FakeProvider()
        let registry = ProviderRegistry(providers: [provider])
        let clipboard = ClipboardSpy()
        let writebackService = await MainActor.run { WritebackService(clipboard: clipboard) }
        let queue = TranslationQueue(
            providerRegistry: registry,
            writebackService: writebackService,
            notificationCenter: NoopUserNotificationCenter()
        )
        let settings = AppSettings(defaultProvider: "openai")
        let selectionA = CapturedSelection(
            frontmostBundleID: "com.apple.TextEdit",
            selectedText: "hello",
            selectedRange: NSRange(location: 0, length: 5),
            capturedAt: Date(),
            writebackTarget: RecordingWritebackTarget()
        )
        let selectionB = CapturedSelection(
            frontmostBundleID: "com.apple.TextEdit",
            selectedText: "world",
            selectedRange: NSRange(location: 0, length: 5),
            capturedAt: Date(),
            writebackTarget: RecordingWritebackTarget()
        )

        let firstID = await queue.enqueue(
            selection: selectionA,
            settings: settings,
            credential: ProviderCredential(providerID: "openai", apiKey: "token")
        )
        let secondID = await queue.enqueue(
            selection: selectionB,
            settings: settings,
            credential: ProviderCredential(providerID: "openai", apiKey: "token")
        )
        let snapshots = await queue.waitUntilIdle()
        let recordedTexts = await provider.recordedTexts

        XCTAssertEqual(snapshots.map(\.id), [firstID, secondID])
        XCTAssertEqual(snapshots.map(\.status), [.succeeded, .succeeded])
        XCTAssertEqual(recordedTexts, ["hello", "world"])
    }

    func testProcessesCredentiallessProvidersWithoutFailingPreflight() async throws {
        let provider = FakeCredentiallessProvider()
        let registry = ProviderRegistry(providers: [provider])
        let clipboard = ClipboardSpy()
        let writebackService = await MainActor.run { WritebackService(clipboard: clipboard) }
        let queue = TranslationQueue(
            providerRegistry: registry,
            writebackService: writebackService,
            notificationCenter: NoopUserNotificationCenter()
        )
        let settings = AppSettings(defaultProvider: "copilot")
        let selection = CapturedSelection(
            frontmostBundleID: "com.apple.TextEdit",
            selectedText: "hello",
            selectedRange: NSRange(location: 0, length: 5),
            capturedAt: Date(),
            writebackTarget: RecordingWritebackTarget()
        )

        _ = await queue.enqueue(
            selection: selection,
            settings: settings,
            credential: nil
        )
        let snapshots = await queue.waitUntilIdle()
        let recordedTexts = await provider.recordedTexts

        XCTAssertEqual(snapshots.map(\.status), [.succeeded])
        XCTAssertEqual(recordedTexts, ["hello"])
    }
}

private actor FakeProvider: TranslationProvider {
    nonisolated let descriptor = ProviderDescriptor(
        id: "openai",
        displayName: "OpenAI",
        credentialLabel: "API key",
        credentialPlaceholder: "OpenAI API key",
        requiresStoredCredential: true,
        supportsCustomModel: true,
        defaultModel: "gpt-4.1-mini"
    )
    private(set) var recordedTexts: [String] = []

    func translate(_ request: TranslationRequest, credential: ProviderCredential?, preferences: ProviderPreferences) async throws -> TranslationResponse {
        recordedTexts.append(request.text)
        return TranslationResponse(translatedText: "translated-\(request.text)", detectedSourceLanguage: "auto")
    }
}

private actor FakeCredentiallessProvider: TranslationProvider {
    nonisolated let descriptor = ProviderDescriptor(
        id: "copilot",
        displayName: "GitHub Copilot",
        credentialLabel: "",
        credentialPlaceholder: "",
        requiresStoredCredential: false,
        supportsCustomModel: true,
        defaultModel: nil
    )
    private(set) var recordedTexts: [String] = []

    func translate(_ request: TranslationRequest, credential: ProviderCredential?, preferences: ProviderPreferences) async throws -> TranslationResponse {
        XCTAssertNil(credential)
        recordedTexts.append(request.text)
        return TranslationResponse(translatedText: "translated-\(request.text)", detectedSourceLanguage: "auto")
    }
}

private struct RecordingWritebackTarget: WritebackTarget {
    var targetDescription: String { "recording-target" }

    func replaceText(in selectedRange: NSRange, with replacement: String) throws -> NSRange {
        NSRange(location: selectedRange.location, length: replacement.count)
    }
}

private struct NoopUserNotificationCenter: UserNotificationCentering {
    func notify(title: String, body: String) async {}
}

private final class ClipboardSpy: ClipboardWriting, @unchecked Sendable {
    func copy(_ string: String) {}
}
