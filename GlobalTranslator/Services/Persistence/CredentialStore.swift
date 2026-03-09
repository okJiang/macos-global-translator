import Combine
import Foundation
import Security

@MainActor
final class CredentialStore: ObservableObject {
    private let secretStore: SecretStoring

    init(secretStore: SecretStoring = KeychainSecretStore()) {
        self.secretStore = secretStore
    }

    func credential(for providerID: String) -> ProviderCredential? {
        guard let apiKey = try? secretStore.readSecret(for: providerID) else {
            return nil
        }

        return ProviderCredential(providerID: providerID, apiKey: apiKey)
    }

    func apiKey(for providerID: String) -> String {
        (try? secretStore.readSecret(for: providerID)) ?? ""
    }

    func save(apiKey: String, for providerID: String) {
        try? secretStore.writeSecret(apiKey, for: providerID)
        objectWillChange.send()
    }
}

struct KeychainSecretStore: SecretStoring {
    private let service = "com.okjiang.globaltranslator.credentials"

    func readSecret(for key: String) throws -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
        guard let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func writeSecret(_ value: String, for key: String) throws {
        let encoded = Data(value.utf8)
        let baseQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
        ]

        let update: [CFString: Any] = [kSecValueData: encoded]
        let status = SecItemUpdate(baseQuery as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = baseQuery
            addQuery[kSecValueData] = encoded
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(addStatus))
            }
            return
        }
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
}
