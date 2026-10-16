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
        app.buttons["navigation.tab.2"].tap()
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
        app.buttons["navigation.tab.0"].tap()
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
        app.buttons["navigation.back"].tap()
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
    func testAllGamesResetsCategoryAndShowsScopeFeedback() {
        app.buttons["Passport ▸"].tap()
        app.buttons["passport.tab.ribbons"].tap()
        let all = app.buttons["ribbons.allGames"]
        XCTAssertTrue(all.waitForExistence(timeout: 5))
        XCTAssertEqual(all.value as? String, "Off")
        app.buttons["Last chance"].tap()
        all.tap()
        XCTAssertEqual(all.value as? String, "On")
        XCTAssertTrue(all.isSelected)
        let count = app.staticTexts["ribbons.resultCount"]
        XCTAssertTrue(count.label.contains("All games"))
        XCTAssertTrue(app.buttons["All"].isSelected)
        app.switches["ribbons.earnable"].tap()
        XCTAssertTrue(count.label.contains("111 shown"))
        all.tap()
        XCTAssertEqual(all.value as? String, "Off")
        XCTAssertTrue(count.label.contains("This game"))
        XCTAssertFalse(count.label.contains("111 shown"))
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
        XCTAssertTrue(app.buttons["album.grouping.games"].waitForExistence(timeout: 5))
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
    func testOverviewRibbonBubbleSwitchesAndDismissesWithoutEditing() {
        app.buttons["Passport ▸"].tap()
        let owned = app.buttons["passport.owned"]
        XCTAssertTrue(owned.waitForExistence(timeout: 5))
        let originalCount = owned.label
        let examples = [
            ("tough-ribbon-ultra-sinnoh", "Tough Ribbon Ultra", "Super Contest Tough Category Ultra Rank winner!"),
            ("tough-ribbon-master-sinnoh", "Tough Ribbon Master", "Super Contest Tough Category Master Rank winner!")
        ]
        for (id, name, description) in examples {
            let ribbon = app.buttons["passport.ribbon.\(id)"]
            XCTAssertTrue(ribbon.exists); ribbon.tap()
            let text = app.staticTexts["ribbon.description.text"]
            let found = text.waitForExistence(timeout: 5)
            if !found { capture("bubble-not-found"); print(app.debugDescription) }
            XCTAssertTrue(found)
            XCTAssertEqual(text.label, description)
            XCTAssertEqual(app.staticTexts["ribbon.description.name"].label, name)
            XCTAssertEqual(ribbon.value as? String, "Description shown")
            let nameFrame = app.staticTexts["ribbon.description.name"].frame
            XCTAssertGreaterThanOrEqual(nameFrame.minX, app.frame.minX)
            XCTAssertLessThanOrEqual(nameFrame.maxX, app.frame.maxX)
            XCTAssertFalse(app.buttons["ribbons.save"].exists)
            XCTAssertFalse(app.buttons["ribbon.description.done"].exists)
            capture("owned-ribbon-bubble-" + id)
        }
        // The second ribbon was selected directly while the first bubble remained open.
        let selected = app.buttons["passport.ribbon.tough-ribbon-master-sinnoh"]
        selected.tap()
        XCTAssertFalse(app.staticTexts["ribbon.description.text"].exists)
        selected.tap()
        XCTAssertTrue(app.staticTexts["ribbon.description.text"].waitForExistence(timeout: 5))
        // Tap blank space well below the ribbons and transfer status.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.82)).tap()
        XCTAssertFalse(app.staticTexts["ribbon.description.text"].exists)
        XCTAssertEqual(owned.label, originalCount)
        app.buttons["passport.tab.journey"].tap()
        XCTAssertTrue(app.buttons["album.grouping.games"].waitForExistence(timeout: 5))
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

final class MemoryRibbonUITests: XCTestCase {
    func testModernPassportAndOwnedDrawerConsolidateButKeepOriginalsEditable() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchEnvironment["RibbonPassportInteractionTest"] = "memory"; app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.buttons["pc.box.slot.0"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["ribbons.manage"].label.contains("3 ribbons"))
        app.buttons["Passport ▸"].tap()
        let owned = app.buttons["passport.owned"]
        XCTAssertTrue(owned.waitForExistence(timeout: 5))
        let count = owned.label
        XCTAssertTrue(count.contains("3"))
        XCTAssertTrue(app.buttons["passport.ribbon.contest-memory-ribbon"].exists)
        XCTAssertTrue(app.buttons["passport.ribbon.battle-memory-ribbon"].exists)
        XCTAssertFalse(app.buttons["passport.ribbon.winning-ribbon"].exists)
        XCTAssertFalse(app.buttons["passport.ribbon.cool-ribbon-hoenn"].exists)
        app.buttons["passport.ribbon.battle-memory-ribbon"].tap()
        XCTAssertTrue(app.staticTexts["ribbon.description.text"].waitForExistence(timeout: 5))
        app.buttons["passport.ribbon.battle-memory-ribbon"].tap()
        let image = XCTAttachment(screenshot: app.screenshot()); image.name = "modern-passport-memory-ribbons"; image.lifetime = .keepAlways; add(image)
        app.buttons["passport.tab.ribbons"].tap()
        let drawer = app.buttons["ribbons.owned"]
        if !drawer.isHittable { app.swipeUp() }
        XCTAssertTrue(drawer.waitForExistence(timeout: 5)); drawer.tap()
        let battle = app.buttons["ribbons.memory.battle-memory-ribbon"]
        XCTAssertTrue(battle.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["ribbons.memory.contest-memory-ribbon"].exists)
        let winning = app.buttons["ribbons.owned.remove.winning-ribbon"]
        XCTAssertFalse(winning.exists)
        battle.tap()
        XCTAssertTrue(winning.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["ribbons.owned.remove.ability-ribbon"].exists)
        winning.tap()
        XCTAssertFalse(winning.exists)
        XCTAssertTrue(battle.exists)
        app.buttons["ribbons.owned.undo"].tap()
        let restored = winning.waitForExistence(timeout: 5)
        if !restored {
            let image = XCTAttachment(screenshot: app.screenshot()); image.name = "memory-undo-state"; image.lifetime = .keepAlways; add(image)
            print(app.debugDescription)
        }
        XCTAssertTrue(restored)
        app.navigationBars.buttons["Done"].tap()
        app.buttons["passport.tab.overview"].tap()
        XCTAssertEqual(owned.label, count)
    }
}

final class MarkAndNavigationUITests: XCTestCase {
    func testOptionalSizeMarksAndCustomOptionBoards() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchEnvironment["RibbonPassportInteractionTest"] = "marks"; app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.buttons["Passport ▸"].waitForExistence(timeout: 10)); app.buttons["Passport ▸"].tap()
        app.buttons["passport.tab.ribbons"].tap()
        app.buttons["ribbons.sizeMarks"].tap()
        XCTAssertTrue(app.staticTexts["ribbons.sizeMarks.optional"].waitForExistence(timeout: 5))
        app.buttons["Confirmed size: Jumbo"].tap()
        let mini = app.buttons["Mini"]
        XCTAssertTrue(mini.waitForExistence(timeout: 5)); mini.tap()
        let add = app.buttons["ribbons.size.add.mini-mark.scar"]
        XCTAssertTrue(add.waitForExistence(timeout: 5)); add.tap()
        let remove = app.buttons["ribbons.size.remove.mini-mark"]
        XCTAssertTrue(remove.waitForExistence(timeout: 5)); remove.tap()
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot()); screenshot.name = "optional-size-marks"; screenshot.lifetime = .keepAlways; self.add(screenshot)
        app.buttons["Close"].tap()
        app.buttons["Passport options"].tap()
        let edit = app.buttons["Edit Pokémon"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5)); edit.tap()
        XCTAssertTrue(app.navigationBars.buttons["Save"].waitForExistence(timeout: 5)); app.navigationBars.buttons["Save"].tap()
        XCTAssertTrue(app.buttons["passport.tab.journey"].waitForExistence(timeout: 5)); app.buttons["passport.tab.journey"].tap()
        XCTAssertTrue(app.buttons["album.grouping.games"].waitForExistence(timeout: 5)); app.buttons["album.grouping.games"].tap()
        XCTAssertTrue(app.buttons["album.grouping.games"].isSelected)
    }

    func testEarnableMarksAndCustomNavigation() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchEnvironment["RibbonPassportInteractionTest"] = "marks"; app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.buttons["Passport ▸"].waitForExistence(timeout: 10))
        app.buttons["Passport ▸"].tap()
        app.buttons["passport.tab.ribbons"].tap()
        let partner = app.buttons["ribbons.tile.partner-mark"]
        XCTAssertTrue(partner.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["ribbons.tile.itemfinder-mark"].exists)
        XCTAssertTrue(app.buttons["ribbons.tile.gourmand-mark"].exists)
        XCTAssertTrue(app.buttons["ribbons.tile.jumbo-mark"].exists)
        XCTAssertFalse(app.buttons["ribbons.tile.mini-mark"].exists)
        partner.tap()
        XCTAssertFalse(partner.exists)
        app.buttons["ribbons.owned"].tap()
        let remove = app.buttons["ribbons.owned.remove.partner-mark"]
        XCTAssertTrue(remove.waitForExistence(timeout: 5))
        remove.tap()
        app.navigationBars.buttons["Done"].tap()
        XCTAssertTrue(partner.waitForExistence(timeout: 5))
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "pixel-navigation-and-earnable-marks"; shot.lifetime = .keepAlways; add(shot)
        app.buttons["navigation.back"].tap()
        XCTAssertTrue(app.buttons["Passport ▸"].waitForExistence(timeout: 5))
        app.buttons["navigation.tab.2"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        app.buttons["navigation.tab.0"].tap()
        XCTAssertTrue(app.buttons["Passport ▸"].waitForExistence(timeout: 5))
    }
}
