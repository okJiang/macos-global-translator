import SwiftUI

struct OnboardingView: View {
    @ObservedObject var controller: MenuBarController

    private var defaultProviderDescriptor: ProviderDescriptor {
        controller.providerRegistry.descriptor(for: controller.settingsStore.settings.defaultProvider)
            ?? CopilotCLIProvider().descriptor
    }

    private var defaultProviderID: String {
        controller.settingsStore.settings.defaultProvider
    }

    private var providerSetupTitle: String {
        defaultProviderDescriptor.requiresStoredCredential ? defaultProviderDescriptor.credentialLabel : "GitHub Copilot CLI"
    }

    private var providerSetupDetail: String {
        if defaultProviderDescriptor.requiresStoredCredential {
            return controller.credentialStore.credential(for: defaultProviderID) == nil ? "Missing" : "Saved"
        }

        return controller.isProviderReady(defaultProviderID)
            ? "Detected locally"
            : "Missing. Install and sign in locally."
    }

    private var providerSetupButtonTitle: String {
        defaultProviderDescriptor.requiresStoredCredential ? "Open Settings" : "Open Copilot Docs"
    }

    private func openProviderSetup() {
        if defaultProviderDescriptor.requiresStoredCredential {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            return
        }

        if let url = URL(string: "https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/install-copilot-cli") {
            NSWorkspace.shared.open(url)
        }
    }

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
                title: providerSetupTitle,
                detail: providerSetupDetail,
                buttonTitle: providerSetupButtonTitle,
                action: openProviderSetup
            )

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
