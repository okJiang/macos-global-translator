import SwiftUI

@main
struct FixtureEditorApplication: App {
    @State private var text = "Select a portion of this text and trigger Global Translator to verify background replacement."

    var body: some Scene {
        WindowGroup {
            VStack(alignment: .leading, spacing: 16) {
                Text("Fixture Editor")
                    .font(.title.bold())
                TextEditor(text: $text)
                    .font(.body.monospaced())
                    .frame(minWidth: 520, minHeight: 320)
            }
            .padding(24)
        }
    }
}
