import XCTest
@testable import OpenTypeless

@MainActor
final class TranscriptionServiceTests: XCTestCase {
    func testTranscribeWithoutModelThrows() async {
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

    func testDefaultModelIsSmall() {
        XCTAssertEqual(TranscriptionService.modelName, "small")
    }
}
