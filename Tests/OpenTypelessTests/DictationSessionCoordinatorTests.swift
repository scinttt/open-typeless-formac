import XCTest
@testable import OpenTypeless

@MainActor
final class DictationSessionCoordinatorTests: XCTestCase {
    func testInitialStateIsIdle() {
        let appState = AppState()
        let coordinator = DictationSessionCoordinator(appState: appState)
        XCTAssertEqual(coordinator.appState.status, .idle)
    }

    func testToggleWhileProcessingIsIgnored() {
        let appState = AppState()
        let coordinator = DictationSessionCoordinator(appState: appState)
        // Manually set processing state
        appState.status = .processing
        // Toggle during processing should be ignored
        coordinator.handleToggle(action: .transcribe)
        XCTAssertEqual(appState.status, .processing)
    }

    func testStopAndProcessWhileIdleIsIgnored() {
        let appState = AppState()
        let coordinator = DictationSessionCoordinator(appState: appState)
        // stopAndProcess without recording should be ignored
        coordinator.stopAndProcess()
        XCTAssertEqual(appState.status, .idle)
    }
}
