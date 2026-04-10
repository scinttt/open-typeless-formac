import XCTest
@testable import OpenTypeless

final class AudioRecorderTests: XCTestCase {
    func testStopWithoutStartThrows() {
        let recorder = AudioRecorder()
        XCTAssertThrowsError(try recorder.stopRecording()) { error in
            XCTAssertTrue(error is AudioRecorderError)
        }
    }

    func testCancelWithoutStartDoesNotCrash() {
        let recorder = AudioRecorder()
        recorder.cancel()
    }

    func testCleanUpNonexistentFile() {
        let fakeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent.wav")
        AudioRecorder.cleanUp(url: fakeURL)
    }
}
