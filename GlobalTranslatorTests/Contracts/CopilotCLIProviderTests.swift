import XCTest
@testable import GlobalTranslatorApp

final class CopilotCLIProviderTests: XCTestCase {
    func testBuildsExpectedCommandAndParsesTrimmedStdout() async throws {
        let runner = RecordingCommandRunner(
            result: CommandResult(
                stdout: " bonjour le monde \n",
                stderr: "",
                exitCode: 0
            )
        )
        let provider = CopilotCLIProvider(
            commandRunner: runner,
            executableLocator: StubExecutableLocator(executable: URL(fileURLWithPath: "/opt/homebrew/bin/copilot")),
            workingDirectory: URL(fileURLWithPath: "/tmp/global-translator-copilot")
        )

        let response = try await provider.translate(
            TranslationRequest(text: "hello world", targetLanguage: "French"),
            credential: nil,
            preferences: ProviderPreferences(model: "gpt-5")
        )
        let maybeInvocation = await runner.firstInvocation()
        let invocation = try XCTUnwrap(maybeInvocation)

        XCTAssertEqual(response.translatedText, "bonjour le monde")
        XCTAssertEqual(invocation.executableURL.path, "/opt/homebrew/bin/copilot")
        XCTAssertEqual(try XCTUnwrap(invocation.workingDirectoryURL).path, "/tmp/global-translator-copilot")
        XCTAssertTrue(invocation.arguments.contains("-p"))
        XCTAssertTrue(invocation.arguments.contains("-s"))
        XCTAssertTrue(invocation.arguments.contains("--allow-all-tools"))
        XCTAssertTrue(invocation.arguments.contains("--disable-builtin-mcps"))
        XCTAssertTrue(invocation.arguments.contains("--no-custom-instructions"))
        XCTAssertTrue(invocation.arguments.contains("--no-auto-update"))
        XCTAssertTrue(invocation.arguments.contains("--model"))
        XCTAssertTrue(invocation.arguments.contains("gpt-5"))
        XCTAssertTrue(invocation.arguments.contains("--excluded-tools"))
        XCTAssertTrue(invocation.arguments.contains("read"))
        XCTAssertTrue(invocation.arguments.contains("write"))
        XCTAssertTrue(invocation.arguments.contains("shell"))
        XCTAssertTrue(invocation.arguments.contains("url"))
        XCTAssertTrue(invocation.arguments.contains("memory"))
        XCTAssertTrue(invocation.arguments.joined(separator: " ").contains("Return only the translated text"))
    }

    func testThrowsHelpfulErrorWhenExecutableIsMissing() async {
        let provider = CopilotCLIProvider(
            commandRunner: RecordingCommandRunner(
                result: CommandResult(stdout: "", stderr: "", exitCode: 0)
            ),
            executableLocator: StubExecutableLocator(executable: nil),
            workingDirectory: URL(fileURLWithPath: "/tmp/global-translator-copilot")
        )

        await XCTAssertThrowsErrorAsync(
            try await provider.translate(
                TranslationRequest(text: "hello", targetLanguage: "French"),
                credential: nil,
                preferences: .empty
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("Copilot CLI"))
        }
    }

    func testThrowsWhenProcessReturnsEmptyOutput() async {
        let runner = RecordingCommandRunner(
            result: CommandResult(stdout: " \n", stderr: "", exitCode: 0)
        )
        let provider = CopilotCLIProvider(
            commandRunner: runner,
            executableLocator: StubExecutableLocator(executable: URL(fileURLWithPath: "/opt/homebrew/bin/copilot")),
            workingDirectory: URL(fileURLWithPath: "/tmp/global-translator-copilot")
        )

        await XCTAssertThrowsErrorAsync(
            try await provider.translate(
                TranslationRequest(text: "hello", targetLanguage: "French"),
                credential: nil,
                preferences: .empty
            )
        )
    }

    func testThrowsWhenProcessExitsNonZero() async {
        let runner = RecordingCommandRunner(
            result: CommandResult(stdout: "", stderr: "authentication required", exitCode: 1)
        )
        let provider = CopilotCLIProvider(
            commandRunner: runner,
            executableLocator: StubExecutableLocator(executable: URL(fileURLWithPath: "/opt/homebrew/bin/copilot")),
            workingDirectory: URL(fileURLWithPath: "/tmp/global-translator-copilot")
        )

        await XCTAssertThrowsErrorAsync(
            try await provider.translate(
                TranslationRequest(text: "hello", targetLanguage: "French"),
                credential: nil,
                preferences: .empty
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("authentication required"))
        }
    }
}

private actor RecordingCommandRunner: CommandRunning {
    private(set) var invocations: [CommandInvocation] = []
    let result: CommandResult

    init(result: CommandResult) {
        self.result = result
    }

    func run(_ invocation: CommandInvocation) async throws -> CommandResult {
        invocations.append(invocation)
        return result
    }

    func firstInvocation() -> CommandInvocation? {
        invocations.first
    }
}

private struct StubExecutableLocator: CopilotCLIExecutableLocating {
    let executable: URL?

    func findExecutable() -> URL? {
        executable
    }
}

private func XCTAssertThrowsErrorAsync(
    _ expression: @autoclosure @escaping () async throws -> some Any,
    _ errorHandler: ((Error) -> Void)? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected error to be thrown", file: file, line: line)
    } catch {
        errorHandler?(error)
    }
}
