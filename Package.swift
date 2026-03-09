// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GlobalTranslator",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "GlobalTranslator", targets: ["GlobalTranslatorApp"]),
        .executable(name: "FixtureEditorApp", targets: ["FixtureEditorApp"]),
    ],
    targets: [
        .executableTarget(
            name: "GlobalTranslatorApp",
            path: "GlobalTranslator",
            exclude: ["Resources"]
        ),
        .executableTarget(
            name: "FixtureEditorApp",
            path: "Harness/FixtureEditorApp",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "GlobalTranslatorTests",
            dependencies: ["GlobalTranslatorApp"],
            path: "GlobalTranslatorTests"
        ),
    ]
)
