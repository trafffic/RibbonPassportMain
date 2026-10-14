import XCTest
import SwiftUI
import UIKit
@testable import RibbonPassport

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
        let screens: [(String, AnyView)] = [
            ("updated-pc-box", AnyView(RootView().environmentObject(store))),
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
            let renderer = ImageRenderer(content: BoxWallpaperView(settings: WallpaperSettings(sunMoon: wallpaper)).frame(width: 364, height: 290))
            renderer.scale = 2
            let rendered = try XCTUnwrap(renderer.uiImage)
            let attachment = XCTAttachment(image: rendered); attachment.name = "sunmoon-\(wallpaper.rawValue)-\(wallpaper.name)"; attachment.lifetime = .keepAlways; add(attachment)
        }
    }
}
