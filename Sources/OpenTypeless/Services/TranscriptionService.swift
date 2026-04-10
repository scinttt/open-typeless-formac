import Foundation

enum TranscriptionError: Error, LocalizedError {
    case noAPIKey
    case invalidURL
    case networkError(Error)
    case apiError(statusCode: Int, message: String)
    case decodingError
    case timeout

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "API key not configured"
        case .invalidURL: return "Invalid API URL"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .apiError(let code, let message): return "API error (\(code)): \(message)"
        case .decodingError: return "Failed to decode API response"
        case .timeout: return "Request timed out"
        }
    }
}

enum APIProvider: String, CaseIterable, Identifiable {
    case openAI = "openai"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .custom: return "Custom (OpenAI-compatible)"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .openAI: return "https://api.openai.com/v1/audio/transcriptions"
        case .custom: return ""
        }
    }
}

final class TranscriptionService {
    static var model = "gpt-4o-mini-transcribe"
    private let timeoutInterval: TimeInterval = 30
    private let maxRetries = 1

    static var apiKey = ProcessInfo.processInfo.environment["AI_BUILDER_TOKEN"]
        ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        ?? ""
    static var provider: APIProvider = .openAI
    static var customBaseURL: String = "https://space.ai-builders.com/backend/v1/audio/transcriptions"

    private var apiURL: String {
        switch Self.provider {
        case .openAI: return APIProvider.openAI.defaultBaseURL
        case .custom: return Self.customBaseURL
        }
    }

    func transcribe(audioURL: URL) async throws -> String {
        var lastError: Error = TranscriptionError.timeout
        for attempt in 0...maxRetries {
            do {
                return try await performTranscription(audioURL: audioURL)
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: 500_000_000)
                }
            }
        }
        throw lastError
    }

    func preload() {
        // No-op for remote API
    }

    private func performTranscription(audioURL: URL) async throws -> String {
        let apiKey = Self.apiKey
        guard !apiKey.isEmpty else { throw TranscriptionError.noAPIKey }

        guard let url = URL(string: apiURL) else {
            throw TranscriptionError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval

        let audioData = try Data(contentsOf: audioURL)
        let body = buildMultipartBody(boundary: boundary, audioData: audioData, fileName: audioURL.lastPathComponent)
        request.httpBody = body

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw TranscriptionError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.networkError(URLError(.badServerResponse))
        }

        guard httpResponse.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TranscriptionError.apiError(statusCode: httpResponse.statusCode, message: message)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            throw TranscriptionError.decodingError
        }

        return text
    }

    private func buildMultipartBody(boundary: String, audioData: Data, fileName: String) -> Data {
        var body = Data()

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        let contentType = fileName.hasSuffix(".m4a") ? "audio/mp4" : "audio/wav"
        body.append("Content-Type: \(contentType)\r\n\r\n")
        body.append(audioData)
        body.append("\r\n")

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        body.append("\(Self.model)\r\n")

        body.append("--\(boundary)--\r\n")

        return body
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
