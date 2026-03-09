import AppKit
import Foundation
import UserNotifications

protocol KeyValueStoring {
    func storedData(forKey key: String) -> Data?
    func store(_ data: Data?, forKey key: String)
}

extension UserDefaults: KeyValueStoring {
    func storedData(forKey key: String) -> Data? {
        data(forKey: key)
    }

    func store(_ data: Data?, forKey key: String) {
        set(data, forKey: key)
    }
}

protocol SecretStoring {
    func readSecret(for key: String) throws -> String?
    func writeSecret(_ value: String, for key: String) throws
}

protocol ClipboardWriting {
    func copy(_ string: String)
}

struct PasteboardClipboard: ClipboardWriting {
    func copy(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
}

protocol UserNotificationCentering: Sendable {
    func notify(title: String, body: String) async
}

struct SystemUserNotificationCenter: UserNotificationCentering {
    func notify(title: String, body: String) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        try? await center.add(request)
    }
}

protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPClient {}
