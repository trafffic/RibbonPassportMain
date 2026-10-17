import XCTest
import SwiftUI
import UIKit
@testable import RibbonPassport

final class CommunityTests: XCTestCase {
    func testBundledGuidesCoverEveryExistingAwardGamePairAndHaveSources() throws {
        let content = CommunityContent.shared
        XCTAssertEqual(content.guideModules.count, 25)
        let sourceIDs = Set(content.sources.map(\.id))
        XCTAssertEqual(sourceIDs.count, content.sources.count)
        var pairs = 0
        for (id, rule) in RibbonRules.shared.awards {
            for game in rule.games {
                let guides = content.guides(award: id, game: game)
                XCTAssertEqual(guides.count, 1, "\(id) / \(game)")
                XCTAssertFalse(try XCTUnwrap(guides.first).steps.isEmpty)
                XCTAssertTrue(Set(guides[0].sourceIDs).isSubset(of: sourceIDs))
                pairs += 1
            }
        }
        XCTAssertEqual(pairs, 423)
        XCTAssertTrue(content.sources.allSatisfy { $0.link != nil && !$0.author.isEmpty })
        XCTAssertTrue(content.guides(award: "rare-mark").isEmpty)
        for honor in content.honorDefinitions { XCTAssertTrue(Set(honor.sourceIDs).isSubset(of: sourceIDs)) }
    }
    func testCommunityCopiesAreIndependentAttributedAndExportable() throws {
        for original in CommunityContent.shared.teamCandidates {
            var collection = CollectionSnapshot()
            let id = try XCTUnwrap(collection.copyCommunityTeam(original, game: original.gameIDs[0]))
            let copy = try XCTUnwrap(collection.teams.first { $0.id == id })
            XCTAssertEqual(copy.communitySourceIDs, original.sourceIDs)
            let members = collection.members(teamID: id)
            XCTAssertEqual(members.count, original.members.count)
            XCTAssertTrue(members.allSatisfy { $0.communitySourceIDs == original.sourceIDs })
            let export = try ShowdownExporter.validatedExport(members)
            XCTAssertFalse(export.isEmpty, original.id)
            let id2 = try XCTUnwrap(collection.copyCommunityTeam(original, game: original.gameIDs[0]))
            XCTAssertTrue(Set(collection.members(teamID: id2).map(\.id)).isDisjoint(with: members.map(\.id)))
            collection.pokemon[0].showdownSet?.item = "Changed"
            XCTAssertNotEqual(original.members[0].item, "Changed")
        }
    }
    func testLegacyDecodeAndCompleteAppBackupRetainLocalRecordsAndImages() throws {
        let legacy = try JSONDecoder().decode(CollectionSnapshot.self, from: Data("{\"pokemon\":[],\"teams\":[],\"selectedID\":\"\",\"selectedTeamID\":\"\",\"appearance\":\"automatic\",\"updatedAt\":0}".utf8))
        XCTAssertNil(legacy.sourceNotes)
        var p = RibbonPokemon(species: "metagross", currentgame: "as", origingame: "emerald")
        p.honors = [PassportHonor(catalogID: "custom", title: "A milestone", game: "emerald", photo: Data([1,2,3]))]
        p.journal = [PassportJournalEntry(title: "A memory", photo: Data([4,5,6]))]
        p.moveNotes = [PassportMoveNote(move: "Meteor Mash", game: "as", homeChecked: true)]
        p.savedBuilds = [PersonalBuild(name: "First", build: ShowdownSet(item: "Leftovers"), sourceIDs: ["peterko-paste"])]
        let value = CollectionSnapshot(pokemon: [p], sourceNotes: ["athis-rse":"Check this route"])
        let decoded = try PassportAppBackup.decode(PassportAppBackup(collection: value).encoded())
        XCTAssertEqual(decoded.pokemon, value.pokemon); XCTAssertEqual(decoded.sourceNotes, value.sourceNotes)
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: PassportAppBackup(collection: value).encoded()) as? [String: Any]); root["version"] = 99
        XCTAssertThrowsError(try PassportAppBackup.decode(JSONSerialization.data(withJSONObject: root)))
    }
    func testOptionalHonorsNeverChangeAwardsAndDeletionRecoversPhotos() throws {
        var p = RibbonPokemon(species: "metagross", currentgame: "platinum", origingame: "emerald", ribbons: ["effort-ribbon"])
        let count = p.displayedAwardIDs.count
        let status = RibbonRules.shared.transferCheck(from: p.currentgame, pokemon: p).lastChance
        p.honors = [PassportHonor(catalogID: "pwt", title: "World Tournament", game: "black2", photo: Data([7,8]), trainerMilestone: true)]
        p.journal = [PassportJournalEntry(title: "Story")]
        XCTAssertEqual(p.displayedAwardIDs.count, count)
        XCTAssertEqual(RibbonRules.shared.transferCheck(from: p.currentgame, pokemon: p).lastChance, status)
        let before = CollectionSnapshot(pokemon: [p]); var after = before
        after.pokemon[0].honors = []; after.pokemon[0].journal = []
        after.captureRecovery(from: before)
        try after.restoreRecoveryEntry(XCTUnwrap(after.recoveryHistory?.first?.id))
        XCTAssertEqual(after.pokemon[0].honors, p.honors); XCTAssertEqual(after.pokemon[0].journal, p.journal)
    }
    @MainActor func testWebsiteImportMetadataPreservationAndExternalExportsExcludeAppNotes() throws {
        var old = RibbonPokemon(species: "metagross", currentgame: "as", origingame: "emerald", ribbons: ["effort-ribbon"], source: "ribbons.guide", language: "english", ball: "poke-ball", trainername: "Trainer")
        old.journal = [PassportJournalEntry(title: "Private story")]
        old.honors = [PassportHonor(catalogID: "custom", title: "Private honor", game: "emerald")]
        var incoming = old; incoming.journal = nil; incoming.honors = nil
        incoming.preservePassportExtras(from: old)
        XCTAssertEqual(incoming.journal, old.journal); XCTAssertEqual(incoming.honors, old.honors)
        let data = try RibbonsGuideExporter.export([incoming], fallbackBall: RibbonsGuideExporter.balls[0].id, fallbackLanguage: RibbonsGuideExporter.languages[0].id)
        let text = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertFalse(text.contains("Private story")); XCTAssertFalse(text.contains("Private honor")); XCTAssertFalse(text.contains("journal"))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        try data.write(to: url); defer { try? FileManager.default.removeItem(at: url) }
        let store = AppStore(snapshot: CollectionSnapshot(pokemon: [old]), save: { _ in })
        store.importBackup(url)
        XCTAssertNil(store.error); XCTAssertEqual(store.snapshot.pokemon.first?.id, old.id)
        XCTAssertEqual(store.snapshot.pokemon.first?.journal, old.journal); XCTAssertEqual(store.snapshot.pokemon.first?.honors, old.honors)
    }
    @MainActor func testTeamVersionApplyPreservesPassportAndRestoresMissingMembers() throws {
        var p = RibbonPokemon(id: "a", species: "pikachu", nickname: "Original", currentgame: "scar", currentlevel: 50, source: "showdown", showdownSet: ShowdownSet(item: "Light Ball"))
        p.journal = [PassportJournalEntry(title: "Keep this")]
        let missing = TeamBuildMember(id: "missing", species: "garchomp", nickname: "Partner", build: ShowdownSet(item: "Lum Berry"), level: 50, game: "as", shiny: true)
        let version = PersonalTeamBuild(name: "Old version", members: [TeamBuildMember(id: p.id, species: p.species, nickname: "Different name", build: ShowdownSet(item: "Leftovers")), missing], sourceIDs: ["athis-starter"])
        var value = CollectionSnapshot(pokemon: [p], teams: [RibbonTeam(id: "t", name: "Team", memberIDs: [p.id])]); value.organizeSections()
        value.restoreTeamBuild(version, teamID: "t")
        XCTAssertEqual(value.pokemon[0].nickname, "Original"); XCTAssertEqual(value.pokemon[0].currentgame, "scar")
        XCTAssertEqual(value.pokemon[0].journal, p.journal); XCTAssertEqual(value.pokemon[0].showdownSet?.item, "Leftovers")
        let restored = try XCTUnwrap(value.members(teamID: "t").last)
        XCTAssertEqual(restored.currentlevel, 50); XCTAssertTrue(restored.shiny); XCTAssertEqual(restored.currentgame, "as")
        XCTAssertEqual(restored.communitySourceIDs, version.sourceIDs)
    }
    @MainActor func testAppBackupRestoreMergesRecoveryAndFailureDoesNotMutateCollection() throws {
        let original = RibbonPokemon(id: "old", species: "pikachu", nickname: "Original")
        let store = AppStore(snapshot: CollectionSnapshot(pokemon: [original]), save: { _ in })
        var historical = original; historical.nickname = "Older"
        let history = RecoveryEntry(action: .edited, kind: .pokemon, objectID: original.id, section: .ribbon, pokemon: historical)
        var incoming = CollectionSnapshot(pokemon: [original], recoveryHistory: [history]); incoming.pokemon[0].nickname = "From backup"
        store.restoreAppBackup(incoming)
        XCTAssertEqual(store.snapshot.pokemon[0].nickname, "From backup")
        XCTAssertTrue(store.snapshot.recoveryHistory?.contains { $0.id == history.id } == true)
        XCTAssertTrue(store.snapshot.recoveryHistory?.contains { $0.pokemon?.nickname == "Original" } == true)
        let failing = AppStore(snapshot: CollectionSnapshot(pokemon: [original]), save: { _ in throw ImportError.invalid("Disk full") })
        failing.restoreAppBackup(incoming)
        XCTAssertEqual(failing.snapshot.pokemon[0], original); XCTAssertNotNil(failing.error)
    }
    func testDateValidationAndOriginAwareHonorGames() {
        XCTAssertTrue(PassportNotes.validDate("")); XCTAssertTrue(PassportNotes.validDate("2024-02-29"))
        XCTAssertFalse(PassportNotes.validDate("2025-02-29")); XCTAssertFalse(PassportNotes.validDate("16/10/2026"))
        let p = RibbonPokemon(species: "metagross", currentgame: "scar", origingame: "scar")
        XCTAssertFalse(PassportNotes.games(for: p).contains("hg")); XCTAssertFalse(PassportNotes.games(for: p).contains("red"))
    }
    @MainActor func testNewScreensRenderAtCompactWidths() throws {
        var value = SharedStore.showdownPreview(); value.organizeSections()
        let sample = try XCTUnwrap(value.pokemon.first); let store = AppStore(snapshot: value, save: { _ in })
        let guide = try XCTUnwrap(CommunityContent.shared.guideModules.first { $0.id == "rse-tower" })
        let team = try XCTUnwrap(CommunityContent.shared.teamCandidates.first)
        for width: CGFloat in [320, 390] {
            for dark in [false, true] {
                let screens: [(String,AnyView)] = [
                    ("guide",AnyView(FieldGuideDetailView(guide: guide, initialGame: "emerald"))),
                    ("library",AnyView(CommunityTeamLibraryView())),
                    ("team",AnyView(CommunityTeamDetailView(team: team))),
                    ("honors",AnyView(HonorAlbumView(pokemonID: sample.id))),
                    ("honor",AnyView(HonorRecordEditor(pokemonID: sample.id, record: PassportHonor(catalogID: "custom", title: "Long milestone title", game: "as")))),
                    ("notes",AnyView(JourneyNotesView(pokemonID: sample.id))),
                    ("notebook",AnyView(BuildNotebookView(pokemonID: sample.id))),
                    ("source",AnyView(SourceReviewView(source: CommunityContent.shared.sources[0]))),
                    ("credits",AnyView(SourcesCreditsView()))]
                for (name,view) in screens {
                    let size = CGSize(width: width, height: 720); let window = UIWindow(frame: CGRect(origin: .zero, size: size))
                    let host = UIHostingController(rootView: NavigationStack { view }.environmentObject(store).environment(\.colorScheme, dark ? .dark : .light).textFieldStyle(TerminalFieldStyle()).buttonStyle(RetroAction()))
                    window.rootViewController = host; window.makeKeyAndVisible(); host.view.frame = window.bounds; host.view.layoutIfNeeded()
                    RunLoop.main.run(until: Date().addingTimeInterval(0.1))
                    let image = UIGraphicsImageRenderer(size: size).image { _ in host.view.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
                    let attachment = XCTAttachment(image: image); attachment.name = "community-\(name)-\(Int(width))-\(dark ? "dark" : "light")"; attachment.lifetime = .keepAlways; add(attachment)
                    XCTAssertEqual(image.size, size); window.isHidden = true
                }
            }
        }
    }
}
