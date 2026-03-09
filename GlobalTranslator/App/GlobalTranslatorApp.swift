import SwiftUI

@main
struct GlobalTranslatorApplication: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller = MenuBarController()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(controller: controller)
                .task {
                    controller.start()
                }
        } label: {
            Label("Global Translator", systemImage: controller.statusSymbolName)
        }

        Settings {
            SettingsView(controller: controller)
        }

        Window("Onboarding", id: "onboarding") {
            OnboardingView(controller: controller)
        }
        .defaultSize(width: 520, height: 360)
    }
}
