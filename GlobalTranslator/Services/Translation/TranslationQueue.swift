import Foundation

actor TranslationQueue {
    private struct QueuedJob {
        let id: UUID
        let selection: CapturedSelection
        let settings: AppSettings
        let credential: ProviderCredential?
        let createdAt: Date
    }

    private let providerRegistry: ProviderRegistry
    private let writebackService: WritebackService
    private let notificationCenter: any UserNotificationCentering

    private var pendingJobs: [QueuedJob] = []
    private var completedJobs: [TranslationJobSnapshot] = []
    private var isProcessing = false

    init(
        providerRegistry: ProviderRegistry,
        writebackService: WritebackService,
        notificationCenter: any UserNotificationCentering
    ) {
        self.providerRegistry = providerRegistry
        self.writebackService = writebackService
        self.notificationCenter = notificationCenter
    }

    @discardableResult
    func enqueue(
        selection: CapturedSelection,
        settings: AppSettings,
        credential: ProviderCredential?
    ) -> UUID {
        let job = QueuedJob(
            id: UUID(),
            selection: selection,
            settings: settings,
            credential: credential,
            createdAt: .now
        )
        pendingJobs.append(job)
        if !isProcessing {
            isProcessing = true
            Task {
                await processLoop()
            }
        }

        return job.id
    }

    func waitUntilIdle() async -> [TranslationJobSnapshot] {
        while isProcessing || !pendingJobs.isEmpty {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return completedJobs
    }

    private func processLoop() async {
        while !pendingJobs.isEmpty {
            let job = pendingJobs.removeFirst()
            let status = await process(job)
            completedJobs.append(
                TranslationJobSnapshot(
                    id: job.id,
                    preview: String(job.selection.selectedText.prefix(32)),
                    providerID: job.settings.defaultProvider,
                    status: status,
                    createdAt: job.createdAt
                )
            )
        }

        isProcessing = false
    }

    private func process(_ job: QueuedJob) async -> TranslationJobStatus {
        do {
            let provider = try providerRegistry.provider(for: job.settings.defaultProvider)
            if provider.descriptor.requiresStoredCredential, job.credential == nil {
                await notificationCenter.notify(
                    title: "Missing API key",
                    body: "Add an API key before running translations."
                )
                return .failed
            }
            let response = try await provider.translate(
                TranslationRequest(
                    text: job.selection.selectedText,
                    targetLanguage: job.settings.targetLanguage
                ),
                credential: job.credential,
                preferences: job.settings.preferences(for: job.settings.defaultProvider)
            )
            let outcome = await MainActor.run {
                writebackService.write(response.translatedText, for: job.selection)
            }
            if outcome == .copiedToClipboard {
                await notificationCenter.notify(
                    title: "Translation copied to clipboard",
                    body: "The original field changed, so the result was copied instead."
                )
            }
            return outcome == .succeeded ? .succeeded : .copiedToClipboard
        } catch {
            await notificationCenter.notify(
                title: "Translation failed",
                body: error.localizedDescription
            )
            return .failed
        }
    }
}
