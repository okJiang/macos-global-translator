import XCTest
@testable import GlobalTranslatorApp

final class CopilotCLIExecutableLocatorTests: XCTestCase {
    func testPrefersKnownMacOSInstallLocationsBeforePATHEntries() {
        let locator = CopilotCLIExecutableLocator(
            fileManager: StubFileManager(
                existingPaths: [
                    "/opt/homebrew/bin/copilot",
                    "/usr/local/bin/copilot",
                    "/custom/bin/copilot",
                ]
            ),
            environment: ["PATH": "/custom/bin:/usr/bin"]
        )

        XCTAssertEqual(locator.findExecutable()?.path, "/opt/homebrew/bin/copilot")
    }

    func testFallsBackToPATHWhenKnownLocationsAreMissing() {
        let locator = CopilotCLIExecutableLocator(
            fileManager: StubFileManager(existingPaths: ["/custom/bin/copilot"]),
            environment: ["PATH": "/custom/bin:/usr/bin"]
        )

        XCTAssertEqual(locator.findExecutable()?.path, "/custom/bin/copilot")
    }

    func testReturnsNilWhenExecutableCannotBeFound() {
        let locator = CopilotCLIExecutableLocator(
            fileManager: StubFileManager(existingPaths: []),
            environment: ["PATH": "/custom/bin:/usr/bin"]
        )

        XCTAssertNil(locator.findExecutable())
    }
}

private struct StubFileManager: FileManaging {
    let existingPaths: Set<String>

    func fileExists(atPath path: String) -> Bool {
        existingPaths.contains(path)
    }
}
