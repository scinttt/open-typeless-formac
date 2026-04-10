import XCTest
@testable import OpenTypeless

final class HotkeyManagerTests: XCTestCase {
    func testDefaultConfig() {
        let manager = HotkeyManager()
        // Default: Right Alt (keyCode=61) for transcribe
        XCTAssertEqual(manager.config.transcribeKeyCode, 61)
        // Default: Control+D for translate
        XCTAssertEqual(manager.config.translateKeyCode, 2)
        XCTAssertTrue(manager.config.translateModifiers.contains(.maskControl))
    }

    func testCustomConfig() {
        let config = HotkeyManager.HotkeyConfig(
            transcribeKeyCode: 0,
            transcribeModifiers: .maskCommand,
            translateKeyCode: 3,
            translateModifiers: .maskControl
        )
        let manager = HotkeyManager(config: config)
        XCTAssertEqual(manager.config.transcribeKeyCode, 0)
        XCTAssertEqual(manager.config.translateKeyCode, 3)
        XCTAssertTrue(manager.config.transcribeModifiers.contains(.maskCommand))
        XCTAssertTrue(manager.config.translateModifiers.contains(.maskControl))
    }

    func testCallbackInitiallyNil() {
        let manager = HotkeyManager()
        XCTAssertNil(manager.onHotkeyPressed)
    }

    func testPauseResume() {
        let manager = HotkeyManager()
        manager.pause()
        manager.resume()
    }
}
