import Combine
import Foundation

@MainActor
final class MenuBarController: ObservableObject {
    @Published private(set) var statusText = "Idle"
    @Published private(set) var lastErrorMessage: String?

    let settingsStore: AppSettingsStore
    let credentialStore: CredentialStore
    let providerRegistry: ProviderRegistry

    private let captureService: AccessibilityCaptureService
    private let writebackService: WritebackService
    private let notificationCenter: any UserNotificationCentering
    private let hotkeyService: HotkeyService
    private let translationQueue: TranslationQueue
    private var cancellables: Set<AnyCancellable> = []

    init(
        settingsStore: AppSettingsStore = AppSettingsStore(),
        credentialStore: CredentialStore = CredentialStore(),
        providerRegistry: ProviderRegistry = ProviderRegistry(),
        captureService: AccessibilityCaptureService = AccessibilityCaptureService(),
        writebackService: WritebackService = WritebackService(),
        notificationCenter: any UserNotificationCentering = SystemUserNotificationCenter(),
        hotkeyService: HotkeyService = HotkeyService()
    ) {
        self.settingsStore = settingsStore
        self.credentialStore = credentialStore
        self.providerRegistry = providerRegistry
        self.captureService = captureService
        self.writebackService = writebackService
        self.notificationCenter = notificationCenter
        self.hotkeyService = hotkeyService
        self.translationQueue = TranslationQueue(
            providerRegistry: providerRegistry,
            writebackService: writebackService,
            notificationCenter: notificationCenter
        )
        bindHotkeyChanges()
    }

    var statusSymbolName: String {
        switch statusText {
        case "Working":
            return "ellipsis.circle"
        case "Failed":
            return "exclamationmark.triangle"
        case "Ready":
            return "checkmark.circle"
        default:
            return "character.cursor.ibeam"
        }
    }

    var requiresOnboarding: Bool {
        !AccessibilityCaptureService.isTrusted || credentialStore.credential(for: settingsStore.settings.defaultProvider) == nil
    }

    func start() {
        refreshHotkey()
    }

    func refreshHotkey() {
        do {
            try hotkeyService.register(shortcut: settingsStore.settings.hotkey) { [weak self] in
                self?.triggerTranslationFromHotkey()
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            statusText = "Failed"
        }
    }

    func triggerTranslationFromHotkey() {
        Task { await triggerTranslation() }
    }

    func triggerTranslation() async {
        do {
            statusText = "Working"
            let selection = try captureService.captureSelection()
            let jobID = await translationQueue.enqueue(
                selection: selection,
                settings: settingsStore.settings,
                credential: credentialStore.credential(for: settingsStore.settings.defaultProvider)
            )

            Task {
                let snapshots = await self.translationQueue.waitUntilIdle()
                guard let snapshot = snapshots.first(where: { $0.id == jobID }) else { return }
                await MainActor.run {
                    self.consume(snapshot: snapshot)
                }
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            statusText = "Failed"
        }
    }

    func saveAPIKey(_ apiKey: String) {
        credentialStore.save(apiKey: apiKey, for: settingsStore.settings.defaultProvider)
    }

    private func consume(snapshot: TranslationJobSnapshot) {
        let recentJob = RecentTranslationJob(
            id: snapshot.id,
            preview: snapshot.preview,
            providerID: snapshot.providerID,
            status: snapshot.status,
            createdAt: snapshot.createdAt
        )
        settingsStore.appendRecentJob(recentJob)
        switch snapshot.status {
        case .succeeded, .copiedToClipboard:
            statusText = "Ready"
        case .failed:
            statusText = "Failed"
        default:
            statusText = "Idle"
        }
    }

    private func bindHotkeyChanges() {
        settingsStore.$settings
            .map(\.hotkey)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.refreshHotkey()
            }
            .store(in: &cancellables)
    }
}
