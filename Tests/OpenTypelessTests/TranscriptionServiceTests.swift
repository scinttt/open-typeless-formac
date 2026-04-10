import XCTest
@testable import OpenTypeless

final class TranscriptionServiceTests: XCTestCase {
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
