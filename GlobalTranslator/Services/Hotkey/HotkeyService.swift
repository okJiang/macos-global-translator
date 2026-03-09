import Carbon
import Foundation

@MainActor
final class HotkeyService {
    private static let signature: OSType = 0x47544C54
    private static var eventHandler: EventHandlerRef?
    private static var action: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?

    init() {
        installEventHandlerIfNeeded()
    }

    func register(shortcut: HotkeyShortcut, action: @escaping () -> Void) throws {
        unregister()
        Self.action = action

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: 1)
        let status = RegisterEventHotKey(
            shortcut.carbonKeyCode,
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard status == noErr else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func installEventHandlerIfNeeded() {
        guard Self.eventHandler == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, _ in
                Task { @MainActor in
                    HotkeyService.action?()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &Self.eventHandler
        )
    }
}
