import Foundation

enum TranslationError: Error, LocalizedError {
    case noAPIKey(String)
    case networkError(Error)
    case apiError(statusCode: Int, message: String)
    case decodingError
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .noAPIKey(let service): return "\(service) API key not configured"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .apiError(let code, let message): return "API error (\(code)): \(message)"
        case .decodingError: return "Failed to decode translation response"
        case .emptyResult: return "Translation returned empty result"
        }
    }
}

enum TranslationTarget: String, CaseIterable, Identifiable {
    case english = "EN"
    case chinese = "ZH"
    case auto = "AUTO"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "Chinese"
        case .auto: return "Auto (中↔英)"
        }
    }
}

final class TranslationService {
    static var deepLAPIKey: String?
    static var deepSeekAPIKey: String?
    /// Fallback key for AI Builders Space chat/completions
    static var aiBuildersKey = ProcessInfo.processInfo.environment["AI_BUILDER_TOKEN"] ?? ""

    private let timeoutInterval: TimeInterval = 30

    func translate(text: String, target: TranslationTarget = .auto) async throws -> String {
        let resolvedTarget = target == .auto ? detectTargetLanguage(text: text) : target

        // Route: pure Chinese↔English → DeepL; otherwise → DeepSeek
        if shouldUseDeepL(text: text, target: resolvedTarget) {
            return try await translateWithDeepL(text: text, target: resolvedTarget)
        } else {
            return try await translateWithDeepSeek(text: text, target: resolvedTarget)
        }
    }

    // MARK: - Language Detection

    func detectTargetLanguage(text: String) -> TranslationTarget {
        let chineseRatio = chineseCharacterRatio(in: text)
        // If mostly Chinese, translate to English; otherwise translate to Chinese
        return chineseRatio > 0.3 ? .english : .chinese
    }

    private func chineseCharacterRatio(in text: String) -> Double {
        guard !text.isEmpty else { return 0 }
        let chineseCount = text.unicodeScalars.filter { scalar in
            (0x4E00...0x9FFF).contains(scalar.value) ||   // CJK Unified
            (0x3400...0x4DBF).contains(scalar.value) ||   // CJK Extension A
            (0xF900...0xFAFF).contains(scalar.value)      // CJK Compatibility
        }.count
        let totalChars = text.unicodeScalars.filter { !$0.properties.isWhitespace }.count
        guard totalChars > 0 else { return 0 }
        return Double(chineseCount) / Double(totalChars)
    }

    private func shouldUseDeepL(text: String, target: TranslationTarget) -> Bool {
        // Use DeepL for pure Chinese↔English
        let ratio = chineseCharacterRatio(in: text)
        let isPureChinese = ratio > 0.8
        let isPureEnglish = ratio < 0.05
        return (isPureChinese || isPureEnglish) && (target == .english || target == .chinese)
    }

    // MARK: - DeepL

    private func translateWithDeepL(text: String, target: TranslationTarget) async throws -> String {
        guard let apiKey = Self.deepLAPIKey else {
            return try await translateWithDeepSeek(text: text, target: target)
        }

        let url = URL(string: "https://api-free.deepl.com/v2/translate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval

        let body: [String: Any] = [
            "text": [text],
            "target_lang": target.rawValue,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw TranslationError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.networkError(URLError(.badServerResponse))
        }

        guard httpResponse.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TranslationError.apiError(statusCode: httpResponse.statusCode, message: message)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let translations = json["translations"] as? [[String: Any]],
              let translated = translations.first?["text"] as? String else {
            throw TranslationError.decodingError
        }

        return translated
    }

    // MARK: - DeepSeek

    private func translateWithDeepSeek(text: String, target: TranslationTarget) async throws -> String {
        // Use DeepSeek key if set, otherwise fallback to aibuilderspace with transcription key
        let apiKey = Self.deepSeekAPIKey ?? Self.aiBuildersKey
        guard !apiKey.isEmpty else {
            throw TranslationError.noAPIKey("Translation")
        }

        let targetLang = target == .english ? "English" : "Chinese"
        let systemPrompt = """
            You are a professional translator. Translate the following text to \(targetLang). \
            Output ONLY the translated text, no explanations or extra formatting.
            """

        let baseURL = Self.deepSeekAPIKey != nil
            ? "https://api.deepseek.com/chat/completions"
            : "https://space.ai-builders.com/backend/v1/chat/completions"
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval

        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text],
            ],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw TranslationError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.networkError(URLError(.badServerResponse))
        }

        guard httpResponse.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TranslationError.apiError(statusCode: httpResponse.statusCode, message: message)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw TranslationError.decodingError
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TranslationError.emptyResult }
        return trimmed
    }
}
