# macOS Global Translator

A native macOS menu bar translator that captures selected editable text, translates it in the background, and writes the result back to the original selection when possible.

## Features

- Global hotkey trigger with a menu bar-only app shell
- Accessibility-based selected-text capture
- Background serial translation queue
- Direct writeback to the original selection when the source element is still writable
- Safe fallback to notification plus clipboard when writeback fails
- OpenAI adapter as the first built-in provider, with a provider registry for future adapters

## Project Layout

- `GlobalTranslator/`: app code, services, models, and SwiftUI views
- `GlobalTranslatorTests/`: unit and contract tests
- `Harness/FixtureEditorApp/`: local smoke-test fixture app
- `project.yml`: XcodeGen project definition
- `GlobalTranslator.xcodeproj/`: generated Xcode project

## Local Development

```bash
swift build -Xswiftc -warnings-as-errors
swift test
./scripts/generate_xcodeproj.sh
open GlobalTranslator.xcodeproj
```

## Setup Notes

1. Grant Accessibility permission to `GlobalTranslator`.
2. Save an OpenAI API key in Settings.
3. Pick a target language and preferred hotkey.
4. Select editable text in another app and press the hotkey.
