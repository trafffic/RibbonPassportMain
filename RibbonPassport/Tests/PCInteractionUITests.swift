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

final class RibbonTransferUITests: XCTestCase {
    func testTransferChecklistRecordsSpecificGamesUpdatesWarningAndUndo() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["RibbonPassportInteractionTest"] = "transfer"
        app.launch()
        defer { app.terminate() }
        let manage = app.buttons["ribbons.manage"]
        XCTAssertTrue(manage.waitForExistence(timeout: 10)); manage.tap()
        let review = app.buttons["ribbons.transfer.review"]
        XCTAssertTrue(review.waitForExistence(timeout: 8))
        XCTAssertTrue(review.label.contains("Not safe to leave Gen IV"))
        review.tap()
        let footprint = app.buttons["ribbons.transfer.add.footprint-ribbon"]
        XCTAssertTrue(footprint.waitForExistence(timeout: 5)); footprint.tap()
        XCTAssertTrue(app.buttons["ribbons.transfer.add.pair-ability-ribbon"].waitForExistence(timeout: 5))
        app.buttons["ribbons.transfer.add.pair-ability-ribbon"].tap()
        app.buttons["ribbons.transfer.add.legend-ribbon"].tap()
        let heartGold = app.buttons["ribbons.game.hg"]
        if !heartGold.waitForExistence(timeout: 5) { print(app.debugDescription) }
        XCTAssertTrue(heartGold.exists); heartGold.tap()
        let status = app.descendants(matching: .any).matching(identifier: "ribbons.transfer.status").firstMatch
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertTrue(status.label.contains("Safe to leave Gen IV"))
        app.buttons["ribbons.transfer.undo"].tap()
        XCTAssertTrue(app.buttons["ribbons.transfer.add.legend-ribbon"].waitForExistence(timeout: 5))
        XCTAssertTrue(status.label.contains("1 last-chance ribbon remains"))
        app.buttons["ribbons.transfer.done"].tap()
        XCTAssertTrue(review.label.contains("Not safe to leave Gen IV"))
        app.buttons["ribbons.save"].tap()
        XCTAssertTrue(manage.waitForExistence(timeout: 5)); manage.tap(); review.tap()
        XCTAssertFalse(app.buttons["ribbons.transfer.add.footprint-ribbon"].exists)
        XCTAssertTrue(app.buttons["ribbons.transfer.add.legend-ribbon"].exists)
    }
}
