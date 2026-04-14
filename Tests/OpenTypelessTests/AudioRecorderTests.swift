import XCTest
@testable import OpenTypeless

final class AudioRecorderTests: XCTestCase {
    func testSilentRecordingThresholdRejectsNearZeroPeak() {
        XCTAssertTrue(AudioRecorder.isSilentRecording(peakLevel: 0.01))
        XCTAssertTrue(AudioRecorder.isSilentRecording(peakLevel: 0.079))
    }

    func testSilentRecordingThresholdAllowsAudiblePeak() {
        XCTAssertFalse(AudioRecorder.isSilentRecording(peakLevel: 0.08))
        XCTAssertFalse(AudioRecorder.isSilentRecording(peakLevel: 0.2))
    }

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
