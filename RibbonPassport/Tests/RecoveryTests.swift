import XCTest
import SwiftUI
import UIKit
@testable import RibbonPassport

final class RecoveryTests: XCTestCase {
    private func fixture() -> CollectionSnapshot {
        let a = RibbonPokemon(id: "recovery-a", species: "metagross", nickname: "Atlas", currentgame: "as", origingame: "emerald", currentlevel: 70,
                              title: "effort-ribbon", ribbons: ["effort-ribbon"], visits: [JourneyVisit(id: "visit", game: "platinum")],
                              earnedGenerations: ["effort-ribbon": 6], earnedGames: ["effort-ribbon": "as"], metLevel: 5)
        let b = RibbonPokemon(id: "recovery-b", species: "pikachu", currentgame: "sw")
        let c = RibbonPokemon(id: "recovery-c", species: "garchomp", source: "showdown", showdownSet: ShowdownSet(item: "Life Orb", moves: ["Earthquake"]))
        var box = PCBox(id: "recovery-box", name: "Travellers", wallpaper: WallpaperSettings(sunMoon: .forest))
        box.slots[12] = a.id; box.slots[0] = b.id
        var snapshot = CollectionSnapshot(pokemon: [a, b, c], teams: [RibbonTeam(id: "recovery-team", name: "Travellers", memberIDs: [a.id, b.id])], selectedID: a.id, storage: StorageLayout(boxes: [box]))
        snapshot.organizeSections(); return snapshot
    }
    private func record(_ before: CollectionSnapshot, changing change: (inout CollectionSnapshot) -> Void) -> CollectionSnapshot {
        var next = before; change(&next); next.organizeSections(); next.captureRecovery(from: before); return next
    }
    func testSavedChangesCaptureCompletePreviousDetailsAndNoOpDoesNotAddVersions() throws {
        let before = fixture()
        let next = record(before) { $0.pokemon[0].nickname = "Changed"; $0.pokemon[0].removeAward("effort-ribbon") }
        let entry = try XCTUnwrap(next.recoveryHistory?.first)
        XCTAssertEqual(entry.pokemon, before.pokemon[0]); XCTAssertEqual(entry.action, .edited)
        XCTAssertEqual(entry.location?.slot, 12); XCTAssertEqual(entry.memberships.first?.team, before.teams[0])
        var noOp = next; noOp.selectedID = "recovery-b"; noOp.appearance = .dark
        noOp.captureRecovery(from: next)
        XCTAssertEqual(noOp.recoveryHistory, next.recoveryHistory)
        var moved = next
        XCTAssertTrue(moved.movePokemon("recovery-a", in: .ribbon, toBox: "recovery-box", slot: 3))
        moved.captureRecovery(from: next)
        XCTAssertEqual(moved.recoveryHistory, next.recoveryHistory)
    }
    func testRecoverDeletedPokemonKeepsIdentityLocationAndTeamWithoutDuplicates() throws {
        let before = fixture()
        var deleted = record(before) { $0.removePokemon(id: "recovery-a") }
        let entry = try XCTUnwrap(deleted.recoveryEntries(kind: .pokemon, id: "recovery-a").first)
        XCTAssertEqual(entry.action, .deleted)
        try deleted.restoreRecoveryEntry(entry.id)
        XCTAssertEqual(deleted.pokemon.first { $0.id == "recovery-a" }, before.pokemon[0])
        XCTAssertEqual(deleted.storage?.boxes[0].slots[12], "recovery-a")
        XCTAssertEqual(deleted.teams.first { $0.id == "recovery-team" }?.memberIDs, ["recovery-a", "recovery-b"])
        try deleted.restoreRecoveryEntry(entry.id)
        XCTAssertEqual(deleted.pokemon.filter { $0.id == "recovery-a" }.count, 1)
        XCTAssertEqual(deleted.teams.first?.memberIDs.filter { $0 == "recovery-a" }.count, 1)
    }
    func testRecoverDoesNotDisplaceOccupiedSlotOrFullParty() throws {
        var before = fixture()
        var next = record(before) { $0.removePokemon(id: "recovery-a") }
        XCTAssertTrue(next.movePokemon("recovery-b", in: .ribbon, toBox: "recovery-box", slot: 12))
        let id = try XCTUnwrap(next.recoveryEntries(kind: .pokemon, id: "recovery-a").first?.id)
        try next.restoreRecoveryEntry(id)
        XCTAssertEqual(next.storage?.boxes[0].slots[12], "recovery-b")
        XCTAssertEqual(next.storage?.boxes.flatMap(\.slots).compactMap { $0 }.filter { $0 == "recovery-a" }.count, 1)
        var party = before.storage(for: .ribbon)
        XCTAssertTrue(party.moveToParty("recovery-a")); before.storage = party
        next = record(before) { $0.removePokemon(id: "recovery-a") }
        for n in 0..<6 { next.pokemon.append(RibbonPokemon(id: "party-\(n)", species: "pikachu")) }
        next.storage?.partyIDs = (0..<6).map { "party-\($0)" }; next.organizeSections()
        try next.restoreRecoveryEntry(XCTUnwrap(next.recoveryEntries(kind: .pokemon, id: "recovery-a").first?.id))
        XCTAssertEqual(next.storage?.partyIDs, (0..<6).map { "party-\($0)" })
        XCTAssertTrue(next.storage?.boxes.flatMap(\.slots).contains("recovery-a") == true)
    }
    func testRestoreExistingVersionKeepsPlacementAndCanBeReversed() throws {
        let before = fixture()
        var changed = record(before) { $0.pokemon[0].nickname = "New name" }
        XCTAssertTrue(changed.movePokemon("recovery-a", in: .ribbon, toBox: "recovery-box", slot: 7))
        let recent = changed
        try changed.restoreRecoveryEntry(XCTUnwrap(changed.recoveryHistory?.first?.id))
        changed.captureRecovery(from: recent, action: .restored)
        XCTAssertEqual(changed.pokemon[0].nickname, "Atlas")
        XCTAssertEqual(changed.storage?.boxes[0].slots[7], "recovery-a")
        let undo = try XCTUnwrap(changed.recoveryEntries(kind: .pokemon, id: "recovery-a").first)
        XCTAssertEqual(undo.action, .restored)
        try changed.restoreRecoveryEntry(undo.id)
        XCTAssertEqual(changed.pokemon[0].nickname, "New name")
    }
    func testTeamVersionsAndDeletedTeamsRestoreOrderAndAvailableMembersOnly() throws {
        let before = fixture()
        var next = record(before) { $0.teams[0].name = "Edited team"; $0.teams[0].memberIDs.reverse() }
        let entry = try XCTUnwrap(next.recoveryEntries(kind: .team, id: "recovery-team").first)
        try next.restoreRecoveryEntry(entry.id)
        XCTAssertEqual(next.teams[0], before.teams[0])
        next = record(before) { $0.teams.removeAll() }
        let deletion = try XCTUnwrap(next.recoveryEntries(kind: .team, id: "recovery-team").first)
        next.removePokemon(id: "recovery-b")
        try next.restoreRecoveryEntry(deletion.id)
        XCTAssertEqual(next.teams[0].memberIDs, ["recovery-a"])
        next.removePokemon(id: "recovery-a")
        XCTAssertThrowsError(try next.restoreRecoveryEntry(deletion.id))
    }
    func testRecreatingMissingBoxAndLastMemberTeamDoesNotRestoreOtherDeletedPokemon() throws {
        let before = fixture()
        var next = record(before) { $0.removePokemon(id: "recovery-a"); $0.removePokemon(id: "recovery-b") }
        next.storage?.boxes = []
        try next.restoreRecoveryEntry(XCTUnwrap(next.recoveryEntries(kind: .pokemon, id: "recovery-a").first?.id))
        XCTAssertNil(next.pokemon.first { $0.id == "recovery-b" })
        XCTAssertEqual(next.teams.first { $0.id == "recovery-team" }?.memberIDs, ["recovery-a"])
        XCTAssertEqual(next.storage?.boxes.first { $0.id == "recovery-box" }?.slots[12], "recovery-a")
    }
    func testCompetitiveRecoveryAndSectionChangeKeepCollectionsSeparate() throws {
        let before = fixture()
        var deleted = record(before) { $0.removePokemon(id: "recovery-c") }
        try deleted.restoreRecoveryEntry(XCTUnwrap(deleted.recoveryEntries(kind: .pokemon, id: "recovery-c").first?.id))
        XCTAssertEqual(deleted.section(forPokemon: "recovery-c"), .showdown)
        XCTAssertFalse(deleted.storage(for: .ribbon).boxes.flatMap(\.slots).contains("recovery-c"))
        var changed = record(before) { $0.pokemon[0].showdownSet = ShowdownSet(moves: ["Protect"]) }
        try changed.restoreRecoveryEntry(XCTUnwrap(changed.recoveryEntries(kind: .pokemon, id: "recovery-a").first?.id))
        XCTAssertEqual(changed.section(forPokemon: "recovery-a"), .ribbon)
        XCTAssertFalse(changed.storage(for: .showdown).boxes.flatMap(\.slots).contains("recovery-a"))
    }
    func testHistoryPersistsAndOldCollectionsDecodeWithoutIt() throws {
        let before = fixture()
        let next = record(before) { $0.removePokemon(id: "recovery-a") }
        let encoded = try JSONEncoder().encode(next)
        var decoded = try JSONDecoder().decode(CollectionSnapshot.self, from: encoded)
        XCTAssertEqual(decoded.recoveryHistory, next.recoveryHistory)
        try decoded.restoreRecoveryEntry(XCTUnwrap(decoded.recoveryEntries(kind: .pokemon, id: "recovery-a").first?.id))
        XCTAssertEqual(decoded.pokemon.first { $0.id == "recovery-a" }, before.pokemon[0])
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any]); json.removeValue(forKey: "recoveryHistory")
        let old = try JSONDecoder().decode(CollectionSnapshot.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(old.recoveryHistory); XCTAssertEqual(old.pokemon, next.pokemon)
    }
    func testLimitsRetainNewestVersionsAndDeletion() throws {
        var snapshot = fixture()
        for n in 0..<30 { snapshot = record(snapshot) { $0.pokemon[0].nickname = "Version \(n)" } }
        XCTAssertEqual(snapshot.recoveryEntries(kind: .pokemon, id: "recovery-a").count, RecoveryEntry.versionsPerItem)
        snapshot = record(snapshot) { $0.removePokemon(id: "recovery-a") }
        XCTAssertEqual(snapshot.recoveryEntries(kind: .pokemon, id: "recovery-a").first?.action, .deleted)
        XCTAssertEqual(snapshot.recoveryEntries(kind: .pokemon, id: "recovery-a").first?.pokemon?.nickname, "Version 29")
        var before = CollectionSnapshot(pokemon: (0..<520).map { RibbonPokemon(id: "many-\($0)", species: "pikachu") })
        before.organizeSections()
        let next = record(before) { $0.pokemon.removeAll() }
        XCTAssertEqual(next.recoveryHistory?.count, RecoveryEntry.totalLimit)
    }
    func testImportReplacementIsRecoverableAndComparisonExplainsAwards() throws {
        let before = fixture()
        var next = before; next.pokemon[0].removeAward("effort-ribbon"); next.pokemon[0].nickname = "Imported"
        next.captureRecovery(from: before, action: .imported)
        let entry = try XCTUnwrap(next.recoveryHistory?.first)
        XCTAssertEqual(entry.action, .imported)
        let changes = RecoveryComparison.changes(for: entry, in: next)
        XCTAssertTrue(changes.contains { $0.contains("Restore awards") }); XCTAssertTrue(changes.contains { $0.contains("Nickname") })
        try next.restoreRecoveryEntry(entry.id)
        XCTAssertEqual(next.pokemon[0], before.pokemon[0])
    }
    @MainActor func testFailedSaveKeepsLiveCollectionAndHistoryUnchanged() throws {
        let before = fixture()
        let store = AppStore(snapshot: before, save: { _ in throw ImportError.invalid("Test save failed") })
        store.deletePokemon("recovery-a")
        XCTAssertEqual(store.snapshot.pokemon, before.pokemon); XCTAssertNil(store.snapshot.recoveryHistory)
        XCTAssertNotNil(store.error)
    }
    @MainActor func testAppStoreCommitsHistoryAndRestoreTogether() throws {
        var writes: [Data] = []
        let store = AppStore(snapshot: fixture(), save: { writes.append(try JSONEncoder().encode($0)) })
        var p = store.snapshot.pokemon[0]; p.nickname = "Edited"
        store.update(p)
        let entry = try XCTUnwrap(store.snapshot.recoveryHistory?.first)
        XCTAssertEqual(writes.count, 1)
        XCTAssertTrue(store.restoreHistory(entry.id))
        let loaded = try JSONDecoder().decode(CollectionSnapshot.self, from: XCTUnwrap(writes.last))
        XCTAssertEqual(loaded.pokemon[0].nickname, "Atlas"); XCTAssertEqual(loaded.recoveryHistory?.first?.action, .restored)
        XCTAssertFalse(store.restoreHistory("missing")); XCTAssertEqual(writes.count, 2)
    }
    @MainActor func testNativeRecoveryScreensRenderAtNarrowWidthsInBothAppearances() throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let previous = scene.windows.first { $0.isKeyWindow }
        let window = UIWindow(windowScene: scene)
        let controller = UIHostingController(rootView: AnyView(EmptyView())); window.rootViewController = controller
        defer { controller.rootView = AnyView(EmptyView()); window.isHidden = true; window.rootViewController = nil; previous?.makeKey() }
        let before = fixture()
        let saved = record(before) { $0.pokemon[0].nickname = "Changed"; $0.pokemon[0].removeAward("effort-ribbon"); $0.removePokemon(id: "recovery-b") }
        let store = AppStore(snapshot: saved, save: { _ in })
        let version = try XCTUnwrap(saved.recoveryEntries(kind: .pokemon, id: "recovery-a").first)
        let previews = FileManager.default.temporaryDirectory.appendingPathComponent("Recovery-Previews")
        try FileManager.default.createDirectory(at: previews, withIntermediateDirectories: true)
        print("Recovery preview directory: \(previews.path)")
        for width in [320.0, 390.0] {
            for dark in [false, true] {
                let screens: [(String, AnyView)] = [
                    ("history", AnyView(NavigationStack { RecoveryHistoryView() })),
                    ("versions", AnyView(NavigationStack { RecoveryItemHistoryView(kind: .pokemon, objectID: "recovery-a") })),
                    ("preview", AnyView(NavigationStack { RecoveryVersionView(entry: version) }))
                ]
                for (name, view) in screens {
                    window.frame = CGRect(x: 0, y: 0, width: width, height: 844)
                    controller.rootView = AnyView(view.environmentObject(store).environment(\.colorScheme, dark ? .dark : .light).id("\(name)-\(width)-\(dark)"))
                    window.makeKeyAndVisible(); controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
                    RunLoop.main.run(until: Date().addingTimeInterval(0.2))
                    let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in controller.view.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
                    let file = "recovery-\(name)-\(Int(width))-\(dark ? "dark" : "light")"
                    let attachment = XCTAttachment(image: image); attachment.name = file; attachment.lifetime = .keepAlways; add(attachment)
                    try image.pngData()?.write(to: previews.appendingPathComponent(file + ".png"))
                }
            }
        }
    }
}
