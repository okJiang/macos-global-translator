import AppKit
import ApplicationServices
import Foundation

@MainActor
final class AccessibilityCaptureService {
    func captureSelection() throws -> CapturedSelection {
        guard AccessibilityCaptureService.isTrusted else {
            throw AccessibilityError.notTrusted
        }

        let systemWide = AXUIElementCreateSystemWide()
        var focusedValue: CFTypeRef?
        let focusStatus = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        )
        guard focusStatus == .success, let focusedValue else {
            throw AccessibilityError.noFocusedElement
        }
        guard CFGetTypeID(focusedValue) == AXUIElementGetTypeID() else {
            throw AccessibilityError.noFocusedElement
        }

        let element = unsafeDowncast(focusedValue as AnyObject, to: AXUIElement.self)
        let selectedText = try stringAttribute(kAXSelectedTextAttribute as CFString, on: element)
        let selectedRange = try rangeAttribute(kAXSelectedTextRangeAttribute as CFString, on: element)
        guard !selectedText.isEmpty, selectedRange.length > 0 else {
            throw AccessibilityError.missingSelectedText
        }

        return CapturedSelection(
            frontmostBundleID: NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "unknown",
            selectedText: selectedText,
            selectedRange: selectedRange,
            capturedAt: .now,
            writebackTarget: AccessibilityWritebackTarget(element: element)
        )
    }

    @MainActor static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    private func stringAttribute(_ attribute: CFString, on element: AXUIElement) throws -> String {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard status == .success, let value, let string = value as? String else {
            throw AccessibilityError.missingSelectedText
        }
        return string
    }

    private func rangeAttribute(_ attribute: CFString, on element: AXUIElement) throws -> NSRange {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard status == .success, let value else {
            throw AccessibilityError.missingSelectedRange
        }
        let axValue = value as! AXValue
        guard AXValueGetType(axValue) == .cfRange else {
            throw AccessibilityError.unsupportedSelection
        }

        var range = CFRange()
        guard AXValueGetValue(axValue, .cfRange, &range) else {
            throw AccessibilityError.missingSelectedRange
        }

        return NSRange(location: range.location, length: range.length)
    }
}

final class AccessibilityWritebackTarget: WritebackTarget, @unchecked Sendable {
    private let element: AXUIElement

    init(element: AXUIElement) {
        self.element = element
    }

    var targetDescription: String { "AXUIElement" }

    func replaceText(in selectedRange: NSRange, with replacement: String) throws -> NSRange {
        var value: CFTypeRef?
        let copyStatus = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
        guard copyStatus == .success, let currentValue = value as? String else {
            throw AccessibilityError.unsupportedWriteback
        }

        guard let stringRange = Range(selectedRange, in: currentValue) else {
            throw AccessibilityError.writeFailed("The captured selection range is no longer valid.")
        }

        var updatedValue = currentValue
        updatedValue.replaceSubrange(stringRange, with: replacement)

        let setStatus = AXUIElementSetAttributeValue(
            element,
            kAXValueAttribute as CFString,
            updatedValue as CFString
        )
        guard setStatus == .success else {
            throw AccessibilityError.writeFailed("The original target rejected the translated text.")
        }

        let newRange = NSRange(location: selectedRange.location, length: replacement.utf16.count)
        var cfRange = CFRange(location: newRange.location, length: newRange.length)
        if let rangeValue = AXValueCreate(.cfRange, &cfRange) {
            _ = AXUIElementSetAttributeValue(
                element,
                kAXSelectedTextRangeAttribute as CFString,
                rangeValue
            )
        }

        return newRange
    }
}
