import Foundation

enum TargetLanguageResolutionError: LocalizedError, Equatable {
    case unsupported(rawValue: String, providerID: String)

    var errorDescription: String? {
        switch self {
        case let .unsupported(rawValue, providerID):
            return "Unsupported target language '\(rawValue)' for provider '\(providerID)'."
        }
    }
}

struct TargetLanguageResolver: Sendable {
    func resolve(_ rawValue: String, for providerID: String) throws -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw TargetLanguageResolutionError.unsupported(rawValue: rawValue, providerID: providerID)
        }

        switch providerID {
        case "deepl":
            return try resolveDeepL(trimmed)
        case "google":
            return try resolveGoogle(trimmed)
        default:
            return trimmed
        }
    }

    private func resolveDeepL(_ rawValue: String) throws -> String {
        let normalized = normalize(rawValue)
        if let variant = Self.deepLVariantAliases[normalized] {
            return variant
        }

        guard let code = canonicalLanguageCode(from: rawValue) else {
            throw TargetLanguageResolutionError.unsupported(rawValue: rawValue, providerID: "deepl")
        }

        let deepLCode = code.uppercased()
        guard Self.deepLSupportedBaseCodes.contains(deepLCode) else {
            throw TargetLanguageResolutionError.unsupported(rawValue: rawValue, providerID: "deepl")
        }

        return deepLCode
    }

    private func resolveGoogle(_ rawValue: String) throws -> String {
        let normalized = normalize(rawValue)
        if let alias = Self.googleAliases[normalized] {
            return alias
        }

        guard let code = canonicalLanguageCode(from: rawValue) else {
            throw TargetLanguageResolutionError.unsupported(rawValue: rawValue, providerID: "google")
        }

        return code.lowercased()
    }

    private func canonicalLanguageCode(from rawValue: String) -> String? {
        let normalized = normalize(rawValue)
        if let alias = Self.commonLanguageAliases[normalized] {
            return alias
        }

        let normalizedCode = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-")
            .first
            .map(String.init)?
            .lowercased()
        if let normalizedCode, Self.isoLanguageCodes.contains(normalizedCode) {
            return normalizedCode
        }

        let locale = Locale(identifier: "en_US_POSIX")
        for code in Self.isoLanguageCodes {
            guard let localizedName = locale.localizedString(forLanguageCode: code) else {
                continue
            }
            if normalize(localizedName) == normalized {
                return code
            }
        }

        return nil
    }

    private func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: " ", with: "-")
    }

    private static let commonLanguageAliases: [String: String] = [
        "arabic": "ar",
        "bulgarian": "bg",
        "chinese": "zh",
        "chinese-simplified": "zh",
        "chinese-traditional": "zh",
        "czech": "cs",
        "danish": "da",
        "dutch": "nl",
        "english": "en",
        "estonian": "et",
        "finnish": "fi",
        "french": "fr",
        "german": "de",
        "greek": "el",
        "hungarian": "hu",
        "indonesian": "id",
        "italian": "it",
        "japanese": "ja",
        "korean": "ko",
        "latvian": "lv",
        "lithuanian": "lt",
        "norwegian": "no",
        "polish": "pl",
        "portuguese": "pt",
        "romanian": "ro",
        "russian": "ru",
        "slovak": "sk",
        "slovenian": "sl",
        "spanish": "es",
        "swedish": "sv",
        "turkish": "tr",
        "ukrainian": "uk",
    ]

    private static let deepLSupportedBaseCodes: Set<String> = [
        "AR", "BG", "CS", "DA", "DE", "EL", "EN", "ES", "ET", "FI", "FR",
        "HU", "ID", "IT", "JA", "KO", "LT", "LV", "NB", "NL", "PL", "PT",
        "RO", "RU", "SK", "SL", "SV", "TR", "UK", "ZH",
    ]

    private static let deepLVariantAliases: [String: String] = [
        "en-gb": "EN-GB",
        "en-us": "EN-US",
        "pt-br": "PT-BR",
        "pt-pt": "PT-PT",
        "zh-hans": "ZH-HANS",
        "zh-hant": "ZH-HANT",
    ]

    private static let googleAliases: [String: String] = [
        "zh-hans": "zh-CN",
        "zh-hant": "zh-TW",
    ]

    private static let isoLanguageCodes = Set(Locale.LanguageCode.isoLanguageCodes.map(\.identifier))
}
