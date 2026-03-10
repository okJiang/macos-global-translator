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

protocol FileManaging: Sendable {
    func fileExists(atPath path: String) -> Bool
}

extension FileManager: FileManaging {}

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

struct CommandInvocation: Sendable {
    let executableURL: URL
    let arguments: [String]
    let workingDirectoryURL: URL?
    let environment: [String: String]
    let timeout: TimeInterval
}

struct CommandResult: Sendable {
    let stdout: String
    let stderr: String
    let exitCode: Int32
}

protocol CommandRunning: Sendable {
    func run(_ invocation: CommandInvocation) async throws -> CommandResult
}

enum CommandRunnerError: LocalizedError {
    case timedOut(command: String)
    case failedToLaunch(String)

    var errorDescription: String? {
        switch self {
        case let .timedOut(command):
            return "The command timed out: \(command)"
        case let .failedToLaunch(message):
            return message
        }
    }
}

struct ProcessCommandRunner: CommandRunning {
    func run(_ invocation: CommandInvocation) async throws -> CommandResult {
        try await Task.detached(priority: nil) {
            try runSynchronously(invocation)
        }.value
    }

    private func runSynchronously(_ invocation: CommandInvocation) throws -> CommandResult {
        let process = Process()
        process.executableURL = invocation.executableURL
        process.arguments = invocation.arguments
        if let workingDirectoryURL = invocation.workingDirectoryURL {
            process.currentDirectoryURL = workingDirectoryURL
        }
        if !invocation.environment.isEmpty {
            process.environment = invocation.environment
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let finished = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in
            finished.signal()
        }

        do {
            try process.run()
        } catch {
            throw CommandRunnerError.failedToLaunch(error.localizedDescription)
        }

        if finished.wait(timeout: .now() + invocation.timeout) == .timedOut {
            process.terminate()
            _ = finished.wait(timeout: .now() + 1)
            throw CommandRunnerError.timedOut(
                command: ([invocation.executableURL.path] + invocation.arguments).joined(separator: " ")
            )
        }

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        return CommandResult(
            stdout: String(data: stdoutData, encoding: .utf8) ?? "",
            stderr: String(data: stderrData, encoding: .utf8) ?? "",
            exitCode: process.terminationStatus
        )
    }
}
