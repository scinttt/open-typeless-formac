import XCTest
@testable import OpenTypeless

final class DictionaryHallucinationFilterTests: XCTestCase {
    func testSuppressesShortDictionaryMatchAtLowAudioLevel() {
        let shouldSuppress = DictionaryHallucinationFilter.shouldSuppress(
            transcribedText: "cloud code",
            correctedText: "Claude Code",
            peakLevel: 0.12,
            entries: [DictionaryEntry(text: "Claude Code")]
        )

        XCTAssertTrue(shouldSuppress)
    }

    func testDoesNotSuppressDictionaryMatchAtNormalAudioLevel() {
        let shouldSuppress = DictionaryHallucinationFilter.shouldSuppress(
            transcribedText: "Claude Code",
            correctedText: "Claude Code",
            peakLevel: 0.3,
            entries: [DictionaryEntry(text: "Claude Code")]
        )

        XCTAssertFalse(shouldSuppress)
    }

    func testDoesNotSuppressUnrelatedShortText() {
        let shouldSuppress = DictionaryHallucinationFilter.shouldSuppress(
            transcribedText: "hello there",
            correctedText: "hello there",
            peakLevel: 0.1,
            entries: [DictionaryEntry(text: "Claude Code")]
        )

        XCTAssertFalse(shouldSuppress)
    }

    func testDoesNotSuppressLongSentenceEvenIfItContainsDictionaryWord() {
        let shouldSuppress = DictionaryHallucinationFilter.shouldSuppress(
            transcribedText: "please open Claude Code and continue with the task",
            correctedText: "please open Claude Code and continue with the task",
            peakLevel: 0.1,
            entries: [DictionaryEntry(text: "Claude Code")]
        )

        XCTAssertFalse(shouldSuppress)
    }

    func testDisabledEntriesAreIgnored() {
        let shouldSuppress = DictionaryHallucinationFilter.shouldSuppress(
            transcribedText: "Claude Code",
            correctedText: "Claude Code",
            peakLevel: 0.1,
            entries: [DictionaryEntry(text: "Claude Code", isEnabled: false)]
        )

        XCTAssertFalse(shouldSuppress)
    }
}
