import Foundation

enum ProviderRegistryError: LocalizedError {
    case unknownProvider(String)

    var errorDescription: String? {
        switch self {
        case let .unknownProvider(providerID):
            return "No provider registered with id '\(providerID)'."
        }
    }
}

struct ProviderRegistry: Sendable {
    private let providers: [String: any TranslationProvider]

    init(providers: [any TranslationProvider] = [OpenAIProvider(), DeepLProvider()]) {
        self.providers = Dictionary(uniqueKeysWithValues: providers.map { ($0.id, $0) })
    }

    func provider(for providerID: String) throws -> any TranslationProvider {
        guard let provider = providers[providerID] else {
            throw ProviderRegistryError.unknownProvider(providerID)
        }

        return provider
    }

    func descriptor(for providerID: String) -> ProviderDescriptor? {
        providers[providerID]?.descriptor
    }

    var availableProviders: [ProviderDescriptor] {
        providers.values.map(\.descriptor).sorted { $0.id < $1.id }
    }
}
