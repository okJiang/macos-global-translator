import XCTest
@testable import GlobalTranslatorApp

@MainActor
final class AppSettingsStoreTests: XCTestCase {
    func testLoadsDefaultsWhenStoreIsEmpty() {
        let store = AppSettingsStore(keyValueStore: InMemoryKeyValueStore())

        XCTAssertEqual(store.settings.targetLanguage, "English")
        XCTAssertEqual(store.settings.defaultProvider, "copilot")
        XCTAssertEqual(store.settings.hotkey, .commandShiftT)
        XCTAssertTrue(store.settings.recentJobs.isEmpty)
    }

    func testPersistsUpdatesAcrossInstances() {
        let keyValueStore = InMemoryKeyValueStore()
        let firstStore = AppSettingsStore(keyValueStore: keyValueStore)
        firstStore.updateTargetLanguage("Japanese")
        firstStore.setAPIModel("gpt-4.1-mini", for: "openai")
        firstStore.appendRecentJob(
            RecentTranslationJob(
                preview: "hello",
                providerID: "openai",
                status: .succeeded,
                createdAt: Date(timeIntervalSince1970: 123)
            )
        )

        let secondStore = AppSettingsStore(keyValueStore: keyValueStore)

        XCTAssertEqual(secondStore.settings.targetLanguage, "Japanese")
        XCTAssertEqual(secondStore.settings.providerPreferences["openai"]?.model, "gpt-4.1-mini")
        XCTAssertEqual(secondStore.settings.recentJobs.count, 1)
    }

    func testDoesNotPersistDefaultModelForProvidersWithoutCustomModel() {
        let keyValueStore = InMemoryKeyValueStore()
        let firstStore = AppSettingsStore(keyValueStore: keyValueStore)

        firstStore.setAPIModel("", for: "deepl")

        let secondStore = AppSettingsStore(keyValueStore: keyValueStore)

        XCTAssertNil(secondStore.settings.providerPreferences["deepl"]?.model)
    }
}

private final class InMemoryKeyValueStore: KeyValueStoring {
    private var storage: [String: Data] = [:]

    func storedData(forKey key: String) -> Data? {
        storage[key]
    }

    func store(_ data: Data?, forKey key: String) {
        storage[key] = data
    }
}
