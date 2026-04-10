import XCTest
@testable import OpenTypeless

@MainActor
final class AppStateTests: XCTestCase {
    func testInitialStateIsIdle() {
        let state = AppState()
        XCTAssertEqual(state.status, .idle)
    }

    func testMenuBarTitleMatchesStatus() {
        let state = AppState()

        state.status = .idle
        XCTAssertEqual(state.menuBarTitle, "Idle")

        state.status = .recording
        XCTAssertEqual(state.menuBarTitle, "Recording")

        state.status = .processing
        XCTAssertEqual(state.menuBarTitle, "Processing")

        state.status = .error
        XCTAssertEqual(state.menuBarTitle, "Error")
    }

    func testMenuBarIconMatchesStatus() {
        let state = AppState()

        state.status = .idle
        XCTAssertEqual(state.menuBarIcon, "mic")

        state.status = .recording
        XCTAssertEqual(state.menuBarIcon, "mic.fill")

        state.status = .processing
        XCTAssertEqual(state.menuBarIcon, "ellipsis.circle")

        state.status = .error
        XCTAssertEqual(state.menuBarIcon, "exclamationmark.triangle")
    }

    func testFlashError() {
        let state = AppState()
        state.flashError()
        XCTAssertEqual(state.status, .error)
    }
}
