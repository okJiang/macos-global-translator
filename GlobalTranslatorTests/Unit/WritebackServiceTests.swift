import XCTest
@testable import GlobalTranslatorApp

@MainActor
final class WritebackServiceTests: XCTestCase {
    func testFallsBackToClipboardWhenTargetWriteFails() throws {
        let clipboard = ClipboardSpy()
        let service = WritebackService(clipboard: clipboard)
        let selection = CapturedSelection(
            frontmostBundleID: "com.apple.TextEdit",
            selectedText: "hello",
            selectedRange: NSRange(location: 0, length: 5),
            capturedAt: Date(),
            writebackTarget: FailingWritebackTarget()
        )

        let outcome = service.write("bonjour", for: selection)

        XCTAssertEqual(outcome, .copiedToClipboard)
        XCTAssertEqual(clipboard.lastCopiedText, "bonjour")
    }
}

private final class ClipboardSpy: ClipboardWriting, @unchecked Sendable {
    private(set) var lastCopiedText: String?

    func copy(_ string: String) {
        lastCopiedText = string
    }
}

private struct FailingWritebackTarget: WritebackTarget {
    var targetDescription: String { "failing-target" }

    func replaceText(in selectedRange: NSRange, with replacement: String) throws -> NSRange {
        throw AccessibilityError.writeFailed("not writable")
    }
}
