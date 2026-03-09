import SwiftUI

struct OnboardingView: View {
    @ObservedObject var controller: MenuBarController

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Finish setup")
                .font(.largeTitle.bold())

            setupRow(
                title: "Accessibility",
                detail: AccessibilityCaptureService.isTrusted ? "Granted" : "Missing",
                buttonTitle: "Open Privacy Settings"
            ) {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }

            setupRow(
                title: "API key",
                detail: controller.credentialStore.credential(for: controller.settingsStore.settings.defaultProvider) == nil ? "Missing" : "Saved",
                buttonTitle: "Open Settings"
            ) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }

            setupRow(
                title: "Hotkey",
                detail: controller.settingsStore.settings.hotkey.displayName,
                buttonTitle: "Refresh Hotkey"
            ) {
                controller.refreshHotkey()
            }

            Text("After these three steps are ready, select any editable text and press the global shortcut.")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(28)
        .frame(minWidth: 520, minHeight: 360)
    }

    private func setupRow(title: String, detail: String, buttonTitle: String, action: @escaping () -> Void) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(buttonTitle, action: action)
        }
    }
}
