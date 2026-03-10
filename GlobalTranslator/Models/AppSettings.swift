import Carbon
import Foundation

enum HotkeyShortcut: String, Codable, CaseIterable, Equatable, Sendable, Identifiable {
    case commandShiftT
    case commandOptionT
    case controlOptionT

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .commandShiftT:
            return "Command + Shift + T"
        case .commandOptionT:
            return "Command + Option + T"
        case .controlOptionT:
            return "Control + Option + T"
        }
    }

    var carbonKeyCode: UInt32 { 17 }

    var carbonModifiers: UInt32 {
        switch self {
        case .commandShiftT:
            return UInt32(cmdKey | shiftKey)
        case .commandOptionT:
            return UInt32(cmdKey | optionKey)
        case .controlOptionT:
            return UInt32(controlKey | optionKey)
        }
    }
}

struct ProviderPreferences: Codable, Equatable, Sendable {
    var model: String?

    static let openAIDefault = ProviderPreferences(model: "gpt-4.1-mini")
    static let empty = ProviderPreferences(model: nil)
}

struct ProviderCredential: Equatable, Sendable {
    let providerID: String
    let apiKey: String
}

enum TranslationJobStatus: String, Codable, Equatable, Sendable {
    case queued
    case running
    case succeeded
    case failed
    case copiedToClipboard
}

struct RecentTranslationJob: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    let preview: String
    let providerID: String
    let status: TranslationJobStatus
    let createdAt: Date

    init(
        id: UUID = UUID(),
        preview: String,
        providerID: String,
        status: TranslationJobStatus,
        createdAt: Date = .now
    ) {
        self.id = id
        self.preview = preview
        self.providerID = providerID
        self.status = status
        self.createdAt = createdAt
    }
}

struct AppSettings: Codable, Equatable, Sendable {
    var targetLanguage: String
    var hotkey: HotkeyShortcut
    var defaultProvider: String
    var providerPreferences: [String: ProviderPreferences]
    var recentJobs: [RecentTranslationJob]

    init(
        targetLanguage: String = "English",
        hotkey: HotkeyShortcut = .commandShiftT,
        defaultProvider: String = "openai",
        providerPreferences: [String: ProviderPreferences] = ["openai": .openAIDefault],
        recentJobs: [RecentTranslationJob] = []
    ) {
        self.targetLanguage = targetLanguage
        self.hotkey = hotkey
        self.defaultProvider = defaultProvider
        self.providerPreferences = providerPreferences
        self.recentJobs = recentJobs
    }

    func preferences(for providerID: String) -> ProviderPreferences {
        providerPreferences[providerID] ?? .empty
    }
}
