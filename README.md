# macOS Global Translator

A native macOS menu bar translator that captures selected editable text, translates it in the background, and writes the result back to the original selection when possible.

## Features

- GitHub Copilot CLI as the default local provider, without storing an API key
- Global hotkey trigger with a menu bar-only app shell
- Accessibility-based selected-text capture
- Background serial translation queue
- Direct writeback to the original selection when the source element is still writable
- Safe fallback to notification plus clipboard when writeback fails
- Built-in GitHub Copilot CLI, OpenAI, DeepL, and Google Cloud Translation Basic v2 adapters, with a provider registry for future adapters

## Project Layout

- `GlobalTranslator/`: app code, services, models, and SwiftUI views
- `GlobalTranslatorTests/`: unit and contract tests
- `Harness/FixtureEditorApp/`: local smoke-test fixture app
- `project.yml`: XcodeGen project definition
- `GlobalTranslator.xcodeproj/`: generated Xcode project

## Local Development

```bash
./scripts/generate_xcodeproj.sh
xcodebuild test -project GlobalTranslator.xcodeproj -scheme GlobalTranslator -destination 'platform=macOS'
swift test
open GlobalTranslator.xcodeproj
```

## Setup Notes

1. Grant Accessibility permission to `GlobalTranslator`.
2. Install `copilot` locally and sign in once from Terminal if you want to use the default provider.
3. Optionally switch to `OpenAI`, `DeepL`, or `Google Cloud` in Settings and save the corresponding API key.
4. Pick a target language using a common language name or code, then choose a preferred hotkey.
5. Select editable text in another app and press the hotkey.

## Copilot CLI Notes

- `GitHub Copilot` is the default provider for new installs.
- The app uses your existing local `copilot` CLI session and does not store a Copilot API key.
- This integration uses single-shot CLI prompts only. It does not use ACP, and it does not modify `~/.copilot` or load repo custom instructions.
