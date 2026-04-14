import XCTest
@testable import OpenTypeless

final class TranscriptionServiceTests: XCTestCase {
    func testLooksLikePromptEchoMatchesExactPrompt() {
        let prompt = "Prefer these spellings when they match the audio: Claude Code, ClaudeCode, skill, 读取."

        XCTAssertTrue(TranscriptionService.looksLikePromptEcho(prompt, prompt: prompt))
    }

    func testLooksLikePromptEchoMatchesPrefixEcho() {
        let prompt = "Prefer these spellings when they match the audio: Claude Code, Cursor."
        let echoed = "Prefer these spellings when they match the audio: Claude Code, Cursor"

        XCTAssertTrue(TranscriptionService.looksLikePromptEcho(echoed, prompt: prompt))
    }

    func testLooksLikePromptEchoIgnoresNormalTranscript() {
        let prompt = "Prefer these spellings when they match the audio: Claude Code, Cursor."

        XCTAssertFalse(
            TranscriptionService.looksLikePromptEcho("Claude Code fixed the issue", prompt: prompt)
        )
    }

    func testTranscribeWithoutAPIKeyThrows() async {
        let original = TranscriptionService.apiKey
        defer { TranscriptionService.apiKey = original }

        // Clear all sources of API key
        UserDefaults.standard.removeObject(forKey: "apiKey")
        TranscriptionService.apiKey = ""

        let service = TranscriptionService()
        let fakeURL = FileManager.default.temporaryDirectory.appendingPathComponent("fake.m4a")
        FileManager.default.createFile(atPath: fakeURL.path, contents: Data(), attributes: nil)
        defer { try? FileManager.default.removeItem(at: fakeURL) }

        do {
            _ = try await service.transcribe(audioURL: fakeURL)
            XCTFail("Should have thrown")
        } catch {
            XCTAssertTrue(error is TranscriptionError)
        }
    }

    func testDefaultModel() {
        XCTAssertEqual(TranscriptionService.model, "gpt-4o-mini-transcribe")
    }
}
