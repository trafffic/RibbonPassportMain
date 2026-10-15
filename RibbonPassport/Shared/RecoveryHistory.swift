import Foundation

enum RecoveryKind: String, Codable { case pokemon, team }
enum RecoverySection: String, Codable {
    case ribbon, competitive
    init(_ kind: TeamKind) { self = kind == .ribbon ? .ribbon : .competitive }
    var teamKind: TeamKind { self == .ribbon ? .ribbon : .showdown }
    var name: String { teamKind.title }
}
enum RecoveryAction: String, Codable {
    case edited, deleted, imported, restored
    var name: String {
        switch self {
        case .edited: "Before edit"
        case .deleted: "Before deletion"
        case .imported: "Before import"
        case .restored: "Before restore"
        }
    }
}
struct RecoveryLocation: Codable, Equatable {
    var boxID: String?
    var boxName: String?
    var wallpaper: WallpaperSettings?
    var slot: Int?
    var partyIndex: Int?
}
struct RecoveryMembership: Codable, Equatable {
    var team: RibbonTeam
    var section: RecoverySection
}
struct RecoveryEntry: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var recordedAt: Date = Date()
    var action: RecoveryAction
    var kind: RecoveryKind
    var objectID: String
    var section: RecoverySection
    var pokemon: RibbonPokemon?
    var team: RibbonTeam?
    var location: RecoveryLocation?
    var memberships: [RecoveryMembership] = []
    var members: [RibbonPokemon] = []
    var key: String { kind.rawValue + ":" + objectID }
    var name: String { pokemon?.displayName ?? team?.name ?? "Saved item" }
    static let versionsPerItem = 20
    static let totalLimit = 500
}

extension CollectionSnapshot {
    func recoveryEntries(kind: RecoveryKind, id: String) -> [RecoveryEntry] {
        (recoveryHistory ?? []).filter { $0.kind == kind && $0.objectID == id }
    }
    func containsRecoveryItem(_ entry: RecoveryEntry) -> Bool {
        entry.kind == .pokemon ? pokemon.contains { $0.id == entry.objectID } : teams.contains { $0.id == entry.objectID }
    }
    func matchesRecoveryVersion(_ entry: RecoveryEntry) -> Bool {
        if let saved = entry.pokemon, entry.kind == .pokemon { return pokemon.first { $0.id == entry.objectID } == saved }
        if let saved = entry.team, entry.kind == .team { return teams.first { $0.id == entry.objectID } == saved }
        return false
    }

    /// Previous record values and their context are committed atomically with the changed collection.
    /// Selection, box moves, appearance and widget changes do not produce record versions.
    mutating func captureRecovery(from before: CollectionSnapshot, action: RecoveryAction = .edited, at date: Date = Date()) {
        var entries: [RecoveryEntry] = []
        let nextPokemon = Dictionary(pokemon.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        let nextTeams = Dictionary(teams.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        let layouts: [RecoverySection: StorageLayout] = [.ribbon: before.storage(for: .ribbon), .competitive: before.storage(for: .showdown)]
        for p in before.pokemon where nextPokemon[p.id] != p {
            let section = RecoverySection(p.showdownSet == nil ? .ribbon : .showdown)
            var location = RecoveryLocation()
            if let layout = layouts[section] {
                location.partyIndex = layout.partyIDs.firstIndex(of: p.id)
                for box in layout.boxes {
                    if let slot = box.slots.firstIndex(where: { $0 == p.id }) {
                        location.boxID = box.id; location.boxName = box.name; location.wallpaper = box.wallpaper; location.slot = slot
                        break
                    }
                }
            }
            let memberships = before.teams.filter { $0.memberIDs.contains(p.id) }.map {
                RecoveryMembership(team: $0, section: RecoverySection(before.kind(of: $0)))
            }
            entries.append(RecoveryEntry(recordedAt: date, action: nextPokemon[p.id] == nil ? .deleted : action,
                                         kind: .pokemon, objectID: p.id, section: section, pokemon: p,
                                         location: location, memberships: memberships))
        }
        for team in before.teams where nextTeams[team.id] != team {
            entries.append(RecoveryEntry(recordedAt: date, action: nextTeams[team.id] == nil ? .deleted : action,
                                         kind: .team, objectID: team.id, section: RecoverySection(before.kind(of: team)),
                                         team: team, members: before.members(teamID: team.id)))
        }
        var counts: [String: Int] = [:]
        let retained = (entries + (before.recoveryHistory ?? [])).filter { entry in
            counts[entry.key, default: 0] += 1
            return counts[entry.key, default: 0] <= RecoveryEntry.versionsPerItem
        }
        recoveryHistory = retained.isEmpty ? nil : Array(retained.prefix(RecoveryEntry.totalLimit))
    }

    /// Restores only this record. Other Pokémon, occupied slots, teams and widget settings stay intact.
    mutating func restoreRecoveryEntry(_ id: String) throws {
        guard let entry = recoveryHistory?.first(where: { $0.id == id }) else { throw ImportError.invalid("This saved version is no longer available.") }
        if entry.kind == .pokemon, let saved = entry.pokemon, saved.id == entry.objectID {
            let previousSection = section(forPokemon: saved.id)
            let oldTeamKinds = Dictionary(teams.map { ($0.id, kind(of: $0)) }, uniquingKeysWith: { _, last in last })
            if let i = pokemon.firstIndex(where: { $0.id == saved.id }) { pokemon[i] = saved }
            else { pokemon.append(saved) }
            let kind: TeamKind = saved.showdownSet == nil ? .ribbon : .showdown
            if previousSection != nil && previousSection != kind {
                for i in teams.indices where oldTeamKinds[teams[i].id] != kind { teams[i].memberIDs.removeAll { $0 == saved.id } }
                teams.removeAll { $0.memberIDs.isEmpty }
            }
            if previousSection == nil || previousSection != kind { restoreLocation(entry.location, pokemonID: saved.id, kind: kind) }
            if previousSection == nil { restoreMemberships(entry.memberships, pokemonID: saved.id, kind: kind) }
            selectedID = saved.id
            if kind == .ribbon { selectedRibbonID = saved.id } else { selectedCompetitiveID = saved.id }
        } else if entry.kind == .team, var saved = entry.team, saved.id == entry.objectID {
            var seen = Set<String>()
            saved.memberIDs = Array(saved.memberIDs.filter {
                section(forPokemon: $0) == entry.section.teamKind && seen.insert($0).inserted
            }.prefix(6))
            guard !saved.memberIDs.isEmpty else { throw ImportError.invalid("Restore at least one of this team's Pokémon first.") }
            if let i = teams.firstIndex(where: { $0.id == saved.id }) { teams[i] = saved }
            else { teams.append(saved) }
            selectedTeamID = saved.id
            if entry.section == .ribbon { selectedRibbonTeamID = saved.id } else { selectedCompetitiveTeamID = saved.id }
        } else { throw ImportError.invalid("This saved version could not be restored.") }
        organizeSections()
    }

    private mutating func restoreLocation(_ location: RecoveryLocation?, pokemonID: String, kind: TeamKind) {
        var layout = storage(for: kind)
        layout.partyIDs.removeAll { $0 == pokemonID }
        for i in layout.boxes.indices {
            for slot in layout.boxes[i].slots.indices where layout.boxes[i].slots[slot] == pokemonID { layout.boxes[i].slots[slot] = nil }
        }
        if let partyIndex = location?.partyIndex, layout.partyIDs.count < 6 {
            layout.partyIDs.insert(pokemonID, at: min(max(0, partyIndex), layout.partyIDs.count))
        } else if let boxID = location?.boxID, let slot = location?.slot, (0..<30).contains(slot) {
            if !layout.boxes.contains(where: { $0.id == boxID }) {
                layout.boxes.append(PCBox(id: boxID, name: location?.boxName ?? "Recovered", wallpaper: location?.wallpaper))
            }
            if let i = layout.boxes.firstIndex(where: { $0.id == boxID }), layout.boxes[i].slots[slot] == nil { layout.boxes[i].slots[slot] = pokemonID }
            else { layout.placeInFirstSlot(pokemonID) }
        } else { layout.placeInFirstSlot(pokemonID) }
        if kind == .ribbon { storage = layout } else { competitiveStorage = layout }
    }
    private mutating func restoreMemberships(_ memberships: [RecoveryMembership], pokemonID: String, kind: TeamKind) {
        for saved in memberships where saved.section.teamKind == kind {
            if let i = teams.firstIndex(where: { $0.id == saved.team.id }) {
                guard self.kind(of: teams[i]) == kind, !teams[i].memberIDs.contains(pokemonID), teams[i].memberIDs.count < 6 else { continue }
                let index = saved.team.memberIDs.firstIndex(of: pokemonID) ?? teams[i].memberIDs.count
                teams[i].memberIDs.insert(pokemonID, at: min(index, teams[i].memberIDs.count))
            } else {
                var team = saved.team
                var seen = Set<String>()
                team.memberIDs = Array(team.memberIDs.filter { section(forPokemon: $0) == kind && seen.insert($0).inserted }.prefix(6))
                if !team.memberIDs.isEmpty { teams.append(team) }
            }
        }
    }
}
