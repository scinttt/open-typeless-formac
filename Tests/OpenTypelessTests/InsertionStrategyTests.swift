import XCTest
@testable import OpenTypeless

final class OutputTargetSnapshotTests: XCTestCase {
    func testSnapshotWithNoFocusedElement() {
        // In test environment, there's no focused AX element
        let snapshot = OutputTargetSnapshot(focusedElement: nil, appPID: nil)
        XCTAssertFalse(snapshot.hasTarget)
        XCTAssertFalse(snapshot.isValid())
    }

    func testSnapshotHasTarget() {
        // Create a snapshot with a dummy element
        let element = AXUIElementCreateSystemWide()
        let snapshot = OutputTargetSnapshot(focusedElement: element, appPID: 1234)
        XCTAssertTrue(snapshot.hasTarget)
        // isValid() will return false since system-wide element is not a text input
        XCTAssertFalse(snapshot.isValid())
    }
}

@MainActor
final class InsertionStrategyTests: XCTestCase {
    func testInsertWithNoTargetShowsPopup() async {
        let snapshot = OutputTargetSnapshot(focusedElement: nil, appPID: nil)
        let result = await InsertionStrategy.insert(text: "test", snapshot: snapshot)
        if case .showPopup(let text) = result {
            XCTAssertEqual(text, "test")
        } else {
            XCTFail("Expected showPopup result")
        }
    }
}
