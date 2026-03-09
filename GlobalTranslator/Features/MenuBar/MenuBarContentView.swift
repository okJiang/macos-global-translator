import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var controller: MenuBarController
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(controller.statusText, systemImage: controller.statusSymbolName)
                .font(.headline)

            if let lastErrorMessage = controller.lastErrorMessage {
                Text(lastErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("Translate Selection Now") {
                controller.triggerTranslationFromHotkey()
            }
            .keyboardShortcut(.return)

            SettingsLink()

            Button("Open Onboarding") {
                openWindow(id: "onboarding")
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(14)
        .frame(width: 280)
    }
}
