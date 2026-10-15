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
        XCTAssertLessThan(abs(app.buttons["pc.party.slot.5"].frame.maxY - app.buttons["pc.box.slot.29"].frame.maxY), 16, "Party and box must end on the same row")
        app.buttons["pc.box.slot.0"].press(forDuration: 0.05, thenDragTo: app.buttons["pc.party.slot.0"])
        expect(app.buttons["pc.party.slot.0"], value: "drag-a")
        expect(app.buttons["pc.box.slot.0"], value: "drag-c")
        app.buttons["pc.party.slot.0"].press(forDuration: 0.05, thenDragTo: app.buttons["pc.box.slot.12"])
        expect(app.buttons["pc.box.slot.12"], value: "drag-a")
        expect(app.buttons["pc.party.slot.0"], value: "Empty")
    }
    func testDropOutsideStorageKeepsOriginalSlot() {
        app.buttons["pc.box.slot.0"].press(forDuration: 0.05, thenDragTo: app.buttons["Collection options"])
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
        let ribbonTab = app.buttons["passport.tab.ribbons"]
        XCTAssertTrue(ribbonTab.waitForExistence(timeout: 5)); ribbonTab.tap(); review.tap()
        XCTAssertFalse(app.buttons["ribbons.transfer.add.footprint-ribbon"].exists)
        XCTAssertTrue(app.buttons["ribbons.transfer.add.legend-ribbon"].exists)
    }
}

final class RecoveryHistoryUITests: XCTestCase {
    private var app: XCUIApplication!
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication(); app.launchEnvironment["RibbonPassportInteractionTest"] = "recovery"; app.launch()
        app.tabBars.buttons["Settings"].tap()
        let history = app.buttons["recovery.open"]
        XCTAssertTrue(history.waitForExistence(timeout: 5)); history.tap()
    }
    override func tearDownWithError() throws { app.terminate(); app = nil }
    private func preview(_ id: String) {
        let item = app.buttons["recovery.item.pokemon.\(id)"]
        XCTAssertTrue(item.waitForExistence(timeout: 5)); item.tap()
        let version = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "recovery.version.")).firstMatch
        XCTAssertTrue(version.waitForExistence(timeout: 5)); version.tap()
    }
    private func restore() {
        let button = app.buttons["recovery.restore"]
        for _ in 0..<8 {
            if button.exists && button.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(button.isHittable); button.tap()
        XCTAssertTrue(app.staticTexts["recovery.restored"].waitForExistence(timeout: 5))
    }
    func testRecoverDeletedPokemonReturnsToPCBox() {
        preview("drag-b"); restore()
        app.tabBars.buttons["Ribbons"].tap()
        let slot = app.buttons["pc.box.slot.1"]
        XCTAssertTrue(slot.waitForExistence(timeout: 5)); XCTAssertEqual(slot.value as? String, "drag-b")
    }
    func testFiltersSeparateDeletedItemsAndSavedVersions() {
        app.buttons["Deleted"].tap()
        XCTAssertTrue(app.buttons["recovery.item.pokemon.drag-b"].exists)
        XCTAssertFalse(app.buttons["recovery.item.pokemon.drag-a"].exists)
        app.buttons["Versions"].tap()
        XCTAssertTrue(app.buttons["recovery.item.pokemon.drag-a"].exists)
        XCTAssertFalse(app.buttons["recovery.item.pokemon.drag-b"].exists)
        app.buttons["All"].tap()
        XCTAssertTrue(app.buttons["recovery.item.pokemon.drag-a"].exists)
        XCTAssertTrue(app.buttons["recovery.item.pokemon.drag-b"].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = "recovery-from-settings"; attachment.lifetime = .keepAlways; add(attachment)
    }
    func testRestoreEarlierDetailsKeepsReplacedVersion() {
        preview("drag-a"); restore()
        app.navigationBars.buttons["Saved versions"].tap()
        XCTAssertTrue(app.staticTexts["Before restore"].waitForExistence(timeout: 5))
        let version = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "recovery.version.")).firstMatch
        version.tap()
        XCTAssertTrue(app.staticTexts["Edited Metagross"].waitForExistence(timeout: 5))
        restore()
    }
}

final class TerminalPassportUITests: XCTestCase {
    private var app: XCUIApplication!
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication(); app.launchEnvironment["RibbonPassportInteractionTest"] = "transfer"; app.launch()
        XCTAssertTrue(app.buttons["pc.box.slot.0"].waitForExistence(timeout: 10))
    }
    override func tearDownWithError() throws { app.terminate(); app = nil }
    private func capture(_ name: String) {
        let image = XCTAttachment(screenshot: app.screenshot()); image.name = name; image.lifetime = .keepAlways; add(image)
    }
    func testPassportTabsSaveRibbonChangesAcrossNavigation() {
        capture("terminal-home")
        app.buttons["Passport ▸"].tap()
        let owned = app.buttons["passport.owned"]
        XCTAssertTrue(owned.waitForExistence(timeout: 5))
        let before = owned.label
        capture("passport-overview")
        app.buttons["passport.tab.ribbons"].tap()
        let drawer = app.buttons["ribbons.owned"]
        if !drawer.isHittable { app.swipeUp() }
        XCTAssertTrue(drawer.waitForExistence(timeout: 5)); drawer.tap()
        let remove = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Remove ")).firstMatch
        XCTAssertTrue(remove.waitForExistence(timeout: 5)); remove.tap()
        app.navigationBars.buttons["Done"].tap()
        app.buttons["passport.tab.journey"].tap()
        XCTAssertTrue(app.segmentedControls["album.grouping"].waitForExistence(timeout: 5))
        capture("passport-journey")
        app.buttons["passport.tab.overview"].tap()
        XCTAssertNotEqual(owned.label, before)
        let changed = owned.label
        app.buttons["passport.tab.ribbons"].tap()
        capture("passport-ribbons")
        app.buttons["ribbons.save"].tap()
        XCTAssertEqual(owned.label, changed)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["pc.box.slot.0"].waitForExistence(timeout: 5))
        app.buttons["Passport ▸"].tap()
        XCTAssertEqual(owned.label, changed)
    }
    func testOverviewRibbonTapShowsThatRibbonsDescriptionWithoutEditing() {
        app.buttons["Passport ▸"].tap()
        let owned = app.buttons["passport.owned"]
        XCTAssertTrue(owned.waitForExistence(timeout: 5))
        let originalCount = owned.label
        let examples = [
            ("tough-ribbon-ultra-sinnoh", "Super Contest Tough Category Ultra Rank winner!"),
            ("tough-ribbon-master-sinnoh", "Super Contest Tough Category Master Rank winner!")
        ]
        for (id, description) in examples {
            let ribbon = app.buttons["passport.ribbon.\(id)"]
            XCTAssertTrue(ribbon.exists)
            let name = ribbon.label
            ribbon.tap()
            let text = app.staticTexts["ribbon.description.text"]
            XCTAssertTrue(text.waitForExistence(timeout: 5))
            XCTAssertEqual(text.label, description)
            XCTAssertEqual(app.staticTexts["ribbon.description.name"].label, name)
            XCTAssertFalse(app.buttons["ribbons.owned"].exists)
            XCTAssertFalse(app.buttons["ribbons.save"].exists)
            capture("owned-description-" + id)
            app.buttons["ribbon.description.done"].tap()
            XCTAssertTrue(owned.waitForExistence(timeout: 5))
            XCTAssertEqual(owned.label, originalCount)
        }
    }
    func testWallpaperSelectionPersistsAndDoesNotChangeOtherBoxes() {
        app.buttons["pc.boxOptions"].tap(); app.buttons["Wallpaper"].tap()
        let simple = app.buttons["pc.wallpaper.sm16"]
        for _ in 0..<10 { if simple.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(simple.isHittable); simple.tap()
        app.navigationBars.buttons["Save"].tap()
        app.buttons["pc.boxOptions"].tap(); app.buttons["Wallpaper"].tap()
        for _ in 0..<10 { if simple.isHittable { break }; app.swipeUp() }
        XCTAssertEqual(simple.value as? String, "Selected")
        capture("sunmoon-wallpaper-selection")
        app.navigationBars.buttons["Cancel"].tap()
        app.buttons["Next box"].tap()
        app.buttons["pc.boxOptions"].tap(); app.buttons["Wallpaper"].tap()
        XCTAssertEqual(app.buttons["pc.wallpaper.sm02"].value as? String, "Selected")
    }
}
