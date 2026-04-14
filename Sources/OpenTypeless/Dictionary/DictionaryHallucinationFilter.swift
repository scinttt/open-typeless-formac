import Foundation

enum DictionaryHallucinationFilter {
    private static let lowAudioThreshold: Float = 0.18
    private static let shortResultTokenLimit = 2
    private static let shortResultCharacterLimit = 24
    private static let tokenPattern = #"[A-Za-z0-9]+(?:[.'-][A-Za-z0-9]+)*"#

    static func shouldSuppress(
        transcribedText: String,
        correctedText: String,
        peakLevel: Float,
        entries: [DictionaryEntry]
    ) -> Bool {
        guard peakLevel < lowAudioThreshold else { return false }
        guard isShortResult(correctedText) else { return false }

        let normalizedCorrected = normalizePhrase(correctedText)
        guard !normalizedCorrected.isEmpty else { return false }

        let activeEntryPhrases = Set(
            entries
                .filter(\.isEnabled)
                .map(\.text)
                .map(normalizePhrase)
                .filter { !$0.isEmpty }
        )
        guard activeEntryPhrases.contains(normalizedCorrected) else { return false }

        let normalizedTranscribed = normalizePhrase(transcribedText)
        return normalizedTranscribed.isEmpty || normalizedTranscribed != normalizedCorrected || isShortResult(transcribedText)
    }

    private static func isShortResult(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return tokenize(trimmed).count <= shortResultTokenLimit && trimmed.count <= shortResultCharacterLimit
    }

    private static func tokenize(_ text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: tokenPattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let swiftRange = Range(match.range, in: text) else { return nil }
            return String(text[swiftRange])
        }
    }

    private static func normalizePhrase(_ text: String) -> String {
        tokenize(text)
            .map {
                $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    .lowercased()
            }
            .joined(separator: " ")
    }
}
