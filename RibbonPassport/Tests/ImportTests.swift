import XCTest
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
