import XCTest
@testable import OpenTypeless

final class TranslationServiceTests: XCTestCase {
    let service = TranslationService()

    func testDetectChineseText() {
        let target = service.detectTargetLanguage(text: "你好世界这是一段中文")
        XCTAssertEqual(target, .english)
    }

    func testDetectEnglishText() {
        let target = service.detectTargetLanguage(text: "Hello world this is English text")
        XCTAssertEqual(target, .chinese)
    }

    func testDetectMixedText() {
        let target = service.detectTargetLanguage(text: "Hello world 你好")
        XCTAssertNotNil(target)
    }

    func testDetectEmptyText() {
        let target = service.detectTargetLanguage(text: "")
        XCTAssertEqual(target, .chinese)
    }

    func testTranslationTargetCases() {
        XCTAssertEqual(TranslationTarget.allCases.count, 3)
        XCTAssertEqual(TranslationTarget.auto.displayName, "Auto (中↔英)")
    }

    func testTranslateWithoutAPIKeysThrows() async {
        let origDeepL = TranslationService.deepLAPIKey
        let origDeepSeek = TranslationService.deepSeekAPIKey
        defer {
            TranslationService.deepLAPIKey = origDeepL
            TranslationService.deepSeekAPIKey = origDeepSeek
        }

        TranslationService.deepLAPIKey = nil
        TranslationService.deepSeekAPIKey = nil

        do {
            _ = try await service.translate(text: "hello", target: .chinese)
            XCTFail("Should have thrown")
        } catch {
            XCTAssertTrue(error is TranslationError)
        }
    }
}
