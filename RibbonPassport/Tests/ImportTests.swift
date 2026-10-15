import XCTest
import SwiftUI
import UIKit
@testable import RibbonPassport

final class RibbonManagerTests: XCTestCase {
    private let rules = RibbonRules.shared
    func testCatalogueAndPageSizeCycle() {
        XCTAssertEqual(rules.ribbonIDs.count, 106)
        XCTAssertFalse(rules.ribbonIDs.contains { $0.hasSuffix("-mark") })
        XCTAssertEqual(RibbonPageSize.options, [12, 16, 32])
        XCTAssertEqual([RibbonPageSize.next(12), RibbonPageSize.next(16), RibbonPageSize.next(32)], [16, 32, 12])
        XCTAssertEqual(RibbonPageSize.validated(8), 12)
        XCTAssertEqual(RibbonPageSize.validated(24), 12)
    }
    func testReachableGamesRespectSpeciesFormsAndOneWayTransfers() {
        let metagross = RibbonPokemon(species: "metagross", currentgame: "diamond", origingame: "ruby")
        let games = rules.compatibleGames(for: metagross)
        XCTAssertFalse(games.contains("red")); XCTAssertFalse(games.contains("ruby"))
        XCTAssertTrue(games.contains("sw")); XCTAssertTrue(games.contains("bd"))
        let home = RibbonPokemon(species: "metagross", currentgame: "home")
        XCTAssertFalse(rules.compatibleGames(for: home).contains("diamond"))
        let cosplay = RibbonPokemon(species: "pikachu-cosplay", currentgame: "as")
        XCTAssertEqual(Set(rules.compatibleGames(for: cosplay)), Set(["or", "as"]))
        let spinda = RibbonPokemon(species: "spinda", currentgame: "bd", origingame: "bd")
        XCTAssertEqual(Set(rules.compatibleGames(for: spinda)), Set(["bd", "sp"]))
    }
    func testMythicalAndLegendaryRestrictionsDependOnTheActualGame() {
        let mew = RibbonPokemon(species: "mew", currentgame: "bd", origingame: "emerald")
        let ray = RibbonPokemon(species: "rayquaza", currentgame: "bd", origingame: "emerald")
        XCTAssertEqual(rules.category(for: mew), "MYTHICAL"); XCTAssertEqual(rules.category(for: ray), "LEGENDARY")
        XCTAssertEqual(rules.category(for: RibbonPokemon(species: "articuno-galar")), "LEGENDARY")
        XCTAssertNil(rules.category(for: RibbonPokemon(species: "metagross")))
        XCTAssertNotNil(rules.unavailableReason("tower-master-ribbon", game: "bd", pokemon: mew))
        XCTAssertNil(rules.unavailableReason("tower-master-ribbon", game: "sw", pokemon: mew))
        XCTAssertTrue(rules.earningGames(for: "tower-master-ribbon", pokemon: ray).contains("sw"))
        XCTAssertFalse(rules.earningGames(for: "tower-master-ribbon", pokemon: ray).contains("bd"))
        let alola = RibbonPokemon(species: "mew", currentgame: "sun")
        XCTAssertNotNil(rules.unavailableReason("battle-tree-great-ribbon", game: "sun", pokemon: alola))
        XCTAssertNil(rules.unavailableReason("battle-tree-great-ribbon", game: "usun", pokemon: alola))
    }
    func testLastChanceDependsOnCompatibleLaterGames() {
        let mew = RibbonPokemon(species: "mew", currentgame: "as", origingame: "emerald")
        let victini = RibbonPokemon(species: "victini", currentgame: "as", origingame: "black")
        XCTAssertFalse(rules.isLastChance("coolness-master-ribbon", game: "as", pokemon: mew))
        XCTAssertTrue(rules.laterGames(for: "coolness-master-ribbon", after: "as", pokemon: mew).contains("bd"))
        XCTAssertTrue(rules.isLastChance("coolness-master-ribbon", game: "as", pokemon: victini))
        let restricted = RibbonPokemon(species: "rayquaza", currentgame: "emerald", origingame: "emerald", currentlevel: 50)
        XCTAssertFalse(rules.isLastChance("winning-ribbon", game: "emerald", pokemon: restricted))
    }
    func testTransferCheckIncludesOtherGamesInDepartureGeneration() {
        var p = RibbonPokemon(species: "metagross", currentgame: "as", origingame: "emerald", metLevel: 5)
        p.ribbons = rules.ribbonIDs.filter { $0 != "kalos-champion-ribbon" }
        XCTAssertNotNil(rules.unavailableReason("kalos-champion-ribbon", game: "as", pokemon: p))
        let check = rules.transferCheck(from: "as", pokemon: p)
        XCTAssertEqual(check.generation, 6)
        XCTAssertEqual(check.nextGeneration, 7)
        XCTAssertEqual(check.lastChance, ["kalos-champion-ribbon"])
        XCTAssertEqual(rules.generationEarningGames(for: "kalos-champion-ribbon", from: "as", pokemon: p), ["x", "y"])
        XCTAssertFalse(check.isSafe)
        XCTAssertTrue(p.recordRibbon("kalos-champion-ribbon", game: "x"))
        XCTAssertTrue(rules.transferCheck(from: "as", pokemon: p).isSafe)
        XCTAssertEqual(p.earnedGames?["kalos-champion-ribbon"], "x")
        p.removeAward("kalos-champion-ribbon")
        XCTAssertFalse(rules.transferCheck(from: "as", pokemon: p).isSafe)
    }
    func testFootprintLastChanceAtTransferLevelBoundary() {
        var p = RibbonPokemon(species: "metagross", currentgame: "platinum", origingame: "emerald", currentlevel: 70, metLevel: 5)
        p.ribbons = rules.ribbonIDs.filter { $0 != "footprint-ribbon" }
        var check = rules.transferCheck(from: "platinum", pokemon: p)
        XCTAssertTrue(check.isSafe)
        XCTAssertEqual(check.canWait, ["footprint-ribbon"])
        XCTAssertTrue(rules.laterGames(for: "footprint-ribbon", after: "platinum", pokemon: p).contains("bd"))
        XCTAssertNil(rules.footprintTransferWarning(from: "platinum", pokemon: p))
        p.currentlevel = 71
        check = rules.transferCheck(from: "platinum", pokemon: p)
        XCTAssertEqual(check.lastChance, ["footprint-ribbon"])
        XCTAssertFalse(check.isSafe)
        XCTAssertNotNil(rules.footprintTransferWarning(from: "platinum", pokemon: p))
        XCTAssertNotNil(rules.footprintTransferWarning(from: "hg", pokemon: p))
        XCTAssertNotNil(rules.unavailableReason("footprint-ribbon", game: "bd", pokemon: p))
        let before = p
        XCTAssertTrue(p.recordRibbon("footprint-ribbon", game: "platinum"))
        XCTAssertTrue(rules.transferCheck(from: "platinum", pokemon: p).isSafe)
        p = before
        XCTAssertFalse(rules.transferCheck(from: "platinum", pokemon: p).isSafe)
    }
    func testFootprintFriendshipExceptionAndFinalGeneration() {
        var voiceless = RibbonPokemon(species: "regigigas", currentgame: "platinum", origingame: "diamond", currentlevel: 100, metLevel: 100)
        voiceless.ribbons = rules.ribbonIDs.filter { $0 != "footprint-ribbon" }
        XCTAssertTrue(rules.transferCheck(from: "platinum", pokemon: voiceless).isSafe)
        XCTAssertTrue(rules.laterGames(for: "footprint-ribbon", after: "platinum", pokemon: voiceless).contains("bd"))
        var p = RibbonPokemon(species: "metagross", currentgame: "sw", origingame: "emerald", currentlevel: 100, metLevel: 70)
        p.ribbons = rules.ribbonIDs.filter { $0 != "footprint-ribbon" }
        let check = rules.transferCheck(from: "sw", pokemon: p)
        XCTAssertEqual(check.lastChance, ["footprint-ribbon"])
        XCTAssertEqual(rules.generationEarningGames(for: "footprint-ribbon", from: "sw", pokemon: p), ["bd", "sp"])
        XCTAssertFalse(check.isSafe)
    }
    func testTransferSafetyRespectsRestrictionsAndUnknownMetLevel() {
        var p = RibbonPokemon(species: "mew", currentgame: "as", origingame: "emerald", currentlevel: 100)
        p.ribbons = rules.ribbonIDs.filter { !["footprint-ribbon", "skillful-battler-ribbon", "expert-battler-ribbon"].contains($0) }
        var check = rules.transferCheck(from: "as", pokemon: p)
        XCTAssertTrue(check.lastChance.isEmpty)
        XCTAssertFalse(check.warnings.isEmpty)
        XCTAssertFalse(check.isSafe)
        p.metLevel = 70
        check = rules.transferCheck(from: "as", pokemon: p)
        XCTAssertTrue(check.warnings.isEmpty)
        XCTAssertTrue(check.isSafe)
        XCTAssertEqual(check.canWait, ["footprint-ribbon"])
        var victini = RibbonPokemon(species: "victini", currentgame: "as", origingame: "black", metLevel: 50)
        victini.ribbons = rules.ribbonIDs.filter { $0 != "coolness-master-ribbon" }
        XCTAssertEqual(rules.transferCheck(from: "as", pokemon: victini).lastChance, ["coolness-master-ribbon"])
    }
    func testTransferCheckRequiresCompatibleGameAndDestination() {
        XCTAssertFalse(rules.transferCheck(from: "", pokemon: RibbonPokemon(species: "metagross")).canAssess)
        XCTAssertFalse(rules.transferCheck(from: "red", pokemon: RibbonPokemon(species: "metagross", currentgame: "as")).canAssess)
        var p = RibbonPokemon(species: "pikachu-cosplay", currentgame: "as")
        p.ribbons = rules.ribbonIDs
        let check = rules.transferCheck(from: "as", pokemon: p)
        XCTAssertTrue(check.canAssess)
        XCTAssertNil(check.nextGeneration)
        XCTAssertFalse(check.isSafe)
    }
    func testRecordUsesOneSpecificGameAndOwnedCannotBeOverwritten() throws {
        var p = RibbonPokemon(species: "metagross", currentgame: "bd", origingame: "emerald")
        XCTAssertTrue(p.recordRibbon("effort-ribbon", game: "bd"))
        XCTAssertEqual(p.awards(earnedInGame: "bd"), ["effort-ribbon"])
        XCTAssertTrue(p.awards(earnedInGame: "sp").isEmpty)
        XCTAssertFalse(p.recordRibbon("effort-ribbon", game: "sp"))
        XCTAssertEqual(p.earnedGames?["effort-ribbon"], "bd")
        XCTAssertTrue(rules.earningGames(for: "effort-ribbon", pokemon: p).isEmpty)
        p.title = "effort-ribbon"; p.titleText = "the Once Well-Trained"
        let before = p
        p.removeAward("effort-ribbon")
        XCTAssertFalse(p.ribbons.contains("effort-ribbon")); XCTAssertNil(p.earnedGames?["effort-ribbon"])
        XCTAssertNil(p.earnedGenerations?["effort-ribbon"]); XCTAssertEqual(p.title, "None")
        XCTAssertTrue(p.recordRibbon("effort-ribbon", game: "sp"))
        XCTAssertEqual(p.earnedGames?["effort-ribbon"], "sp")
        p = before
        XCTAssertEqual(p.earnedGames?["effort-ribbon"], "bd"); XCTAssertEqual(p.title, "effort-ribbon")
        let restored = try JSONDecoder().decode(RibbonPokemon.self, from: JSONEncoder().encode(p))
        XCTAssertEqual(restored, p)
    }
    func testOldGenerationLocationsRemainUnassignedToAGameAndKeepMemoryCounts() throws {
        var p = try XCTUnwrap(SharedStore.demo().pokemon.first { $0.species == "rayquaza" })
        let before = RibbonCatalog.shared.awards(for: p)
        let legacy = try XCTUnwrap(p.ribbons.first { p.earnedGenerations?[$0] == 3 })
        XCTAssertNil(p.earnedGames)
        XCTAssertTrue(p.earningLocation(legacy).contains("Game not set"))
        XCTAssertTrue(p.awards(earnedInGame: "ruby").isEmpty)
        p.assignAward(legacy, game: "ruby")
        XCTAssertEqual(p.earnedGames?[legacy], "ruby")
        XCTAssertTrue(p.awards(earnedInGame: "ruby").contains(legacy))
        XCTAssertEqual(RibbonCatalog.shared.awards(for: p), before)
        XCTAssertTrue(p.recordedVisits.contains { $0.game == p.origingame })
        XCTAssertTrue(p.recordedVisits.contains { $0.game == p.currentgame })
    }
    func testEventMemoryShadowAndLevelRestrictions() {
        var p = RibbonPokemon(species: "metagross", currentgame: "emerald", origingame: "colosseum", currentlevel: 51)
        XCTAssertNotNil(rules.unavailableReason("winning-ribbon", game: "emerald", pokemon: p))
        p.currentlevel = 50
        XCTAssertNil(rules.unavailableReason("winning-ribbon", game: "emerald", pokemon: p))
        XCTAssertFalse(p.recordRibbon("contest-memory-ribbon", game: "as"))
        XCTAssertFalse(p.recordRibbon("world-ribbon", game: "emerald"))
        XCTAssertNotNil(rules.unavailableReason("national-ribbon", game: "colosseum", pokemon: p))
        p.shadow = true
        XCTAssertNil(rules.unavailableReason("national-ribbon", game: "colosseum", pokemon: p))
        var voiced = RibbonPokemon(species: "mew", currentgame: "bd", currentlevel: 100)
        XCTAssertNotNil(rules.unavailableReason("footprint-ribbon", game: "bd", pokemon: voiced))
        voiced.metLevel = 70
        XCTAssertNil(rules.unavailableReason("footprint-ribbon", game: "bd", pokemon: voiced))
        voiced.metLevel = 71
        XCTAssertNotNil(rules.unavailableReason("footprint-ribbon", game: "bd", pokemon: voiced))
    }
    func testEarningLocationsStayOutOfWebsiteExportsButMetLevelRoundTrips() throws {
        var p = RibbonPokemon(species: "metagross", currentgame: "bd", origingame: "emerald", language: "en", ball: "poke")
        p.metLevel = 50; XCTAssertTrue(p.recordRibbon("effort-ribbon", game: "bd"))
        let data = try RibbonsGuideExporter.export([p])
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let entry = try XCTUnwrap((root["pokemon"] as? [[String: Any]])?.first)
        XCTAssertNil(entry["earnedGames"]); XCTAssertNil(entry["earnedGenerations"])
        XCTAssertEqual(try BackupImporter.parse(data).first?.metLevel, 50)
    }
    @MainActor func testNativeTransferDrawerRendersWarningAndSafeStates() throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let previous = scene.windows.first { $0.isKeyWindow }
        let window = UIWindow(windowScene: scene)
        let controller = UIHostingController(rootView: AnyView(EmptyView()))
        window.rootViewController = controller
        defer { controller.rootView = AnyView(EmptyView()); window.isHidden = true; window.rootViewController = nil; previous?.makeKey() }
        let previews = FileManager.default.temporaryDirectory.appendingPathComponent("RibbonTransfer-Previews")
        try FileManager.default.createDirectory(at: previews, withIntermediateDirectories: true)
        print("Transfer preview directory: \(previews.path)")
        var p = RibbonPokemon(species: "metagross", currentgame: "platinum", origingame: "emerald", currentlevel: 100, metLevel: 5)
        p.ribbons = rules.ribbonIDs.filter { (rules.awards[$0]?.gen ?? 99) <= 4 && !["footprint-ribbon", "pair-ability-ribbon", "legend-ribbon"].contains($0) }
        for width in [320.0, 390.0] {
            for dark in [false, true] {
                for safe in [false, true] {
                    var sample = p
                    if safe { sample.ribbons = rules.ribbonIDs }
                    let check = rules.transferCheck(from: "platinum", pokemon: sample)
                    XCTAssertEqual(check.isSafe, safe)
                    window.frame = CGRect(x: 0, y: 0, width: width, height: 844)
                    let view = RibbonTransferDrawer(pokemon: sample, game: "platinum", check: check, onRecord: { _, _ in }, onUndo: {}, onDone: {})
                        .environment(\.colorScheme, dark ? .dark : .light)
                    controller.rootView = AnyView(view.id("\(width)-\(dark)-\(safe)"))
                    window.makeKeyAndVisible(); controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
                    RunLoop.main.run(until: Date().addingTimeInterval(0.2))
                    let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in controller.view.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
                    let name = "transfer-\(Int(width))-\(dark ? "dark" : "light")-\(safe ? "safe" : "warning")"
                    let attachment = XCTAttachment(image: image); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
                    try image.pngData()?.write(to: previews.appendingPathComponent(name + ".png"))
                }
            }
        }
    }
    @MainActor func testNativeManagerRendersEveryPageSizeAndOwnedDrawer() throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let previous = scene.windows.first { $0.isKeyWindow }
        let window = UIWindow(windowScene: scene)
        let controller = UIHostingController(rootView: AnyView(EmptyView()))
        window.rootViewController = controller
        let preferenceName = "RibbonManager.RenderTests." + UUID().uuidString
        let preferences = try XCTUnwrap(UserDefaults(suiteName: preferenceName))
        let previews = FileManager.default.temporaryDirectory.appendingPathComponent("RibbonManager-Previews")
        try FileManager.default.createDirectory(at: previews, withIntermediateDirectories: true)
        print("Ribbon manager preview directory: \(previews.path)")
        defer { controller.rootView = AnyView(EmptyView()); window.isHidden = true; window.rootViewController = nil; previous?.makeKey(); preferences.removePersistentDomain(forName: preferenceName) }
        var p = RibbonPokemon(species: "mew", currentgame: "bd", origingame: "emerald", currentlevel: 100, metLevel: 50)
        for id in ["effort-ribbon", "alert-ribbon", "shock-ribbon"] { XCTAssertTrue(p.recordRibbon(id, game: "bd")) }
        for width in [320.0, 390.0] {
            for count in RibbonPageSize.options {
                for dark in [false, true] {
                    preferences.set(count, forKey: "ribbons.pageSize")
                    window.frame = CGRect(x: 0, y: 0, width: width, height: 844)
                    let view = RibbonManager(pokemon: .constant(p), allGames: true, earnableOnly: false) {}.defaultAppStorage(preferences).environment(\.colorScheme, dark ? .dark : .light)
                    controller.rootView = AnyView(view.id("\(width)-\(count)-\(dark)"))
                    window.makeKeyAndVisible()
                    controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
                    RunLoop.main.run(until: Date().addingTimeInterval(0.15))
                    let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in controller.view.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
                    XCTAssertEqual(image.size.width, width)
                    let attachment = XCTAttachment(image: image); attachment.name = "ribbons-\(count)-\(Int(width))-\(dark ? "dark" : "light")"; attachment.lifetime = .keepAlways; add(attachment)
                    try image.pngData()?.write(to: previews.appendingPathComponent("ribbons-\(count)-\(Int(width))-\(dark ? "dark" : "light").png"))
                }
            }
        }
        controller.rootView = AnyView(RibbonManager(pokemon: .constant(p), initiallyOwned: true) {}.id("owned"))
        controller.view.layoutIfNeeded(); RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        let ownedImage = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
        let ownedAttachment = XCTAttachment(image: ownedImage); ownedAttachment.name = "ribbons-owned-drawer"; ownedAttachment.lifetime = .keepAlways; add(ownedAttachment)
        try ownedImage.pngData()?.write(to: previews.appendingPathComponent("ribbons-owned-drawer.png"))
        controller.rootView = AnyView(RibbonGamePicker(pokemon: p, selected: "bd") { _ in }.id("game-picker"))
        controller.view.layoutIfNeeded(); RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        let pickerImage = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in controller.view.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
        try pickerImage.pngData()?.write(to: previews.appendingPathComponent("ribbons-game-picker.png"))
    }
}

final class ImportTests: XCTestCase {
    func testShowdownNicknameGenderAndShiny() throws {
        let text = "Sparky (Pikachu) (F) @ Light Ball\nAbility: Static\nLevel: 50\nShiny: Yes\n- Thunderbolt\n\nLugia @ Leftovers\n- Roost"
        let pokemon = try ShowdownImporter.parse(text)
        XCTAssertEqual(pokemon.count, 2)
        XCTAssertEqual(pokemon[0].species, "pikachu")
        XCTAssertEqual(pokemon[0].nickname, "Sparky")
        XCTAssertEqual(pokemon[0].gender, "female")
        XCTAssertTrue(pokemon[0].shiny)
        XCTAssertEqual(pokemon[0].currentlevel, 50)
        XCTAssertEqual(pokemon[0].showdownSet?.item, "Light Ball")
        XCTAssertEqual(pokemon[0].showdownSet?.ability, "Static")
        XCTAssertEqual(pokemon[0].showdownSet?.moves, ["Thunderbolt"])
        XCTAssertTrue(pokemon[0].ribbons.isEmpty)
        XCTAssertEqual(pokemon[0].origingame, "")
        XCTAssertEqual(pokemon[1].species, "lugia")
    }
    func testShowdownFormsAndNoFinalBlankLine() throws {
        let pokemon = try ShowdownImporter.parse("=== [gen9ou] Team ===\r\n\r\nRotom-Wash @ Leftovers\r\n- Hydro Pump\r\n\r\nZacian-Crowned @ Rusted Sword\r\nShiny: Yes\r\n- Behemoth Blade")
        XCTAssertEqual(pokemon.count, 2)
        XCTAssertEqual(pokemon[0].species, "rotom-wash")
        XCTAssertEqual(pokemon[1].spritePath, "shiny/zacian-crowned.png")
    }
    func testInvalidShowdownIsRejected() {
        XCTAssertThrowsError(try ShowdownImporter.parse(""))
        XCTAssertThrowsError(try ShowdownImporter.parse("UnknownCustomMon @ Leftovers\n- Tackle"))
        XCTAssertThrowsError(try ShowdownImporter.parse("Pikachu\nLevel: 150"))
        XCTAssertThrowsError(try ShowdownImporter.parse(Array(repeating: "Pikachu\n- Thunderbolt", count: 7).joined(separator: "\n\n")))
    }
    func testMemoryMergingAndCountsIncludeMarks() {
        let catalog = RibbonCatalog.shared
        let battle = catalog.merges.filter { $0.value == "battle" }.map(\.key)
        let contest = catalog.merges.filter { $0.value == "contest" }.map(\.key)
        var pokemon = RibbonPokemon(species: "pikachu", currentgame: "as", origingame: "emerald", ribbons: battle + contest + ["national-ribbon", "earth-ribbon", "rare-mark"])
        let modern = catalog.awards(for: pokemon)
        XCTAssertEqual(modern.count, 5)
        XCTAssertTrue(modern.contains("contest-memory-ribbon-gold"))
        XCTAssertTrue(modern.contains("battle-memory-ribbon-gold"))
        XCTAssertEqual(catalog.ranked(modern, ribbonsOnly: true).count, 4)
        pokemon.currentgame = "emerald"
        XCTAssertEqual(catalog.awards(for: pokemon).count, 51)
    }
    func testBattleGoldThreshold() {
        let catalog = RibbonCatalog.shared
        let battle = Array(catalog.merges.filter { $0.value == "battle" }.map(\.key).sorted().prefix(7))
        var pokemon = RibbonPokemon(species: "pikachu", currentgame: "as", ribbons: battle)
        XCTAssertEqual(catalog.awards(for: pokemon), ["battle-memory-ribbon"])
        pokemon.currentgame = "scar"
        XCTAssertEqual(catalog.awards(for: pokemon), ["battle-memory-ribbon-gold"])
    }
    func testBackupAndShadowOrigin() throws {
        let data = Data(#"{"fileVersion":5,"pokemon":[{"species":"lugia","origingame":"xd","currentgame":"as","shiny":"square","ribbons":["national-ribbon","national-ribbon"]}]}"#.utf8)
        let pokemon = try BackupImporter.parse(data)
        XCTAssertEqual(pokemon[0].ribbons.count, 1)
        XCTAssertTrue(pokemon[0].shiny)
        XCTAssertEqual(pokemon[0].spritePath, "regular/lugia-shadow.png")
        XCTAssertThrowsError(try BackupImporter.parse(Data(#"{"fileVersion":4,"pokemon":[]}"#.utf8)))
    }
    func testSeparateTeamSelectionsAndExistingSnapshotDecoding() throws {
        let ribbon = RibbonPokemon(id: "ribbon", species: "metagross", ribbons: ["effort-ribbon"])
        let battle = RibbonPokemon(id: "battle", species: "pikachu", source: "showdown", showdownSet: ShowdownSet(item: "Light Ball"))
        let ribbonTeam = RibbonTeam(id: "ribbon-team", name: "Ribbons", memberIDs: [ribbon.id])
        let battleTeam = RibbonTeam(id: "battle-team", name: "Battles", memberIDs: [battle.id])
        let snapshot = CollectionSnapshot(pokemon: [ribbon, battle], teams: [ribbonTeam, battleTeam], selectedTeamID: battleTeam.id)
        // No new stored fields are required: teams from the previous app use their existing builds.
        let restored = try JSONDecoder().decode(CollectionSnapshot.self, from: JSONEncoder().encode(snapshot))
        XCTAssertEqual(restored.teams(for: .showdown).map(\.id), [battleTeam.id])
        XCTAssertEqual(restored.teams(for: .ribbon).map(\.id), [ribbonTeam.id])
        XCTAssertEqual(restored.widgetTeam(for: .ribbon)?.id, ribbonTeam.id)
        XCTAssertEqual(restored.widgetTeam(for: .showdown)?.id, battleTeam.id)
        XCTAssertNil(restored.widgetTeam(for: .showdown, id: ribbonTeam.id))
        XCTAssertNil(restored.widgetTeam(for: .ribbon, id: "deleted-team"))
    }
    func testDeletionPrunesTeamsAndRepairsSelections() {
        let a = RibbonPokemon(id: "a", species: "pikachu")
        let b = RibbonPokemon(id: "b", species: "lugia")
        let pair = RibbonTeam(id: "pair", name: "Pair", memberIDs: [a.id, b.id])
        let solo = RibbonTeam(id: "solo", name: "Solo", memberIDs: [a.id])
        var snapshot = CollectionSnapshot(pokemon: [a, b], teams: [pair, solo], selectedID: a.id, selectedTeamID: solo.id)
        snapshot.removePokemon(id: a.id)
        XCTAssertEqual(snapshot.pokemon.map(\.id), [b.id])
        XCTAssertEqual(snapshot.teams.map(\.id), [pair.id])
        XCTAssertEqual(snapshot.teams[0].memberIDs, [b.id])
        XCTAssertEqual(snapshot.selectedID, b.id)
        XCTAssertEqual(snapshot.selectedTeamID, pair.id)
        snapshot.removePokemon(id: b.id)
        XCTAssertTrue(snapshot.pokemon.isEmpty); XCTAssertTrue(snapshot.teams.isEmpty)
        XCTAssertEqual(snapshot.selectedID, ""); XCTAssertEqual(snapshot.selectedTeamID, "")
    }
    func testRefreshingDemoKeepsImportsAndStableDemoIDs() {
        let imported = RibbonPokemon(id: "imported", species: "lugia", source: "ribbons.guide")
        let oldDemo = RibbonPokemon(id: "old-demo", species: "pikachu", source: "demo")
        let staleDemo = RibbonPokemon(id: "stale", species: "swampert", source: "demo")
        let team = RibbonTeam(id: "demo-team", name: "Demo Ribbon Team", memberIDs: [oldDemo.id, staleDemo.id])
        let custom = RibbonTeam(id: "custom", name: "My favourites", memberIDs: [oldDemo.id, imported.id])
        var snapshot = CollectionSnapshot(pokemon: [imported, oldDemo, staleDemo], teams: [team, custom])
        let refreshed = [RibbonPokemon(species: "pikachu", shiny: true), RibbonPokemon(species: "sylveon")]
        snapshot.replaceDemo(with: refreshed)
        XCTAssertEqual(snapshot.pokemon.first, imported)
        XCTAssertEqual(snapshot.pokemon.first(where: { $0.species == "pikachu" })?.id, oldDemo.id)
        XCTAssertFalse(snapshot.pokemon.contains(where: { $0.id == staleDemo.id }))
        XCTAssertEqual(snapshot.teams.count, 2)
        XCTAssertEqual(snapshot.teams.first(where: { $0.id == custom.id }), custom)
        XCTAssertEqual(snapshot.teams.first(where: { $0.name == "Demo Ribbon Team" })?.id, team.id)
        let ids = snapshot.pokemon.map(\.id)
        snapshot.replaceDemo(with: refreshed)
        XCTAssertEqual(snapshot.pokemon.map(\.id), ids)
        XCTAssertEqual(snapshot.teams.count, 2)
    }
    func testDemoGamesAwardsAndFeatureCoverage() {
        let catalog = RibbonCatalog.shared
        let pokemon = SharedStore.demo().pokemon
        XCTAssertEqual(pokemon.count, 6)
        for p in pokemon {
            let generation = catalog.gameInfo[p.currentgame]?.gen ?? 0
            if generation < 8 { XCTAssertFalse(p.ribbons.contains("galar-champion-ribbon")) }
            if generation < 9 { XCTAssertFalse(p.ribbons.contains("paldea-champion-ribbon")) }
            if p.origingame != "xd" && p.origingame != "colosseum" { XCTAssertFalse(p.ribbons.contains("national-ribbon")) }
            XCTAssertTrue(p.ribbons.allSatisfy { catalog.ribbons[$0] != nil })
            XCTAssertTrue(catalog.awards(for: p).contains(catalog.equippedID(for: p)))
        }
        let pikachu = pokemon.first { $0.species == "pikachu" }!
        XCTAssertEqual(pikachu.spritePath, "shiny/pikachu-gmax.png")
        let rayquaza = pokemon.first { $0.species == "rayquaza" }!
        XCTAssertTrue(catalog.awards(for: rayquaza).contains("contest-memory-ribbon-gold"))
        let metagross = pokemon.first { $0.species == "metagross" }!
        XCTAssertEqual(catalog.consoleByGame[metagross.origingame], "ds")
        XCTAssertTrue(catalog.awards(for: metagross).contains("battle-memory-ribbon"))
        XCTAssertFalse(catalog.awards(for: metagross).contains("battle-memory-ribbon-gold"))
        let sylveon = pokemon.first { $0.species == "sylveon" }!
        XCTAssertEqual(catalog.awards(for: sylveon).count, 8)
        XCTAssertEqual(catalog.ranked(sylveon.ribbons, ribbonsOnly: true).count, 4)
    }
}

final class CustomizationTests: XCTestCase {
    func testOnlyUnchangedDemoRecordsReceiveAuthoredHistory() throws {
        var original = try XCTUnwrap(SharedStore.demo().pokemon.first { $0.species == "metagross" })
        original.id = "existing-demo"; original.source = "demo"; original.visits = nil; original.earnedGenerations = nil
        var imported = original; imported.id = "real-import"; imported.source = "ribbons.guide"
        var edited = original; edited.id = "edited-demo"; edited.ribbons.append("rare-mark")
        let migrated = SharedStore.restoringDemoHistory(in: CollectionSnapshot(pokemon: [original, imported, edited]))
        XCTAssertEqual(migrated.pokemon[0].id, "existing-demo")
        XCTAssertEqual(migrated.pokemon[0].visitedGenerations, [4, 5, 6, 7, 8, 9])
        XCTAssertNil(migrated.pokemon[1].visits)
        XCTAssertNil(migrated.pokemon[2].visits)
        XCTAssertEqual(migrated.pokemon[1].visitedGenerations, [4, 9])
    }
    func testOldSnapshotDecodesWithoutCustomizationFields() throws {
        let p = RibbonPokemon(id: "original", species: "metagross", currentgame: "scar", origingame: "diamond", ribbons: ["effort-ribbon"])
        let original = CollectionSnapshot(pokemon: [p], selectedID: p.id)
        let data = try JSONEncoder().encode(original)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNil(object["storage"]); XCTAssertNil(object["widgetPresets"])
        let decoded = try JSONDecoder().decode(CollectionSnapshot.self, from: data)
        XCTAssertEqual(decoded.pokemon.first?.id, "original")
        XCTAssertNil(decoded.pokemon.first?.earnedGenerations)
        XCTAssertEqual(decoded.pokemon.first?.visitedGenerations, [4, 9])
        XCTAssertNil(decoded.widgetPresets)
    }
    func testStorageReconciliationPreservesEveryPokemonExactlyOnce() {
        let ids = (0..<39).map { "p\($0)" }
        var layout = StorageLayout(boxes: [PCBox(slots: ["p0", "p0", "deleted", "p1"])], partyIDs: ["p0", "p0", "deleted", "p2"])
        layout.reconcile(pokemonIDs: ids)
        let placed = layout.partyIDs + layout.boxes.flatMap { $0.slots.compactMap { $0 } }
        XCTAssertEqual(Set(placed), Set(ids)); XCTAssertEqual(placed.count, ids.count)
        XCTAssertEqual(layout.boxes.count, 2)
        XCTAssertTrue(layout.boxes.allSatisfy { $0.slots.count == 30 })
    }
    func testStorageSwapAndPartyRoundTripDoNotLosePokemon() {
        var layout = StorageLayout(); layout.reconcile(pokemonIDs: ["a", "b", "c"])
        let box = layout.boxes[0].id
        XCTAssertTrue(layout.move("a", toBox: box, slot: 1))
        XCTAssertEqual(Array(layout.boxes[0].slots.prefix(3)), ["b", "a", "c"])
        XCTAssertTrue(layout.moveToParty("a"))
        XCTAssertEqual(layout.partyIDs, ["a"]); XCTAssertFalse(layout.boxes[0].slots.contains("a"))
        XCTAssertTrue(layout.move("a", toBox: box, slot: 0))
        XCTAssertEqual(layout.partyIDs, ["b"])
        layout.returnToBox("b")
        XCTAssertTrue(layout.partyIDs.isEmpty)
        XCTAssertEqual(Set(layout.boxes[0].slots.compactMap { $0 }), ["a", "b", "c"])
        XCTAssertFalse(layout.move("unknown", toBox: box, slot: 2))
        XCTAssertFalse(layout.move("a", toBox: box, slot: 31))
    }
    func testFullPartyRejectsSeventhPokemonWithoutRemovingItFromBox() {
        let ids = (0..<7).map(String.init)
        var layout = StorageLayout(); layout.reconcile(pokemonIDs: ids)
        for id in ids.prefix(6) { XCTAssertTrue(layout.moveToParty(id)) }
        XCTAssertFalse(layout.moveToParty(ids[6]))
        XCTAssertTrue(layout.boxes.contains { $0.slots.contains(ids[6]) })
    }
    func testDeletingPokemonPrunesPartyAndSlots() {
        var layout = StorageLayout(); layout.reconcile(pokemonIDs: ["a", "b"])
        _ = layout.moveToParty("a"); layout.reconcile(pokemonIDs: ["b"])
        XCTAssertTrue(layout.partyIDs.isEmpty)
        XCTAssertEqual(layout.boxes.flatMap { $0.slots.compactMap { $0 } }, ["b"])
    }
    func testRibbonLocationsUseOriginalAwardsWithoutChangingMemoryCounts() throws {
        var p = try XCTUnwrap(SharedStore.demo().pokemon.first { $0.species == "metagross" })
        let originalCount = p.ribbons.count, displayedCount = RibbonCatalog.shared.awards(for: p).count
        let award = try XCTUnwrap(p.ribbons.first { RibbonCatalog.shared.merges[$0] == "contest" })
        p.assignAward(award, generation: 4)
        XCTAssertTrue(p.awards(earnedIn: 4).contains(award))
        p.assignAward(award, generation: 6)
        XCTAssertFalse(p.awards(earnedIn: 4).contains(award)); XCTAssertTrue(p.awards(earnedIn: 6).contains(award))
        p.assignAward(award, generation: nil)
        XCTAssertNil(p.earnedGenerations?[award])
        p.assignAward("unowned-award", generation: 4)
        XCTAssertNil(p.earnedGenerations?["unowned-award"])
        XCTAssertEqual(p.ribbons.count, originalCount)
        XCTAssertEqual(RibbonCatalog.shared.awards(for: p).count, displayedCount)
    }
    func testWidgetPresetsRemainIndependentAndFilterByContent() throws {
        var a = WidgetPreset(name: "Light", content: .pokemon, selectionID: "pikachu")
        a.style.appearance = .light; a.style.showJourney = false
        var b = WidgetPreset(name: "Dark", content: .showdownTeam, selectionID: "battle-team")
        b.style.appearance = .dark; b.style.palette = .ocean; b.style.showMoves = false
        let snapshot = CollectionSnapshot(widgetPresets: [a, b], widgetDefaults: [WidgetContent.pokemon.rawValue: a.id])
        let restored = try JSONDecoder().decode(CollectionSnapshot.self, from: JSONEncoder().encode(snapshot))
        XCTAssertEqual(restored.preset(for: .pokemon), a)
        XCTAssertEqual(restored.preset(for: .showdownTeam, id: b.id), b)
        XCTAssertNil(restored.preset(for: .pokemon, id: b.id))
        XCTAssertEqual(restored.preset(for: .showdownTeam), WidgetThemePack.midnightCircuit.preset(for: .showdownTeam))
        XCTAssertFalse(restored.preset(for: .showdownTeam, id: b.id)!.style.showMoves)
    }
    func testJourneyAndWidgetSettingsRoundTrip() throws {
        var p = RibbonPokemon(species: "pikachu", currentgame: "sw", origingame: "as", ribbons: ["effort-ribbon"])
        p.visits = [JourneyVisit(game: "as"), JourneyVisit(game: "sun"), JourneyVisit(game: "sw")]
        p.assignAward("effort-ribbon", generation: 6)
        var snapshot = CollectionSnapshot(pokemon: [p]); snapshot.storage = snapshot.organizedStorage
        let restored = try JSONDecoder().decode(CollectionSnapshot.self, from: JSONEncoder().encode(snapshot))
        XCTAssertEqual(restored.pokemon[0].visitedGenerations, [6, 7, 8])
        XCTAssertEqual(restored.pokemon[0].earnedGenerations?["effort-ribbon"], 6)
        XCTAssertEqual(restored.storage, snapshot.storage)
    }
    func testShowdownExportRoundTripsBuildFields() throws {
        let original = try ShowdownImporter.parse("Sparky (Pikachu) (F) @ Light Ball\nAbility: Static\nShiny: Yes\nLevel: 50\nTera Type: Electric\nEVs: 252 SpA / 4 SpD / 252 Spe\nIVs: 0 Atk\nTimid Nature\n- Thunderbolt\n- Volt Switch\n- Grass Knot\n- Protect")
        let restored = try ShowdownImporter.parse(ShowdownExporter.export(original))
        XCTAssertEqual(restored[0].showdownSet, original[0].showdownSet)
        XCTAssertEqual(restored[0].gender, "female"); XCTAssertTrue(restored[0].shiny)
        XCTAssertEqual(restored[0].currentlevel, 50); XCTAssertEqual(restored[0].nickname, "Sparky")
        XCTAssertEqual(ShowdownStats.values(restored[0].showdownSet!.evs, fallback: 0), [0, 0, 0, 252, 4, 252])
        XCTAssertEqual(ShowdownStats.values(restored[0].showdownSet!.ivs, fallback: 31), [31, 0, 31, 31, 31, 31])
    }
    @MainActor func testBundledPixelFontAndAllWidgetSizesRender() throws {
        _ = PixelFont.font(17)
        XCTAssertNotNil(UIFont(name: "PixelifySans-Regular", size: 17), "The app and widget must use the bundled pixel font.")
        for p in SharedStore.demo().pokemon { XCTAssertNotNil(Artwork.sprite(p), "Missing bundled sprite: \(p.spritePath)") }
        let variants: [(WidgetContent, PassportSize, CGFloat, CGFloat, String)] = [
            (.pokemon, .small, 176, 176, "passport-small"), (.pokemon, .medium, 364, 184, "passport-medium"),
            (.pokemon, .large, 364, 384, "passport-large"), (.ribbonTeam, .medium, 364, 184, "ribbon-medium"),
            (.ribbonTeam, .large, 364, 384, "ribbon-large"), (.showdownTeam, .medium, 364, 184, "showdown-medium"),
            (.showdownTeam, .large, 364, 384, "showdown-large")
        ]
        for dark in [false, true] {
            for (content, size, width, height, name) in variants {
                let records = content == .showdownTeam ? SharedStore.showdownPreview().pokemon : SharedStore.demo().pokemon
                let chosen = content == .pokemon ? Array(records.filter { $0.species == "metagross" }) : records
                let theme = PassportTheme(dark: dark, game: "scar")
                let view = ConfiguredWidgetView(pokemon: chosen, name: "Main team", content: content, size: size, theme: theme)
                    .frame(width: width, height: height).environment(\.colorScheme, dark ? .dark : .light)
                let renderer = ImageRenderer(content: view); renderer.scale = 2
                let image = try XCTUnwrap(renderer.uiImage, name)
                XCTAssertEqual(image.size.width, width); XCTAssertEqual(image.size.height, height)
                let attachment = XCTAttachment(image: image); attachment.name = "\(name)-\(dark ? "dark" : "light")"; attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }
    @MainActor func testNarrowWidgetsWithLargeTextRender() throws {
        var style = WidgetStyle(); style.textScale = 1.15
        for (content, size, width, height, label) in [
            (WidgetContent.showdownTeam, PassportSize.large, CGFloat(300), CGFloat(384), "narrow-showdown-large"),
            (.showdownTeam, .medium, 300, 184, "narrow-showdown-medium"),
            (.pokemon, .small, 176, 176, "large-text-small-passport")
        ] {
            let records = content == .showdownTeam ? SharedStore.showdownPreview().pokemon : SharedStore.demo().pokemon.filter { $0.species == "metagross" }
            let view = ConfiguredWidgetView(pokemon: records, name: "Main team", content: content, size: size,
                                            theme: PassportTheme(dark: false, game: "scar", style: style))
                .frame(width: width, height: height).environment(\.colorScheme, .light)
            let renderer = ImageRenderer(content: view); renderer.scale = 2
            let image = try XCTUnwrap(renderer.uiImage)
            let attachment = XCTAttachment(image: image); attachment.name = label; attachment.lifetime = .keepAlways; add(attachment)
        }
    }
}

final class CollectionUpdateTests: XCTestCase {
    func testStarterPacksAreAvailableWithoutReplacingSavedDefaults() throws {
        let blank = CollectionSnapshot()
        XCTAssertEqual(blank.availableWidgetPresets.count, 15)
        XCTAssertEqual(Set(blank.availableWidgetPresets.map(\.id)).count, 15)
        for content in WidgetContent.allCases {
            XCTAssertEqual(blank.preset(for: content)?.style, WidgetThemePack.defaultPack(for: content).style)
            for pack in WidgetThemePack.allCases {
                let preset = pack.preset(for: content)
                XCTAssertEqual(blank.preset(for: content, id: preset.id), preset)
            }
        }
        var custom = WidgetPreset(name: "My design", content: .pokemon, selectionID: "my-pokemon")
        custom.style.palette = .game; custom.style.wallpaper = nil
        let snapshot = CollectionSnapshot(widgetPresets: [custom], widgetDefaults: ["pokemon": custom.id])
        let restored = try JSONDecoder().decode(CollectionSnapshot.self, from: JSONEncoder().encode(snapshot))
        XCTAssertEqual(restored.preset(for: .pokemon), custom)
        XCTAssertEqual(restored.widgetPresets, [custom])
        XCTAssertEqual(restored.availableWidgetPresets.count, 16)
        XCTAssertNil(restored.preset(for: .showdownTeam, id: custom.id))
        var stale = restored; stale.widgetDefaults?["pokemon"] = "deleted"
        XCTAssertEqual(stale.preset(for: .pokemon), WidgetThemePack.pocketGreen.preset(for: .pokemon))
    }
    func testPassportRetainsEndpointsWithMultipleGamesInSameGeneration() throws {
        var p = RibbonPokemon(species: "metagross", currentgame: "vio", origingame: "ruby")
        p.visits = [JourneyVisit(game: "scar"), JourneyVisit(game: "emerald"), JourneyVisit(game: "scar"), JourneyVisit(game: "as")]
        let stableIDs = p.recordedVisits.map(\.id)
        XCTAssertEqual(p.recordedVisits.map(\.id), stableIDs, "Endpoint IDs must remain stable while SwiftUI recomputes the view.")
        XCTAssertEqual(p.games(in: 3), ["ruby", "emerald"])
        XCTAssertEqual(p.games(in: 9), ["scar", "vio"])
        XCTAssertEqual(p.visitedGenerations, [3, 6, 9])
        let restored = try JSONDecoder().decode(RibbonPokemon.self, from: JSONEncoder().encode(p))
        XCTAssertEqual(restored.origingame, "ruby"); XCTAssertEqual(restored.currentgame, "vio")
        XCTAssertEqual(restored.games(in: 3), ["ruby", "emerald"])
        XCTAssertEqual(restored.games(in: 9), ["scar", "vio"])
        p.visits = []; XCTAssertEqual(p.recordedVisits.map(\.game), ["ruby", "vio"])
    }
    func testChronologyCoversEntireCatalogAndKeepsRanksInOrder() {
        let c = RibbonCatalog.shared
        XCTAssertTrue(c.games.keys.allSatisfy { CatalogOrder.gameIndex($0) != Int.max })
        XCTAssertTrue(c.ribbons.keys.allSatisfy { CatalogOrder.awardIndex($0) != Int.max })
        XCTAssertEqual(c.chronologicalGames.count, c.games.count)
        let visits = ["vio", "sun", "ruby", "platinum", "as", "sw", "white", "x"]
        XCTAssertEqual(visits.sorted { CatalogOrder.gameIndex($0) < CatalogOrder.gameIndex($1) }, ["ruby", "platinum", "white", "x", "as", "sun", "sw", "vio"])
        XCTAssertEqual(c.chronologicalAwards(["paldea-champion-ribbon", "cool-ribbon-master-hoenn", "cool-ribbon-hoenn", "kalos-champion-ribbon", "sinnoh-champion-ribbon", "galar-champion-ribbon"]),
                       ["cool-ribbon-hoenn", "cool-ribbon-master-hoenn", "sinnoh-champion-ribbon", "kalos-champion-ribbon", "galar-champion-ribbon", "paldea-champion-ribbon"])
        let species = c.nationalDexSpecies
        XCTAssertEqual(species.count, c.pokemon.count)
        XCTAssertEqual(species.first, "bulbasaur")
        XCTAssertEqual(c.dexOrdered([RibbonPokemon(species: "lugia"), RibbonPokemon(species: "pikachu")]).map(\.species), ["pikachu", "lugia"])
        XCTAssertEqual(c.dexNumber(for: "alcremie-caramel-berry"), 869)
        XCTAssertNotEqual(c.speciesPickerName("alcremie-caramel-berry"), c.speciesPickerName("alcremie"))
        let generations = c.chronologicalAwards(Array(c.ribbons.keys)).map { CatalogOrder.awardGeneration($0) }
        XCTAssertEqual(generations, generations.sorted())
    }
    func testOldBoxAndStyleDecodeAndIndependentWallpapersRoundTrip() throws {
        let oldBox = PCBox(name: "Old box")
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(oldBox)) as? [String: Any])
        object.removeValue(forKey: "wallpaper")
        let decoded = try JSONDecoder().decode(PCBox.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(decoded.wallpaper); XCTAssertEqual(decoded.slots.count, 30)
        var oldStyle = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(WidgetStyle())) as? [String: Any])
        oldStyle.removeValue(forKey: "wallpaper")
        XCTAssertNil(try JSONDecoder().decode(WidgetStyle.self, from: JSONSerialization.data(withJSONObject: oldStyle)).wallpaper)
        var layout = StorageLayout(boxes: [decoded, PCBox(name: "Second")])
        XCTAssertNotEqual(layout.wallpaper(for: layout.boxes[0]).sunMoon, layout.wallpaper(for: layout.boxes[1]).sunMoon)
        layout.boxes[0].wallpaper = WallpaperSettings(design: .seaside, tint: "3679B3", strength: 0.8)
        layout.boxes[1].wallpaper = WallpaperSettings(design: .starfield)
        layout.reconcile(pokemonIDs: ["a", "b"])
        let restored = try JSONDecoder().decode(StorageLayout.self, from: JSONEncoder().encode(layout))
        XCTAssertEqual(restored, layout)
        XCTAssertEqual(restored.boxes[0].wallpaper?.tint, "3679B3")
        XCTAssertEqual(restored.boxes[1].wallpaper?.design, .starfield)
    }
    func testManualPokemonGoesToChosenBoxAndKeepsAllDetails() throws {
        let imported = RibbonPokemon(id: "import", species: "lugia", source: "ribbons.guide")
        var snapshot = CollectionSnapshot(pokemon: [imported])
        var layout = snapshot.organizedStorage
        let chosen = PCBox(name: "Favourites"); layout.boxes.append(chosen); snapshot.competitiveStorage = layout
        let entry = RibbonPokemon(species: "pikachu", nickname: " Sparky ", gender: "female", shiny: true, currentgame: "vio", origingame: "as", currentlevel: 50, title: "effort-ribbon", ribbons: ["effort-ribbon", "effort-ribbon"], showdownSet: ShowdownSet(item: "Light Ball", moves: ["Thunderbolt"]))
        try snapshot.addManualPokemon(entry, toBox: chosen.id)
        let added = try XCTUnwrap(snapshot.pokemon.last)
        XCTAssertEqual(added.id, entry.id); XCTAssertEqual(added.source, "manual"); XCTAssertEqual(added.nickname, "Sparky")
        XCTAssertEqual(added.showdownSet, entry.showdownSet); XCTAssertEqual(added.gender, "female"); XCTAssertTrue(added.shiny)
        XCTAssertEqual(added.ribbons, ["effort-ribbon"]); XCTAssertEqual(added.title, "effort-ribbon")
        XCTAssertEqual(added.recordedVisits.map(\.game), ["as", "vio"])
        XCTAssertEqual(snapshot.storage(for: .showdown).boxes.first { $0.id == chosen.id }?.slots[0], entry.id)
        XCTAssertEqual(snapshot.pokemon.first, imported)
        XCTAssertEqual(snapshot.selectedID, entry.id)
        let restored = try JSONDecoder().decode(CollectionSnapshot.self, from: JSONEncoder().encode(snapshot))
        XCTAssertEqual(restored.pokemon, snapshot.pokemon); XCTAssertEqual(restored.storage, snapshot.storage)
        XCTAssertThrowsError(try snapshot.addManualPokemon(entry, toBox: chosen.id))
    }
    func testManualCreationRejectsInvalidEntriesAndExpandsFullStorage() throws {
        var snapshot = CollectionSnapshot()
        XCTAssertThrowsError(try snapshot.addManualPokemon(RibbonPokemon(species: "unknown"), toBox: nil))
        XCTAssertThrowsError(try snapshot.addManualPokemon(RibbonPokemon(species: "pikachu", currentlevel: 101), toBox: nil))
        XCTAssertThrowsError(try snapshot.addManualPokemon(RibbonPokemon(species: "pikachu", currentgame: "unknown"), toBox: nil))
        XCTAssertTrue(snapshot.pokemon.isEmpty)
        for _ in 0..<30 { try snapshot.addManualPokemon(RibbonPokemon(species: "pikachu"), toBox: nil) }
        let full = snapshot.organizedStorage.boxes[0].id
        let extra = RibbonPokemon(species: "eevee")
        try snapshot.addManualPokemon(extra, toBox: full)
        XCTAssertEqual(snapshot.organizedStorage.boxes.count, 2)
        XCTAssertEqual(snapshot.organizedStorage.boxes[1].slots[0], extra.id)
        XCTAssertEqual(Set(snapshot.organizedStorage.boxes.flatMap { $0.slots.compactMap { $0 } }).count, 31)
    }
    @MainActor func testThemePacksAndWallpaperPreviewsRender() throws {
        for pack in WidgetThemePack.allCases {
            for content in WidgetContent.allCases {
                let records = content == .showdownTeam ? SharedStore.showdownPreview().pokemon : SharedStore.demo().pokemon
                let members = content == .pokemon ? records.filter { $0.species == "metagross" } : records
                let sizes: [(PassportSize, CGFloat, CGFloat, String)] = content == .pokemon ? [(.small, 176, 176, "small"), (.medium, 364, 184, "medium"), (.large, 364, 384, "large")] : [(.medium, 364, 184, "medium"), (.large, 364, 384, "large")]
                for (size, width, height, label) in sizes {
                    let dark = pack.style.appearance == .dark
                    let view = ConfiguredWidgetView(pokemon: members, name: "Main team", content: content, size: size, theme: PassportTheme(dark: dark, game: "scar", style: pack.style))
                        .frame(width: width, height: height).environment(\.colorScheme, dark ? .dark : .light)
                    let renderer = ImageRenderer(content: view); renderer.scale = 2
                    let image = try XCTUnwrap(renderer.uiImage)
                    let attachment = XCTAttachment(image: image); attachment.name = "pack-\(pack.rawValue)-\(content.rawValue)-\(label)"; attachment.lifetime = .keepAlways; add(attachment)
                }
            }
        }
        for wallpaper in PixelWallpaper.allCases {
            let view = PixelWallpaperView(settings: WallpaperSettings(design: wallpaper, strength: 0.9), dark: false, base: PassportTheme(dark: false, game: "").board).frame(width: 364, height: 290)
            let renderer = ImageRenderer(content: view); renderer.scale = 2
            let image = try XCTUnwrap(renderer.uiImage)
            let attachment = XCTAttachment(image: image); attachment.name = "wallpaper-\(wallpaper.rawValue)"; attachment.lifetime = .keepAlways; add(attachment)
        }
    }
}

extension CollectionUpdateTests {
    @MainActor func testCollectionScreensRenderWithSharedGenerationEndpoints() throws {
        let store = AppStore()
        var p = try XCTUnwrap(SharedStore.demo().pokemon.first { $0.species == "metagross" })
        p.origingame = "diamond"; p.currentgame = "scar"
        p.visits = [JourneyVisit(game: "pearl"), JourneyVisit(game: "platinum"), JourneyVisit(game: "vio"), JourneyVisit(game: "as")]
        store.snapshot = CollectionSnapshot(pokemon: [p], selectedID: p.id)
        store.snapshot.pokemon.append(SharedStore.showdownPreview().pokemon[0])
        store.snapshot.organizeSections()
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first { $0.isKeyWindow }
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        defer { window.isHidden = true; previous?.makeKey() }
        let preferenceName = "RibbonPassport.RenderTests." + UUID().uuidString
        let preferences = UserDefaults(suiteName: preferenceName)!
        preferences.set(AlbumGrouping.games.rawValue, forKey: "album.grouping")
        preferences.set(true, forKey: "pc.ribbon.partyVisible")
        defer { UserDefaults.standard.removePersistentDomain(forName: preferenceName) }
        let fullStore = AppStore()
        fullStore.snapshot = CollectionSnapshot(pokemon: (0..<30).map { index in
            var record = SharedStore.demo().pokemon[index % 6]; record.id = "grid-\(index)"; return record
        })
        fullStore.snapshot.organizeSections(); fullStore.snapshot.selectedRibbonID = "grid-20"
        var exportRecord = p; exportRecord.ball = "ultra"; exportRecord.language = "en"
        let screens: [(String, AnyView)] = [
            ("updated-pc-box", AnyView(RootView().environmentObject(store))),
            ("aligned-full-pc-grid", AnyView(PCStorageView().environmentObject(fullStore))),
            ("aligned-party-pc-grid", AnyView(PCStorageView().environmentObject(fullStore).defaultAppStorage(preferences))),
            ("passport-game-stamps", AnyView(NavigationStack { StampAlbumView(pokemonID: p.id) }.environmentObject(store).defaultAppStorage(preferences))),
            ("ribbons-guide-export", AnyView(PokemonExportView(selection: PokemonExportSelection(pokemon: [exportRecord], target: .ribbonsGuide)))),
            ("showdown-export", AnyView(PokemonExportView(selection: PokemonExportSelection(pokemon: [SharedStore.showdownPreview().pokemon[2]], target: .showdown)))),
            ("competitive-section", AnyView(PCStorageView(kind: .showdown).environmentObject(store))),
            ("game-search-list", AnyView(SearchableChoiceList(title: "Game", value: .constant("xd"), choices: RibbonCatalog.shared.gameChoices, emptyLabel: "Not set"))),
            ("sunmoon-wallpaper-picker", AnyView(BoxWallpaperEditor(box: store.snapshot.storage(for: .ribbon).boxes[0], settings: WallpaperSettings(sunMoon: .forest)).environmentObject(store))),
            ("passport-multiple-games", AnyView(NavigationStack { StampAlbumView(pokemonID: p.id) }.environmentObject(store))),
            ("add-pokemon-form", AnyView(AddPokemonView(boxID: store.snapshot.organizedStorage.boxes[0].id).environmentObject(store))),
            ("theme-pack-studio", AnyView(NavigationStack { WidgetStudioView() }.environmentObject(store)))
        ]
        for (name, view) in screens {
            let controller = UIHostingController(rootView: view.environment(\.colorScheme, .light))
            window.rootViewController = controller; window.makeKeyAndVisible()
            controller.view.frame = window.bounds; controller.view.setNeedsLayout(); controller.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.3))
            let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in controller.view.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
            let attachment = XCTAttachment(image: image); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
        }
    }
}

final class NavigationAndSearchTests: XCTestCase {
    func testSearchFindsAbbreviationsAndNamesWithoutChangingChronology() throws {
        let choices = RibbonCatalog.shared.gameChoices
        XCTAssertTrue(choices.filter { $0.matches("XD") }.contains { $0.id == "xd" })
        XCTAssertTrue(choices.filter { $0.matches("gale of darkness") }.contains { $0.id == "xd" })
        XCTAssertTrue(choices.filter { $0.matches(" oras ") }.contains { $0.id == "oras" })
        XCTAssertTrue(choices.filter { $0.matches("hgss") }.contains { $0.id == "hgss" })
        XCTAssertTrue(choices.filter { $0.matches("alpha sapphire") }.contains { $0.id == "as" })
        XCTAssertTrue(choices.filter { $0.matches("not-a-real-game") }.isEmpty)
        XCTAssertEqual(choices.filter { $0.matches("") }.map(\.id), RibbonCatalog.shared.chronologicalGames)
        let ribbons = RibbonCatalog.shared.awardChoices(Array(RibbonCatalog.shared.ribbons.keys))
        XCTAssertTrue(ribbons.filter { $0.matches("champion") }.contains { $0.id == "paldea-champion-ribbon" })
        XCTAssertTrue(ribbons.filter { $0.matches("gen iii") }.contains { $0.id == "cool-ribbon-hoenn" })
    }
    func testLegacyMixedStorageSplitsWithoutLosingPositionsOrWallpapers() throws {
        let ribbon = RibbonPokemon(id: "r", species: "lugia")
        let battle = RibbonPokemon(id: "b", species: "pikachu", showdownSet: ShowdownSet(item: "Light Ball"))
        var box = PCBox(name: "Old favourites", wallpaper: WallpaperSettings(sunMoon: .volcano))
        box.slots[4] = ribbon.id; box.slots[17] = battle.id
        var onlyBattle = PCBox(name: "Battle builds"); onlyBattle.slots[2] = "party-battle"
        let partyRibbon = RibbonPokemon(id: "party-ribbon", species: "eevee")
        let partyBattle = RibbonPokemon(id: "party-battle", species: "rayquaza", showdownSet: ShowdownSet())
        let legacy = StorageLayout(boxes: [box, onlyBattle], partyIDs: [partyRibbon.id])
        var snapshot = CollectionSnapshot(pokemon: [ribbon, battle, partyRibbon, partyBattle], storage: legacy)
        snapshot.organizeSections()
        let r = snapshot.storage(for: .ribbon), b = snapshot.storage(for: .showdown)
        XCTAssertEqual(r.boxes.count, 1); XCTAssertEqual(b.boxes.count, 2)
        XCTAssertEqual(r.boxes[0].slots[4], ribbon.id); XCTAssertNil(r.boxes[0].slots[17])
        XCTAssertEqual(b.boxes[0].slots[17], battle.id); XCTAssertNil(b.boxes[0].slots[4])
        XCTAssertEqual(r.wallpaper(for: r.boxes[0]).sunMoon, .volcano); XCTAssertEqual(b.wallpaper(for: b.boxes[0]).sunMoon, .volcano)
        XCTAssertEqual(r.partyIDs, [partyRibbon.id]); XCTAssertTrue(b.partyIDs.isEmpty)
        let beforeR = r, beforeB = b
        snapshot.organizeSections()
        XCTAssertEqual(snapshot.storage(for: .ribbon), beforeR); XCTAssertEqual(snapshot.storage(for: .showdown), beforeB)
        let restored = try JSONDecoder().decode(CollectionSnapshot.self, from: JSONEncoder().encode(snapshot))
        XCTAssertEqual(restored.pokemon, snapshot.pokemon); XCTAssertEqual(restored.storage, r); XCTAssertEqual(restored.competitiveStorage, b)
        let all = [r, b].flatMap { $0.partyIDs + $0.boxes.flatMap { $0.slots.compactMap { $0 } } }
        XCTAssertEqual(Set(all), Set(snapshot.pokemon.map(\.id))); XCTAssertEqual(all.count, 4)
    }
    func testSelectionsAndDefaultsStayWithinEachSection() {
        let a = RibbonPokemon(id: "r", species: "lugia"), b = RibbonPokemon(id: "b", species: "pikachu", showdownSet: ShowdownSet())
        let rt = RibbonTeam(id: "rt", name: "Ribbon team", memberIDs: [a.id]), bt = RibbonTeam(id: "bt", name: "Battle team", memberIDs: [b.id])
        var snapshot = CollectionSnapshot(pokemon: [a, b], teams: [rt, bt], selectedID: b.id, selectedTeamID: bt.id)
        snapshot.selectedRibbonID = a.id; snapshot.selectedCompetitiveID = b.id
        snapshot.selectedRibbonTeamID = rt.id; snapshot.selectedCompetitiveTeamID = bt.id
        XCTAssertEqual(snapshot.selectedPokemonID(for: .ribbon), a.id); XCTAssertEqual(snapshot.selectedPokemonID(for: .showdown), b.id)
        XCTAssertEqual(snapshot.widgetTeam(for: .ribbon), rt); XCTAssertEqual(snapshot.widgetTeam(for: .showdown), bt)
        XCTAssertEqual(snapshot.pokemon(for: .ribbon), [a]); XCTAssertEqual(snapshot.pokemon(for: .showdown), [b])
        XCTAssertEqual(TeamKind.ribbon.widgetContents, [.pokemon, .ribbonTeam]); XCTAssertEqual(TeamKind.showdown.widgetContents, [.showdownTeam])
        XCTAssertEqual(snapshot.section(forPokemon: b.id), .showdown)
    }
    @MainActor func testAllSixteenSunMoonWallpapersAreBundledAndRender() throws {
        XCTAssertEqual(SunMoonWallpaper.allCases.count, 16)
        for wallpaper in SunMoonWallpaper.allCases {
            let image = try XCTUnwrap(BoxWallpaperView.image(for: wallpaper), wallpaper.name)
            XCTAssertEqual(image.size, CGSize(width: 208, height: 192))
            for full in [false, true] {
                let renderer = ImageRenderer(content: BoxWallpaperView(settings: WallpaperSettings(sunMoon: wallpaper), fullArtwork: full).frame(width: 364, height: full ? 336 : 290))
                renderer.scale = 2
                let rendered = try XCTUnwrap(renderer.uiImage)
                let attachment = XCTAttachment(image: rendered); attachment.name = "sunmoon-\(wallpaper.rawValue)-\(wallpaper.name)-\(full ? "full" : "grid")"; attachment.lifetime = .keepAlways; add(attachment)
            }
        }
    }
}

final class GridAlbumExportTests: XCTestCase {
    func testPartyDropSwapsWhenFullAndRejectsOtherSections() throws {
        let ids = (0..<7).map { "party-drag-\($0)" }
        let records = ids.map { RibbonPokemon(id: $0, species: "pikachu") } + [RibbonPokemon(id: "competitive-drag", species: "eevee", showdownSet: ShowdownSet())]
        var box = PCBox(id: "party-drag-box"); box.slots[0] = ids[0]
        var snapshot = CollectionSnapshot(pokemon: records, storage: StorageLayout(boxes: [box], partyIDs: Array(ids.dropFirst())))
        snapshot.organizeSections()
        XCTAssertTrue(snapshot.movePokemonToParty(ids[0], in: .ribbon, slot: 4))
        XCTAssertEqual(snapshot.storage?.partyIDs[4], ids[0])
        XCTAssertEqual(snapshot.storage?.boxes[0].slots[0], ids[5])
        XCTAssertEqual(snapshot.storage?.partyIDs.count, 6)
        let before = snapshot.storage
        XCTAssertFalse(snapshot.movePokemonToParty("competitive-drag", in: .ribbon, slot: 0))
        XCTAssertFalse(snapshot.movePokemonToParty(ids[0], in: .ribbon, slot: 6))
        XCTAssertEqual(snapshot.storage, before)
        let restored = try JSONDecoder().decode(CollectionSnapshot.self, from: JSONEncoder().encode(snapshot))
        XCTAssertEqual(restored.storage, snapshot.storage)
    }
    func testPartyReorderAndEmptyDropKeepUniqueCompactRecords() {
        var box = PCBox(); box.slots[0] = "c"
        var layout = StorageLayout(boxes: [box], partyIDs: ["a", "b"])
        XCTAssertTrue(layout.moveToParty("a", slot: 1))
        XCTAssertEqual(layout.partyIDs, ["b", "a"])
        XCTAssertTrue(layout.moveToParty("c", slot: 5))
        XCTAssertEqual(layout.partyIDs, ["b", "a", "c"])
        XCTAssertNil(layout.boxes[0].slots[0])
        XCTAssertTrue(layout.move("a", toBox: box.id, slot: 12))
        XCTAssertEqual(layout.partyIDs, ["b", "c"])
        XCTAssertEqual(layout.boxes[0].slots[12], "a")
        XCTAssertFalse(layout.moveToParty("missing", slot: 0))
    }
    func testDragHitTestingUsesExactSlotFramesAndRejectsOutsideDrops() {
        let frames: [PCSlotTarget: CGRect] = [
            .box("first", 0): CGRect(x: 40, y: 100, width: 32, height: 30),
            .box("first", 1): CGRect(x: 72, y: 100, width: 32, height: 30),
            .party(0): CGRect(x: 0, y: 100, width: 35, height: 31),
            .page(1): CGRect(x: 280, y: 40, width: 33, height: 44)
        ]
        XCTAssertEqual(PCSlotTarget.hit(at: CGPoint(x: 71.9, y: 115), frames: frames), .box("first", 0))
        XCTAssertEqual(PCSlotTarget.hit(at: CGPoint(x: 72, y: 115), frames: frames), .box("first", 1))
        XCTAssertEqual(PCSlotTarget.hit(at: CGPoint(x: 18, y: 115), frames: frames), .party(0))
        XCTAssertEqual(PCSlotTarget.hit(at: CGPoint(x: 300, y: 62), frames: frames), .page(1))
        XCTAssertNil(PCSlotTarget.hit(at: CGPoint(x: 37, y: 115), frames: frames))
        XCTAssertNil(PCSlotTarget.hit(at: CGPoint(x: 200, y: 600), frames: frames))
    }
    func testGridMatchesSunMoonArtworkTileBoundaries() throws {
        XCTAssertEqual(PCGridMetrics.columns, 6); XCTAssertEqual(PCGridMetrics.rows, 5)
        XCTAssertEqual(PCGridMetrics.gridWidth / Double(PCGridMetrics.columns), 32)
        XCTAssertEqual(PCGridMetrics.gridHeight / Double(PCGridMetrics.rows), 30)
        let image = try XCTUnwrap(BoxWallpaperView.image(for: .simple)?.cgImage)
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = try XCTUnwrap(CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        // This checks the bundled wallpaper, so changing its crop cannot silently shift the slots.
        let y = 110
        func brightness(_ x: Int) -> Int { let offset = (y * width + x) * 4; return (Int(pixels[offset]) + Int(pixels[offset + 1]) + Int(pixels[offset + 2])) / 3 }
        for boundary in [40, 72, 104, 136, 168] { XCTAssertGreaterThan(abs(brightness(boundary - 1) - brightness(boundary)), 4) }
        XCTAssertEqual(PCGridMetrics.originX, 8); XCTAssertEqual(PCGridMetrics.originY, 36)
    }
    func testDraggedPokemonSwapsAcrossBoxesAndCannotCrossSections() throws {
        let a = RibbonPokemon(id: "a", species: "pikachu"), b = RibbonPokemon(id: "b", species: "lugia")
        let c = RibbonPokemon(id: "c", species: "eevee", showdownSet: ShowdownSet())
        var first = PCBox(), second = PCBox(name: "Box 02")
        first.slots[0] = a.id; second.slots[29] = b.id
        var snapshot = CollectionSnapshot(pokemon: [a, b, c], storage: StorageLayout(boxes: [first, second]))
        snapshot.organizeSections()
        XCTAssertTrue(snapshot.movePokemon(a.id, in: .ribbon, toBox: second.id, slot: 29))
        XCTAssertEqual(snapshot.storage?.boxes[0].slots[0], b.id); XCTAssertEqual(snapshot.storage?.boxes[1].slots[29], a.id)
        XCTAssertEqual(snapshot.selectedPokemonID(for: .ribbon), a.id)
        let before = snapshot.storage
        XCTAssertFalse(snapshot.movePokemon(c.id, in: .ribbon, toBox: first.id, slot: 0))
        XCTAssertFalse(snapshot.movePokemon(a.id, in: .ribbon, toBox: "missing-box", slot: 0))
        XCTAssertFalse(snapshot.movePokemon(a.id, in: .ribbon, toBox: first.id, slot: 30))
        XCTAssertEqual(snapshot.storage, before)
        let restored = try JSONDecoder().decode(CollectionSnapshot.self, from: JSONEncoder().encode(snapshot))
        XCTAssertEqual(restored.storage, snapshot.storage); XCTAssertEqual(restored.competitiveStorage, snapshot.competitiveStorage)
    }
    func testVisitedGamesKeepBothSameGenerationEndpointsAndDeduplicateVisits() {
        var p = RibbonPokemon(species: "pikachu", currentgame: "vio", origingame: "scar")
        p.visits = [JourneyVisit(game: "scar"), JourneyVisit(game: "vio"), JourneyVisit(game: "scar")]
        XCTAssertEqual(p.visitedGenerations, [9]); XCTAssertEqual(p.recordedVisits.map(\.game), ["scar", "vio"])
        XCTAssertEqual(AlbumGrouping.allCases.map(\.rawValue), ["generations", "games"])
    }
    func testManualPokemonExportsToShowdownWithOnlySupportedFields() throws {
        var p = RibbonPokemon(species: "pikachu", nickname: "Sparky", gender: "female", shiny: true, currentgame: "vio", origingame: "as", currentlevel: 50, title: "effort-ribbon", ribbons: ["effort-ribbon"], source: "manual")
        p.visits = [JourneyVisit(game: "sun")]; p.earnedGenerations = ["effort-ribbon": 6]
        let text = try ShowdownExporter.validatedExport([p])
        let restored = try XCTUnwrap(ShowdownImporter.parse(text).first)
        XCTAssertEqual(restored.species, p.species); XCTAssertEqual(restored.nickname, p.nickname); XCTAssertEqual(restored.currentlevel, 50)
        XCTAssertTrue(restored.shiny); XCTAssertEqual(restored.gender, "female")
        for excluded in ["effort-ribbon", "vio", "origingame", "visits", "earnedGenerations", "manual", p.id] { XCTAssertFalse(text.contains(excluded)) }
        XCTAssertTrue(restored.ribbons.isEmpty)
    }
    func testShowdownValidationAndSanitizingPreventBrokenImportText() throws {
        var p = RibbonPokemon(species: "rayquaza", nickname: "Ray\n\nPikachu @ Light Ball", showdownSet: ShowdownSet(nature: "jolly", evs: "252 Attack / 4 Sp. Def / 252 Speed", ivs: "0 Sp. Atk", teraType: "normal", moves: ["Dragon Ascent", "Extreme Speed"]))
        let text = try ShowdownExporter.validatedExport([p]), restored = try ShowdownImporter.parse(text)
        XCTAssertEqual(restored.count, 1); XCTAssertEqual(restored[0].showdownSet?.nature, "Jolly")
        XCTAssertEqual(restored[0].showdownSet?.evs, "252 Atk / 4 SpD / 252 Spe"); XCTAssertEqual(restored[0].showdownSet?.ivs, "0 SpA")
        XCTAssertEqual(restored[0].showdownSet?.moves, ["Dragon Ascent", "Extreme Speed"])
        XCTAssertThrowsError(try ShowdownExporter.validatedExport(Array(repeating: p, count: 7)))
        p.showdownSet?.evs = "252 Atk / 252 Def / 252 Spe"; XCTAssertThrowsError(try ShowdownExporter.validatedExport([p]))
        p.showdownSet?.evs = ""; p.showdownSet?.ivs = "32 Atk"; XCTAssertThrowsError(try ShowdownExporter.validatedExport([p]))
        p.showdownSet?.ivs = ""; p.showdownSet?.nature = "made-up"; XCTAssertThrowsError(try ShowdownExporter.validatedExport([p]))
    }
    func testRibbonsGuideExportHasRequiredSchemaAndOmitsAppMetadata() throws {
        var p = RibbonPokemon(species: "pikachu", nickname: "Sparky", shiny: true, currentgame: "vio", origingame: "as", currentlevel: 50, title: "effort-ribbon", ribbons: ["effort-ribbon", "effort-ribbon", "not-real"], source: "manual", showdownSet: ShowdownSet(item: "Light Ball"), language: "ja", ball: "ultra")
        p.visits = [JourneyVisit(game: "sun")]; p.earnedGenerations = ["effort-ribbon": 6]
        let data = try RibbonsGuideExporter.export([p], date: Date(timeIntervalSince1970: 123))
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(root.keys), Set(["fileVersion", "lastModified", "settings", "boxes", "pokemon"]))
        XCTAssertEqual(root["fileVersion"] as? Int, 5); XCTAssertEqual(root["lastModified"] as? Int, 123000)
        let entry = try XCTUnwrap((root["pokemon"] as? [[String: Any]])?.first)
        XCTAssertEqual(entry["shiny"] as? String, "star"); XCTAssertEqual(entry["ribbons"] as? [String], ["effort-ribbon"])
        XCTAssertEqual(entry["ball"] as? String, "ultra"); XCTAssertEqual(entry["language"] as? String, "ja")
        XCTAssertEqual(entry["achievements"] as? [String], []); XCTAssertEqual(entry["box"] as? Int, -1)
        for key in ["id", "source", "visits", "earnedGenerations", "showdownSet", "storage", "widgetPresets", "titleText"] { XCTAssertNil(entry[key]) }
        let restored = try XCTUnwrap(BackupImporter.parse(data).first)
        XCTAssertEqual(restored.species, p.species); XCTAssertEqual(restored.currentgame, p.currentgame); XCTAssertEqual(restored.ribbons, ["effort-ribbon"])
        XCTAssertEqual(restored.language, "ja"); XCTAssertEqual(restored.ball, "ultra")
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json"); attachment.name = "ribbons-guide-compatible-fixture.json"; attachment.lifetime = .keepAlways; add(attachment)
    }
    func testRibbonsGuideDefaultsAreExplicitAndTemporaryFormsUseSupportedSpecies() throws {
        var p = RibbonPokemon(species: "charizard-mega-x", shiny: false, currentgame: "not-real", ribbons: [])
        XCTAssertThrowsError(try RibbonsGuideExporter.export([p]))
        let data = try RibbonsGuideExporter.export([p], fallbackBall: "poke", fallbackLanguage: "en")
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any]), entry = try XCTUnwrap((root["pokemon"] as? [[String: Any]])?.first)
        XCTAssertEqual(entry["species"] as? String, "charizard"); XCTAssertEqual(entry["shiny"] as? Bool, false)
        XCTAssertEqual(entry["currentgame"] as? String, "")
        p.title = "partner-ribbon"; p.ribbons = ["partner-ribbon"]
        XCTAssertThrowsError(try RibbonsGuideExporter.export([p], fallbackBall: "poke", fallbackLanguage: "en"))
        XCTAssertNoThrow(try RibbonsGuideExporter.export([p], fallbackBall: "poke", fallbackLanguage: "en", fallbackTrainer: "Liam"))
    }
    func testAppendingWebsiteBackupPreservesExistingRecordsSettingsAndBoxes() throws {
        let backup = Data(#"{"fileVersion":5,"lastModified":1,"boxes":["Old favourites"],"settings":{"theme":"dark","language":"fr"},"pokemon":[{"species":"lugia","nickname":"Lugia","ribbons":["earth-ribbon"],"ball":"poke","language":"fr","notes":"Keep me","box":0}]}"#.utf8)
        let p = RibbonPokemon(species: "pikachu", language: "en", ball: "luxury")
        let data = try RibbonsGuideExporter.export([p], merging: backup), root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(root["boxes"] as? [String], ["Old favourites"]); XCTAssertEqual((root["settings"] as? [String: String])?["theme"], "dark")
        let entries = try XCTUnwrap(root["pokemon"] as? [[String: Any]])
        XCTAssertEqual(entries.count, 2); XCTAssertEqual(entries[0]["notes"] as? String, "Keep me"); XCTAssertEqual(entries[0]["box"] as? Int, 0)
        XCTAssertEqual(entries[1]["species"] as? String, "pikachu")
        XCTAssertThrowsError(try RibbonsGuideExporter.export([p], merging: Data(#"{"fileVersion":4}"#.utf8)))
    }
}

final class TerminalPassportRenderTests: XCTestCase {
    @MainActor func testTerminalAndPassportTabsRenderAtCompactWidthsInBothThemes() throws {
        var snapshot = SharedStore.demo()
        snapshot.organizeSections()
        let store = AppStore(snapshot: snapshot, save: { _ in })
        let pokemon = try XCTUnwrap(store.snapshot.pokemon(for: .ribbon).first)
        let defaultsName = "RibbonPassport.TerminalRender." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsName))
        defer { defaults.removePersistentDomain(forName: defaultsName) }
        for width: CGFloat in [320, 390] {
            for dark in [false, true] {
                for screen in ["terminal", "terminal-party", "overview", "ribbons", "journey"] {
                    defaults.set(screen == "terminal-party", forKey: "pc.ribbon.partyVisible")
                    let view: AnyView
                    if screen.hasPrefix("terminal") { view = AnyView(PCStorageView()) }
                    else {
                        let section = PassportSection.allCases.first { $0.rawValue.lowercased() == screen }!
                        view = AnyView(NavigationStack { StampAlbumView(pokemonID: pokemon.id, section: section) })
                    }
                    let size = CGSize(width: width, height: 844)
                    let window = UIWindow(frame: CGRect(origin: .zero, size: size))
                    let controller = UIHostingController(rootView: view.environmentObject(store).defaultAppStorage(defaults).environment(\.colorScheme, dark ? .dark : .light))
                    window.rootViewController = controller; window.makeKeyAndVisible()
                    controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
                    RunLoop.main.run(until: Date().addingTimeInterval(0.2))
                    let image = UIGraphicsImageRenderer(size: size).image { _ in controller.view.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
                    let attachment = XCTAttachment(image: image); attachment.name = "terminal-\(screen)-\(Int(width))-\(dark ? "dark" : "light")"; attachment.lifetime = .keepAlways; add(attachment)
                    XCTAssertEqual(image.size, size)
                    window.isHidden = true
                }
            }
        }
    }
}
