import XCTest

final class CommunityScreensUITests: XCTestCase {
    private var app: XCUIApplication!
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication(); app.launchEnvironment["RibbonPassportInteractionTest"] = "community"; app.launch()
        XCTAssertTrue(app.buttons["pc.box.slot.0"].waitForExistence(timeout: 10))
    }
    override func tearDownWithError() throws { app.terminate(); app = nil }
    private func tap(_ element: XCUIElement) {
        _ = element.waitForExistence(timeout: 2)
        for _ in 0..<6 { if element.exists && element.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(element.exists)
        element.tap()
    }
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    private func passportJourney() {
        tap(app.buttons["Passport ▸"]); tap(app.buttons["passport.tab.journey"])
    }
    func testHonorRecordCanBeAddedEditedAndRemoved() {
        passportJourney(); tap(app.buttons["passport.honors"]); tap(app.buttons["honors.custom"])
        let title = app.textFields["honor.title"]; XCTAssertTrue(title.waitForExistence(timeout: 5)); title.tap(); title.typeText("First tournament")
        tap(app.buttons["honor.save"])
        let record = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "honors.record.")).firstMatch
        tap(record); XCTAssertEqual(app.textFields["honor.title"].value as? String, "First tournament")
        capture("community-honor-record")
        tap(app.buttons["honor.remove"])
        XCTAssertTrue(app.buttons["honors.custom"].waitForExistence(timeout: 5)); XCTAssertFalse(record.exists)
    }
    func testJourneyMemoryAndManualMoveNotesSave() {
        passportJourney(); tap(app.buttons["passport.notes"]); tap(app.buttons["journal.add"])
        let title = app.textFields["journal.title"]; XCTAssertTrue(title.waitForExistence(timeout: 5)); title.tap(); title.typeText("First visit")
        tap(app.buttons["journal.save"])
        let record = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "journal.entry.")).firstMatch
        tap(record); XCTAssertEqual(app.textFields["journal.title"].value as? String, "First visit")
        tap(app.buttons["navigation.back"].firstMatch)
        tap(app.buttons["Move Dex"]); tap(app.buttons["moves.add"])
        let move = app.textFields["move.name"]; XCTAssertTrue(move.waitForExistence(timeout: 5)); move.tap(); move.typeText("Meteor Mash")
        tap(app.buttons["move.save"])
        XCTAssertTrue(app.staticTexts["Meteor Mash"].waitForExistence(timeout: 5)); capture("community-move-notes")
    }
    func testGuidesAndSettingsCreditsShowOriginalAuthors() {
        passportJourney(); tap(app.buttons["passport.guides"])
        let guide = app.buttons["guide.bdsp-tower"]; tap(guide)
        XCTAssertTrue(app.staticTexts["guide.title"].waitForExistence(timeout: 5)); capture("community-field-guide")
        tap(app.buttons["Sources"])
        XCTAssertTrue(app.staticTexts[".athis"].waitForExistence(timeout: 5))
        tap(app.buttons["Settings"])
        tap(app.buttons["settings.credits"])
        let search = app.textFields["credits.search"]; XCTAssertTrue(search.waitForExistence(timeout: 5)); search.tap(); search.typeText("Peterko")
        tap(app.buttons["credits.source.peterko-paste"])
        XCTAssertTrue(app.staticTexts["source.author"].waitForExistence(timeout: 5)); XCTAssertEqual(app.staticTexts["source.author"].label, "Peterko")
        capture("community-author-credit")
    }
    func testCommunityTeamCopyAndBuildNotebook() {
        tap(app.buttons["Competitive"]); tap(app.buttons["Collection options"])
        tap(app.buttons["community.library.open"])
        let search = app.textFields["library.search"]; XCTAssertTrue(search.waitForExistence(timeout: 5)); search.tap(); search.typeText("Peterko")
        tap(app.buttons["library.team.iv-peterko"])
        XCTAssertEqual(app.staticTexts["team.author"].label, "By Peterko")
        tap(app.buttons["library.copy"])
        XCTAssertTrue(app.staticTexts["library.saved"].waitForExistence(timeout: 5))
        tap(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Open my copy")).firstMatch)
        tap(app.buttons["team.notebook"])
        let name = app.textFields["notebook.name"]; XCTAssertTrue(name.waitForExistence(timeout: 5)); name.tap(); name.typeText("First version")
        tap(app.buttons["notebook.save"])
        XCTAssertTrue(app.staticTexts["First version"].waitForExistence(timeout: 5)); capture("community-team-notebook")
    }
}

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

final class GuidedMoveUITests: XCTestCase {
    private var app: XCUIApplication!
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication(); app.launchEnvironment["RibbonPassportInteractionTest"] = "move"; app.launch()
        XCTAssertTrue(app.buttons["pc.box.slot.0"].waitForExistence(timeout: 10))
    }
    override func tearDownWithError() throws { app.terminate(); app = nil }
    private func tap(_ id: String) {
        let button = app.buttons[id]
        XCTAssertTrue(button.waitForExistence(timeout: 6), id)
        for _ in 0..<5 { if button.isHittable { break }; app.swipeUp() }
        button.tap()
    }
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    func testOverviewMoveChecksInAndUndoRestoresDeparture() {
        tap("Passport ▸"); tap("passport.transfer.review"); tap("ribbons.transfer.move")
        capture("guided-move-generation")
        tap("ribbons.move.generation.7"); tap("ribbons.move.next")
        XCTAssertFalse(app.buttons["ribbons.move.save"].isEnabled)
        tap("ribbons.move.game.usun"); capture("guided-move-game-selected")
        tap("ribbons.move.back"); tap("ribbons.move.generation.8"); tap("ribbons.move.next")
        XCTAssertFalse(app.buttons["ribbons.move.save"].isEnabled)
        XCTAssertTrue(app.buttons["ribbons.move.game.sw"].exists)
        XCTAssertFalse(app.buttons["ribbons.move.game.usun"].exists)
        tap("ribbons.move.back"); tap("ribbons.move.generation.7"); tap("ribbons.move.next")
        tap("ribbons.move.game.usun"); tap("ribbons.move.save")
        XCTAssertTrue(app.staticTexts["ribbons.move.recorded"].waitForExistence(timeout: 5)); capture("guided-move-recorded")
        tap("ribbons.move.undo"); tap("ribbons.move.cancel")
        XCTAssertTrue(app.buttons["ribbons.transfer.move"].waitForExistence(timeout: 5))
        tap("ribbons.transfer.done")
        XCTAssertTrue(app.staticTexts["Alpha Sapphire"].firstMatch.waitForExistence(timeout: 5))
    }
    func testRibbonTabMoveUpdatesPassportAndJourney() {
        tap("ribbons.manage"); tap("ribbons.transfer.review"); tap("ribbons.transfer.move")
        tap("ribbons.move.next"); tap("ribbons.move.game.usun"); tap("ribbons.move.save"); tap("ribbons.move.done")
        tap("passport.tab.overview")
        XCTAssertTrue(app.staticTexts["Ultra Sun"].firstMatch.waitForExistence(timeout: 5))
        capture("guided-move-passport-updated")
        tap("passport.tab.journey")
        XCTAssertTrue(app.buttons["album.game.as"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["album.game.usun"].exists)
        capture("guided-move-journey-updated")
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
        app.buttons["passport.tab.overview"].tap()
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
        app.buttons["passport.tab.overview"].tap()
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
        XCTAssertTrue(app.buttons["ribbons.manage"].label.contains("3 awards"))
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
    func testCornerControlsFitAndEarnableStaysSeparateFromAll() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchEnvironment["RibbonPassportInteractionTest"] = "marks"; app.launch()
        defer { app.terminate() }
        func checkCorner(_ button: XCUIElement) {
            XCTAssertTrue(button.waitForExistence(timeout: 5))
            XCTAssertTrue(button.isHittable)
            XCTAssertGreaterThanOrEqual(button.frame.width, 44)
            XCTAssertGreaterThanOrEqual(button.frame.height, 44)
            XCTAssertGreaterThanOrEqual(button.frame.minX, app.frame.minX)
            XCTAssertLessThanOrEqual(button.frame.maxX, app.frame.maxX)
        }
        checkCorner(app.buttons["Collection options"])
        app.buttons["Passport ▸"].tap()
        checkCorner(app.buttons["Passport options"])
        checkCorner(app.buttons["navigation.back"])
        app.buttons["passport.tab.ribbons"].tap()
        let earnable = app.switches["ribbons.earnable"]
        XCTAssertTrue(earnable.waitForExistence(timeout: 5))
        let all = app.buttons["ribbons.allGames"]
        XCTAssertLessThan(earnable.frame.maxX + 4, all.frame.minX)
        earnable.tap()
        XCTAssertTrue(app.buttons["ribbons.tile.mini-mark"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot()); screenshot.name = "corner-icons-and-earnable-spacing"; screenshot.lifetime = .keepAlways; add(screenshot)
        app.buttons["ribbons.owned"].tap()
        checkCorner(app.navigationBars.buttons["Done"])
        app.navigationBars.buttons["Done"].tap()
        app.buttons["Passport options"].tap()
        checkCorner(app.buttons["Close"])
        app.buttons["Edit Pokémon"].tap()
        checkCorner(app.navigationBars.buttons["Save"])
        app.navigationBars.buttons["Save"].tap()
    }
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

final class JourneyEditingUITests: XCTestCase {
    private var app: XCUIApplication!
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication(); app.launchEnvironment["RibbonPassportInteractionTest"] = "journey"; app.launch()
        XCTAssertTrue(app.buttons["Passport ▸"].waitForExistence(timeout: 10)); app.buttons["Passport ▸"].tap()
    }
    override func tearDownWithError() throws { app.terminate(); app = nil }
    private func openVisits() {
        app.buttons["Passport options"].tap()
        app.buttons["passport.editVisits"].tap()
        XCTAssertTrue(app.buttons["visits.generation.3"].waitForExistence(timeout: 5))
    }
    private func capture(_ title: String) {
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = title; shot.lifetime = .keepAlways; add(shot)
    }
    func testGenerationBoardAssignsMovesClearsAndUndoesSpecificGames() {
        openVisits()
        XCTAssertFalse(app.buttons["visits.remove.emerald"].exists)
        XCTAssertFalse(app.buttons["visits.remove.ruby"].exists)
        app.buttons["visits.generation.4"].tap()
        XCTAssertTrue(app.buttons["visits.game.pearl"].exists)
        XCTAssertFalse(app.buttons["visits.game.ruby"].exists)
        capture("game-journal-gen-four")
        app.buttons["visits.game.platinum"].tap()
        let effort = app.buttons["visits.award.effort-ribbon"]
        XCTAssertTrue(effort.waitForExistence(timeout: 5))
        XCTAssertTrue((effort.value as? String ?? "").contains("Ruby"))
        effort.tap()
        XCTAssertEqual(effort.value as? String, "Recorded here")
        capture("game-journal-assign-ribbons")
        effort.tap()
        XCTAssertEqual(effort.value as? String, "Game not set")
        app.buttons["visits.awards.undo"].tap()
        XCTAssertEqual(effort.value as? String, "Recorded here")
        app.buttons["visits.awards.done"].tap()
        XCTAssertFalse(app.buttons["visits.remove.platinum"].exists)
        app.buttons["visits.generation.3"].tap()
        XCTAssertTrue(app.buttons["visits.remove.ruby"].exists)
        app.buttons["visits.game.ruby"].tap()
        XCTAssertTrue(effort.waitForExistence(timeout: 5)); effort.tap()
        XCTAssertEqual(effort.value as? String, "Recorded here")
        app.buttons["visits.awards.done"].tap()
        app.buttons["visits.mode.add"].tap()
        app.buttons["visits.generation.4"].tap()
        app.buttons["visits.game.ss"].tap()
        XCTAssertTrue(app.buttons["visits.remove.ss"].waitForExistence(timeout: 5))
        app.buttons["visits.remove.ss"].tap()
        app.buttons["visits.undo"].tap()
        XCTAssertTrue(app.buttons["visits.remove.ss"].exists)
    }
    func testTappingAJourneyRibbonOpensItsSpecificGameSelector() {
        app.buttons["passport.tab.journey"].tap()
        app.buttons["album.grouping.games"].tap()
        app.buttons["album.game.ruby"].tap()
        app.buttons["Effort Ribbon"].tap()
        XCTAssertTrue(app.buttons["ribbons.generation.4"].waitForExistence(timeout: 5))
        app.buttons["ribbons.generation.4"].tap()
        app.buttons["ribbons.game.platinum"].tap()
        XCTAssertTrue(app.buttons["passport.tab.journey"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No ribbons assigned"].exists)
        openVisits()
        app.buttons["visits.generation.4"].tap()
        app.buttons["visits.game.platinum"].tap()
        let effort = app.buttons["visits.award.effort-ribbon"]
        XCTAssertTrue(effort.waitForExistence(timeout: 5))
        XCTAssertEqual(effort.value as? String, "Recorded here")
    }
}

final class AwardGalleryFeedbackUITests: XCTestCase {
    func testGalleryIsReadOnlyAndConsolidatesMemoryAwards() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchEnvironment["RibbonPassportInteractionTest"] = "memory"; app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.buttons["Passport ▸"].waitForExistence(timeout: 10)); app.buttons["Passport ▸"].tap()
        let owned = app.buttons["passport.owned"]
        let original = owned.label
        owned.tap()
        let battle = app.buttons["awards.gallery.battle-memory-ribbon"]
        let found = battle.waitForExistence(timeout: 5)
        if !found { print(app.debugDescription) }
        XCTAssertTrue(found)
        XCTAssertTrue(app.buttons["awards.gallery.contest-memory-ribbon"].exists)
        XCTAssertFalse(app.buttons["awards.gallery.winning-ribbon"].exists)
        XCTAssertEqual(app.staticTexts["awards.gallery.count"].label, "3")
        XCTAssertFalse(app.buttons["ribbons.owned.remove.effort-ribbon"].exists)
        battle.tap()
        XCTAssertTrue(app.staticTexts["ribbon.description.text"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["ribbon.description.name"].label.contains("Battle Memory"))
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "expanded-owned-awards-gallery"; shot.lifetime = .keepAlways; add(shot)
        app.buttons["awards.gallery.close"].tap()
        XCTAssertEqual(owned.label, original)
        XCTAssertFalse(app.buttons["ribbons.tile.effort-ribbon"].exists)
    }
    func testAddingShowsNamedFeedbackUndoAndAutomaticallySavedGalleryAward() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchEnvironment["RibbonPassportInteractionTest"] = "marks"; app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.buttons["Passport ▸"].waitForExistence(timeout: 10)); app.buttons["Passport ▸"].tap()
        app.buttons["passport.tab.ribbons"].tap()
        XCTAssertFalse(app.buttons["ribbons.save"].exists)
        let effort = app.buttons["ribbons.tile.effort-ribbon"]
        XCTAssertTrue(effort.waitForExistence(timeout: 5)); effort.tap()
        let title = app.staticTexts["ribbons.feedback.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertTrue(title.label.contains("Added")); XCTAssertTrue(title.label.contains("Effort Ribbon"))
        XCTAssertEqual(app.staticTexts["ribbons.feedback.subtitle"].label, "Scarlet")
        XCTAssertFalse(effort.exists)
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "ribbon-added-feedback-without-footer"; shot.lifetime = .keepAlways; add(shot)
        app.buttons["ribbons.feedback.undo"].tap()
        XCTAssertTrue(effort.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, "Change undone")
        effort.tap()
        let hidden = NSPredicate(format: "exists == false")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: hidden, object: title)], timeout: 10), .completed)
        XCTAssertTrue(app.staticTexts["ribbons.resultCount"].exists)
        app.buttons["passport.tab.overview"].tap()
        app.buttons["passport.owned"].tap()
        XCTAssertTrue(app.buttons["awards.gallery.effort-ribbon"].waitForExistence(timeout: 5))
        app.buttons["awards.gallery.close"].tap()
        app.buttons["passport.tab.ribbons"].tap()
        app.buttons["ribbons.owned"].tap()
        let remove = app.buttons["ribbons.owned.remove.effort-ribbon"]
        XCTAssertTrue(remove.waitForExistence(timeout: 5)); remove.tap()
        app.navigationBars.buttons["Done"].tap()
        XCTAssertTrue(title.label.contains("Removed"))
        app.buttons["ribbons.feedback.undo"].tap()
        app.buttons["passport.tab.overview"].tap()
        XCTAssertTrue(app.buttons["passport.owned"].label.contains("1"))
    }
}

final class StreamlinedUIUITests: XCTestCase {
    private var app: XCUIApplication!
    override func setUpWithError() throws { continueAfterFailure = false }
    override func tearDownWithError() throws { app?.terminate(); app = nil }
    private func launch(_ fixture: String) {
        app = XCUIApplication(); app.launchEnvironment["RibbonPassportInteractionTest"] = fixture; app.launch()
        XCTAssertTrue(app.buttons["Collection options"].waitForExistence(timeout: 10))
    }
    private func tap(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        for _ in 0..<8 { if element.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(element.isHittable); element.tap()
    }
    private func enter(_ text: String, into field: XCUIElement) {
        tap(field)
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 12) + text)
        if app.buttons["keyboard.done"].exists { tap(app.buttons["keyboard.done"]) }
    }
    func testEmptyCollectionsExposeTheirStartingActions() {
        launch("empty")
        XCTAssertTrue(app.buttons["pc.empty.import"].isHittable)
        XCTAssertTrue(app.buttons["pc.empty.demo"].isHittable)
        tap(app.buttons["Competitive"])
        XCTAssertTrue(app.buttons["pc.empty.showdown"].isHittable)
        tap(app.buttons["pc.empty.library"])
        XCTAssertTrue(app.textFields["library.search"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["library.games.iv-peterko"].exists)
    }
    func testCollectionActionsCanEditLevelDirectly() {
        launch("community")
        tap(app.buttons["Pokémon actions"]); tap(app.buttons["pc.pokemon.edit"])
        let level = app.textFields["pokemon.level"]; enter("100", into: level)
        tap(app.navigationBars.buttons["Save"])
        XCTAssertTrue(app.staticTexts["Lv. 100 · Brilliant Diamond"].waitForExistence(timeout: 5))
    }
    func testJourneyHasDirectMoveNotesAndOptionalMemoryDate() {
        launch("community")
        tap(app.buttons["Passport ▸"]); tap(app.buttons["passport.tab.journey"])
        tap(app.buttons["passport.moves"])
        XCTAssertTrue(app.buttons["moves.add"].waitForExistence(timeout: 5))
        tap(app.buttons["navigation.back"].firstMatch); tap(app.buttons["passport.notes"])
        tap(app.buttons["journal.add"])
        enter("First visit", into: app.textFields["journal.title"])
        let known = app.switches["journal.date.known"]; XCTAssertEqual(known.value as? String, "0")
        tap(known); XCTAssertTrue(app.datePickers["journal.date"].exists)
        tap(app.navigationBars.buttons["Save"])
        tap(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "journal.entry.")).firstMatch)
        XCTAssertEqual(app.textFields["journal.title"].value as? String, "First visit")
        XCTAssertEqual(app.switches["journal.date.known"].value as? String, "1")
    }
    func testRecoveryStartsWithChangesAndRestore() {
        launch("recovery")
        tap(app.buttons["Settings"]); tap(app.buttons["recovery.open"])
        tap(app.buttons["recovery.item.pokemon.drag-a"])
        tap(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "recovery.version.")).firstMatch)
        XCTAssertTrue(app.buttons["recovery.restore"].isHittable)
        XCTAssertFalse(app.staticTexts["Species"].exists)
        tap(app.buttons["recovery.restore"])
        XCTAssertTrue(app.staticTexts["recovery.restored"].waitForExistence(timeout: 5))
    }
    func testWidgetSetupKeepsAdvancedControlsOptional() {
        launch("community")
        tap(app.buttons["Settings"]); tap(app.buttons["Ribbon widgets"])
        XCTAssertTrue(app.buttons["widgets.addToHomeScreen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["widgets.addToHomeScreen"].isHittable)
        XCTAssertFalse(app.buttons["Palette: Sage"].exists)
        tap(app.buttons["widgets.customise"])
        XCTAssertTrue(app.buttons["Palette: Sage"].exists)
        tap(app.buttons["widgets.addToHomeScreen"])
        XCTAssertTrue(app.staticTexts["Hold an empty area on the Home Screen."].waitForExistence(timeout: 5))
    }
    func testTransferMetLevelCanBeSetAndUndone() {
        launch("metlevel")
        tap(app.buttons["ribbons.manage"]); tap(app.buttons["ribbons.transfer.review"])
        let fix = app.buttons["ribbons.transfer.metLevel"]; XCTAssertTrue(fix.waitForExistence(timeout: 5)); tap(fix)
        tap(app.switches["Met level known"])
        enter("20", into: app.textFields["pokemon.metLevel"])
        tap(app.navigationBars.buttons["Save"])
        XCTAssertTrue(app.buttons["ribbons.transfer.undo"].waitForExistence(timeout: 5))
        XCTAssertFalse(fix.exists)
        tap(app.buttons["ribbons.transfer.undo"])
        XCTAssertTrue(fix.waitForExistence(timeout: 5))
    }
    func testRibbonDetailsAndRecordingAreSeparate() {
        launch("transfer")
        tap(app.buttons["ribbons.manage"])
        tap(app.buttons["ribbons.details.footprint-ribbon"])
        XCTAssertTrue(app.staticTexts["Footprint Ribbon"].waitForExistence(timeout: 5))
        tap(app.navigationBars.buttons["Done"])
        let record = app.buttons["ribbons.tile.footprint-ribbon"]
        XCTAssertTrue(record.waitForExistence(timeout: 5)); tap(record)
        XCTAssertTrue(app.staticTexts["ribbons.feedback.title"].waitForExistence(timeout: 5))
        XCTAssertFalse(record.exists)
        tap(app.buttons["ribbons.feedback.undo"])
        XCTAssertTrue(record.waitForExistence(timeout: 5))
    }
}
