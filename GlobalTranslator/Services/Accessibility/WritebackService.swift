import Foundation

@MainActor
final class WritebackService {
    private let clipboard: ClipboardWriting

    init(clipboard: ClipboardWriting = PasteboardClipboard()) {
        self.clipboard = clipboard
    }

    func write(_ translation: String, for selection: CapturedSelection) -> WritebackOutcome {
        do {
            _ = try selection.writebackTarget.replaceText(in: selection.selectedRange, with: translation)
            return .succeeded
        } catch {
            clipboard.copy(translation)
            return .copiedToClipboard
        }
    }
}
