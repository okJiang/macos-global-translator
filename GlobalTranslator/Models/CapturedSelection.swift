import Foundation

protocol WritebackTarget: Sendable {
    var targetDescription: String { get }
    func replaceText(in selectedRange: NSRange, with replacement: String) throws -> NSRange
}

struct CapturedSelection: Sendable {
    let frontmostBundleID: String
    let selectedText: String
    let selectedRange: NSRange
    let capturedAt: Date
    let writebackTarget: any WritebackTarget
}

enum WritebackOutcome: Equatable {
    case succeeded
    case copiedToClipboard
    case failed
}

enum AccessibilityError: LocalizedError {
    case notTrusted
    case noFocusedElement
    case missingSelectedText
    case missingSelectedRange
    case unsupportedSelection
    case unsupportedWriteback
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .notTrusted:
            return "Accessibility permission is not granted."
        case .noFocusedElement:
            return "Could not find the focused editable element."
        case .missingSelectedText:
            return "No selected text was found."
        case .missingSelectedRange:
            return "No selected text range was found."
        case .unsupportedSelection:
            return "The focused element does not expose writable text attributes."
        case .unsupportedWriteback:
            return "The original element can no longer be written back to."
        case let .writeFailed(reason):
            return reason
        }
    }
}
