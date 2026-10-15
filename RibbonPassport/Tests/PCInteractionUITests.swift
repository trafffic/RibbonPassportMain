import XCTest

final class PCInteractionUITests: XCTestCase {
    private var app: XCUIApplication!
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["RibbonPassportInteractionTest"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["pc.box.slot.0"].waitForExistence(timeout: 10))
    }
    override func tearDownWithError() throws { app.terminate(); app = nil }
    private func expect(_ element: XCUIElement, value: String, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "value == %@", value)
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: 4)
        XCTAssertEqual(result, .completed, file: file, line: line)
    }
    func testDragToEmptySlotAndSwapOccupiedSlots() {
        app.buttons["pc.box.slot.0"].press(forDuration: 0.05, thenDragTo: app.buttons["pc.box.slot.12"])
        expect(app.buttons["pc.box.slot.12"], value: "drag-a")
        expect(app.buttons["pc.box.slot.0"], value: "Empty")
        app.buttons["pc.box.slot.12"].press(forDuration: 0.05, thenDragTo: app.buttons["pc.box.slot.1"])
        expect(app.buttons["pc.box.slot.1"], value: "drag-a")
        expect(app.buttons["pc.box.slot.12"], value: "drag-b")
    }
    func testDragToPartySwapsAndBackToBoxWorks() {
        app.buttons["pc.box.slot.0"].press(forDuration: 0.05, thenDragTo: app.buttons["pc.party.slot.0"])
        expect(app.buttons["pc.party.slot.0"], value: "drag-a")
        expect(app.buttons["pc.box.slot.0"], value: "drag-c")
        app.buttons["pc.party.slot.0"].press(forDuration: 0.05, thenDragTo: app.buttons["pc.box.slot.12"])
        expect(app.buttons["pc.box.slot.12"], value: "drag-a")
        expect(app.buttons["pc.party.slot.0"], value: "Empty")
    }
    func testDropOutsideStorageKeepsOriginalSlot() {
        app.buttons["pc.box.slot.0"].press(forDuration: 0.05, thenDragTo: app.buttons["Teams"])
        expect(app.buttons["pc.box.slot.0"], value: "drag-a")
        expect(app.buttons["pc.box.slot.1"], value: "drag-b")
    }
    func testDropOnBoxArrowCancelsAfterHoveringAcrossBoxes() {
        app.buttons["pc.box.slot.0"].press(forDuration: 0.05, thenDragTo: app.buttons["Next box"], withVelocity: .slow, thenHoldForDuration: 1)
        expect(app.buttons["pc.box.slot.0"], value: "drag-a")
        expect(app.buttons["pc.box.slot.1"], value: "drag-b")
    }
}
