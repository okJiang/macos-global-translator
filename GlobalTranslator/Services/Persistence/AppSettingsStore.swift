import Combine
import Foundation

@MainActor
final class AppSettingsStore: ObservableObject {
    @Published private(set) var settings: AppSettings

    private let keyValueStore: KeyValueStoring
    private let storageKey = "global-translator.settings"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(keyValueStore: KeyValueStoring = UserDefaults.standard) {
        self.keyValueStore = keyValueStore
        if
            let data = keyValueStore.storedData(forKey: storageKey),
            let decoded = try? decoder.decode(AppSettings.self, from: data)
        {
            settings = decoded
        } else {
            settings = AppSettings()
        }
    }

    func updateTargetLanguage(_ language: String) {
        settings.targetLanguage = language.isEmpty ? "English" : language
        persist()
    }

    func updateHotkey(_ hotkey: HotkeyShortcut) {
        settings.hotkey = hotkey
        persist()
    }

    func updateDefaultProvider(_ providerID: String) {
        settings.defaultProvider = providerID
        persist()
    }

    func setAPIModel(_ model: String, for providerID: String) {
        settings.providerPreferences[providerID] = ProviderPreferences(
            model: model.isEmpty ? ProviderPreferences.openAIDefault.model : model
        )
        persist()
    }

    func appendRecentJob(_ job: RecentTranslationJob) {
        settings.recentJobs.insert(job, at: 0)
        settings.recentJobs = Array(settings.recentJobs.prefix(5))
        persist()
    }

    private func persist() {
        if let data = try? encoder.encode(settings) {
            keyValueStore.store(data, forKey: storageKey)
        }
    }
}
