import SwiftUI

struct SettingsView: View {
    @ObservedObject var controller: MenuBarController
    @State private var targetLanguage = ""
    @State private var hotkey: HotkeyShortcut = .commandShiftT
    @State private var selectedProvider = "openai"
    @State private var model = ""
    @State private var apiKey = ""

    private var selectedProviderDescriptor: ProviderDescriptor {
        controller.providerRegistry.descriptor(for: selectedProvider)
            ?? OpenAIProvider().descriptor
    }

    var body: some View {
        Form {
            Section("Translation") {
                TextField("Target language", text: $targetLanguage)

                Picker("Hotkey", selection: $hotkey) {
                    ForEach(HotkeyShortcut.allCases) { shortcut in
                        Text(shortcut.displayName).tag(shortcut)
                    }
                }

                Picker("Provider", selection: $selectedProvider) {
                    ForEach(controller.providerRegistry.availableProviders, id: \.id) { provider in
                        Text(provider.displayName).tag(provider.id)
                    }
                }

                if selectedProviderDescriptor.supportsCustomModel {
                    TextField("Model", text: $model)
                }
            }

            Section("Actions") {
                Button("Save Settings") {
                    controller.settingsStore.updateTargetLanguage(targetLanguage)
                    controller.settingsStore.updateHotkey(hotkey)
                    controller.settingsStore.updateDefaultProvider(selectedProvider)
                    if selectedProviderDescriptor.supportsCustomModel {
                        controller.settingsStore.setAPIModel(model, for: selectedProvider)
                    } else {
                        controller.settingsStore.setAPIModel("", for: selectedProvider)
                    }
                    controller.refreshHotkey()
                }
            }

            Section(selectedProviderDescriptor.credentialLabel) {
                SecureField(selectedProviderDescriptor.credentialPlaceholder, text: $apiKey)
                Button("Save \(selectedProviderDescriptor.credentialLabel)") {
                    controller.saveAPIKey(apiKey)
                }
            }

            Section("Recent Jobs") {
                if controller.settingsStore.settings.recentJobs.isEmpty {
                    Text("No jobs yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(controller.settingsStore.settings.recentJobs) { job in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(job.preview)
                            Text("\(job.providerID) • \(job.status.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(minWidth: 520, minHeight: 480)
        .onAppear {
            targetLanguage = controller.settingsStore.settings.targetLanguage
            hotkey = controller.settingsStore.settings.hotkey
            selectedProvider = controller.settingsStore.settings.defaultProvider
            reloadProviderFields(for: selectedProvider)
        }
        .onChange(of: selectedProvider) { _, newValue in
            reloadProviderFields(for: newValue)
        }
    }

    private func reloadProviderFields(for providerID: String) {
        let descriptor = controller.providerRegistry.descriptor(for: providerID) ?? OpenAIProvider().descriptor
        model = controller.settingsStore.settings.preferences(for: providerID).model ?? descriptor.defaultModel ?? ""
        apiKey = controller.credentialStore.apiKey(for: providerID)
    }
}
