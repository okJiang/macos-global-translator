import Foundation

protocol CopilotCLIExecutableLocating: Sendable {
    func findExecutable() -> URL?
}

struct CopilotCLIExecutableLocator: CopilotCLIExecutableLocating {
    private let fileManager: any FileManaging
    private let environment: [String: String]

    init(
        fileManager: any FileManaging = FileManager.default,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.fileManager = fileManager
        self.environment = environment
    }

    func findExecutable() -> URL? {
        for path in candidatePaths where fileManager.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        return nil
    }

    private var candidatePaths: [String] {
        let knownLocations = [
            "/opt/homebrew/bin/copilot",
            "/usr/local/bin/copilot",
        ]
        let pathEntries = (environment["PATH"] ?? "")
            .split(separator: ":")
            .map { String($0) }
            .filter { !$0.isEmpty }
            .map { URL(fileURLWithPath: $0).appendingPathComponent("copilot").path }

        return knownLocations + pathEntries
    }
}

enum CopilotCLIProviderError: LocalizedError {
    case executableNotFound
    case timedOut
    case emptyOutput
    case processFailed(String)
    case workingDirectoryUnavailable

    var errorDescription: String? {
        switch self {
        case .executableNotFound:
            return "GitHub Copilot CLI was not found. Install `copilot` locally before using this provider."
        case .timedOut:
            return "GitHub Copilot CLI timed out before returning a translation."
        case .emptyOutput:
            return "GitHub Copilot CLI returned an empty translation."
        case let .processFailed(message):
            return "GitHub Copilot CLI failed: \(message)"
        case .workingDirectoryUnavailable:
            return "Global Translator could not prepare a neutral working directory for GitHub Copilot CLI."
        }
    }
}

struct CopilotCLIProvider: TranslationProvider {
    let descriptor = ProviderDescriptor(
        id: "copilot",
        displayName: "GitHub Copilot",
        credentialLabel: "",
        credentialPlaceholder: "",
        requiresStoredCredential: false,
        supportsCustomModel: true,
        defaultModel: nil
    )

    private let commandRunner: any CommandRunning
    private let executableLocator: any CopilotCLIExecutableLocating
    private let workingDirectory: URL
    private let timeout: TimeInterval

    init(
        commandRunner: any CommandRunning = ProcessCommandRunner(),
        executableLocator: any CopilotCLIExecutableLocating = CopilotCLIExecutableLocator(),
        workingDirectory: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("GlobalTranslator.CopilotCLI", isDirectory: true),
        timeout: TimeInterval = 45
    ) {
        self.commandRunner = commandRunner
        self.executableLocator = executableLocator
        self.workingDirectory = workingDirectory
        self.timeout = timeout
    }

    func translate(
        _ request: TranslationRequest,
        credential: ProviderCredential?,
        preferences: ProviderPreferences
    ) async throws -> TranslationResponse {
        _ = credential

        guard let executableURL = executableLocator.findExecutable() else {
            throw CopilotCLIProviderError.executableNotFound
        }
        do {
            try FileManager.default.createDirectory(
                at: workingDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            throw CopilotCLIProviderError.workingDirectoryUnavailable
        }

        do {
            let result = try await commandRunner.run(
                CommandInvocation(
                    executableURL: executableURL,
                    arguments: arguments(for: request, model: preferences.model),
                    workingDirectoryURL: workingDirectory,
                    environment: [:],
                    timeout: timeout
                )
            )

            guard result.exitCode == 0 else {
                let message = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
                throw CopilotCLIProviderError.processFailed(
                    message.isEmpty ? "exit code \(result.exitCode)" : message
                )
            }

            let translatedText = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !translatedText.isEmpty else {
                throw CopilotCLIProviderError.emptyOutput
            }

            return TranslationResponse(translatedText: translatedText, detectedSourceLanguage: "auto")
        } catch let error as CommandRunnerError {
            switch error {
            case .timedOut:
                throw CopilotCLIProviderError.timedOut
            case let .failedToLaunch(message):
                throw CopilotCLIProviderError.processFailed(message)
            }
        }
    }

    private func arguments(for request: TranslationRequest, model: String?) -> [String] {
        var arguments = [
            "-p",
            prompt(for: request),
            "-s",
            "--allow-all-tools",
            "--excluded-tools", "read", "write", "shell", "url", "memory",
            "--disable-builtin-mcps",
            "--no-custom-instructions",
            "--no-auto-update",
        ]
        if let model, !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            arguments.append(contentsOf: ["--model", model])
        }

        return arguments
    }

    private func prompt(for request: TranslationRequest) -> String {
        """
        Translate the following text into \(request.targetLanguage).
        Preserve line breaks and plain-text structure.
        Return only the translated text.
        Do not explain anything.
        Do not wrap the answer in code fences.
        Do not add prefixes or suffixes.
        Do not use tools.

        \(request.text)
        """
    }
}
