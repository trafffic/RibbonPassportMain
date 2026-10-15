import Foundation

struct RibbonRule: Decodable {
    var gen: Int
    var games: [String]
    var description: String
    var banned: [String]
    var bannedBDSP: [String]
    var nomythical: Bool
    var mark: Bool
    var memory: Bool
}
struct RibbonSpeciesRule: Decodable {
    var games: [String]
    var mythical: Bool
    var legendary: Bool
    var flags: [String]
    var voiceless: Bool
    var base: String
}
struct RibbonGameRule: Decodable {
    var gen: Int
    var group: String
    var service: Bool
}

struct RibbonTransferCheck {
    var generation: Int?
    var nextGeneration: Int?
    var lastChance: [String] = []
    var canWait: [String] = []
    var warnings: [String] = []
    var canAssess = false
    var isSafe: Bool { canAssess && nextGeneration != nil && lastChance.isEmpty && warnings.isEmpty }
    var title: String {
        guard canAssess, let generation else { return "Choose a game to check transfer" }
        guard nextGeneration != nil else { return "No compatible later generation" }
        if !lastChance.isEmpty { return "Not safe to leave Gen \(generation.roman)" }
        return warnings.isEmpty ? "Safe to leave Gen \(generation.roman)" : "Check before leaving Gen \(generation.roman)"
    }
    var summary: String {
        guard canAssess else { return "Set a compatible current game first" }
        guard nextGeneration != nil else { return "This Pokémon cannot move up yet" }
        if !lastChance.isEmpty { return "\(lastChance.count) last-chance \(lastChance.count == 1 ? "ribbon remains" : "ribbons remain")" }
        return warnings.isEmpty ? "No last-chance ribbons left" : "Footprint eligibility needs checking"
    }
}

/// Offline snapshot of ribbons.guide's availability and directed transfer graph.
struct RibbonRules: Decodable {
    var species: [String: RibbonSpeciesRule]
    var awards: [String: RibbonRule]
    var games: [String: RibbonGameRule]
    var travel: [String: [String]]

    static let shared: RibbonRules = {
        guard let url = Bundle.main.url(forResource: "ribbon-rules", withExtension: "json", subdirectory: "RibbonAssets"),
              let data = try? Data(contentsOf: url), let rules = try? JSONDecoder().decode(Self.self, from: data) else {
            preconditionFailure("Missing ribbon eligibility catalogue")
        }
        return rules
    }()
    var ribbonIDs: [String] { RibbonCatalog.shared.chronologicalAwards(awards.keys.filter { awards[$0]?.mark == false }) }
    func category(for pokemon: RibbonPokemon) -> String? {
        guard let info = species[pokemon.species] else { return nil }
        return info.mythical ? "MYTHICAL" : info.legendary ? "LEGENDARY" : nil
    }
    func group(for game: String) -> String? { games[game]?.group ?? RibbonCatalog.shared.gameInfo[game]?.group }
    func reachableGroups(from game: String) -> Set<String> {
        guard let start = group(for: game) else { return [] }
        var seen: Set<String> = [start], queue = [start]
        while !queue.isEmpty {
            for next in travel[queue.removeFirst()] ?? [] where seen.insert(next).inserted { queue.append(next) }
        }
        return seen
    }
    func compatibleGames(for p: RibbonPokemon, reachableOnly: Bool = true) -> [String] {
        guard let info = species[p.species] else { return [] }
        let current = p.currentgame.isEmpty ? p.origingame : p.currentgame
        let groups = reachableGroups(from: current)
        return games.keys.filter { id in
            guard let game = games[id], !game.service, info.games.contains(id) else { return false }
            if reachableOnly && !current.isEmpty && !groups.contains(game.group) { return false }
            if p.ball == "go-safari" && id != "go" { return false }
            if p.gmax && ["pikachu", "eevee", "meowth", "duraludon"].contains(info.base) && !["sw", "sh"].contains(id) { return false }
            let bdsp = ["bd", "sp"]
            if info.base == "spinda" {
                let locked = bdsp.contains(current) || bdsp.contains(p.origingame)
                if locked != bdsp.contains(id) { return false }
            }
            if info.base == "nincada" {
                if bdsp.contains(p.origingame) && !["sw", "sh"].contains(current) && ["sw", "sh"].contains(id) { return false }
                if !bdsp.contains(current) && !bdsp.contains(p.origingame) && bdsp.contains(id) { return false }
            }
            return true
        }.sorted { CatalogOrder.gameIndex($0) < CatalogOrder.gameIndex($1) }
    }
    func unavailableReason(_ award: String, game: String, pokemon p: RibbonPokemon, historical: Bool = false, checkCompatibility: Bool = true) -> String? {
        guard let rule = awards[award], let info = species[p.species] else { return "Choose a Pokémon" }
        if rule.memory { return "Combined automatically from original ribbons" }
        if rule.games.isEmpty { return "Event distribution only" }
        guard rule.games.contains(game) else { return "Not awarded in this game" }
        if checkCompatibility && !compatibleGames(for: p, reachableOnly: !historical).contains(game) { return "This Pokémon cannot reach this game" }
        if rule.nomythical && info.mythical { return "Mythical Pokémon cannot enter this challenge" }
        if rule.banned.contains(info.base) { return "This Pokémon cannot enter this challenge" }
        if award == "tower-master-ribbon", ["bd", "sp"].contains(game), info.mythical || rule.bannedBDSP.contains(info.base) {
            return "This Pokémon cannot enter the BDSP Battle Tower"
        }
        if award == "battle-tree-great-ribbon", ["sun", "moon"].contains(game),
           info.mythical || (awards["battle-tree-master-ribbon"]?.banned.contains(info.base) ?? false) {
            return "This Pokémon needs Ultra Sun or Ultra Moon"
        }
        if award == "national-ribbon" {
            let origin = p.origingame.isEmpty ? p.currentgame : p.origingame
            let shadow = origin == "colosseum" ? info.flags.contains("colShadow") : ["xd", "xd-nso"].contains(origin) && info.flags.contains("xdShadow")
            if !p.shadow || !shadow { return "Requires a Shadow Pokémon from Colosseum or XD" }
        }
        if !historical {
            if award == "winning-ribbon", p.currentlevel > 50 { return "Requires level 50 or below" }
            if award == "gorgeous-ribbon", ["bd", "sp"].contains(game), p.ribbons.contains("royal-ribbon") || p.ribbons.contains("gorgeous-royal-ribbon") { return "The earlier purchase is no longer available" }
            if award == "royal-ribbon", ["bd", "sp"].contains(game), p.ribbons.contains("gorgeous-royal-ribbon") { return "The earlier purchase is no longer available" }
            if award == "footprint-ribbon", !["diamond", "pearl", "platinum"].contains(game), !(info.voiceless && ["bd", "sp"].contains(game)) {
                let current = p.currentgame.isEmpty ? p.origingame : p.currentgame
                let resetsMetLevel = ["3", "4", "3DSVC"].contains(group(for: current) ?? "")
                // Earlier games replace the met level on transfer; the old value cannot block a later ribbon.
                if resetsMetLevel {
                    if p.currentlevel > 70 { return "Transfer resets the met level above 70" }
                } else if p.origingame != "go", let level = p.metLevel {
                    if level > 70 { return "Requires gaining 30 levels after being met" }
                } else if p.origingame != "go", p.currentlevel > 70 { return "Set the met level to check the 30-level requirement" }
            }
        }
        return nil
    }
    func earningGames(for award: String, pokemon p: RibbonPokemon) -> [String] {
        guard !p.ribbons.contains(award) else { return [] }
        return compatibleGames(for: p).filter { unavailableReason(award, game: $0, pokemon: p, checkCompatibility: false) == nil }
    }
    func laterGames(for award: String, after game: String, pokemon p: RibbonPokemon) -> [String] {
        let generation = games[game]?.gen ?? RibbonCatalog.shared.gameInfo[game]?.gen ?? 0
        // The route must be reachable from the selected game as well as the Pokémon's current game.
        let groups = reachableGroups(from: game)
        return compatibleGames(for: p).filter {
            (games[$0]?.gen ?? 0) > generation && groups.contains(games[$0]?.group ?? "") && unavailableReason(award, game: $0, pokemon: p, checkCompatibility: false) == nil
        }
    }
    func isLastChance(_ award: String, game: String, pokemon p: RibbonPokemon) -> Bool {
        !p.ribbons.contains(award) && unavailableReason(award, game: game, pokemon: p) == nil && laterGames(for: award, after: game, pokemon: p).isEmpty
    }

    func generationEarningGames(for award: String, from game: String, pokemon p: RibbonPokemon) -> [String] {
        let generation = games[game]?.gen
        let groups = reachableGroups(from: game)
        return compatibleGames(for: p).filter {
            games[$0]?.gen == generation && groups.contains(games[$0]?.group ?? "") &&
            unavailableReason(award, game: $0, pokemon: p, checkCompatibility: false) == nil
        }
    }

    /// Checks the whole departure generation, independently of grid filters and pagination.
    func transferCheck(from game: String, pokemon p: RibbonPokemon) -> RibbonTransferCheck {
        guard let generation = games[game]?.gen, species[p.species] != nil,
              compatibleGames(for: p).contains(game) else { return RibbonTransferCheck() }
        let groups = reachableGroups(from: game)
        let later = compatibleGames(for: p).filter {
            (games[$0]?.gen ?? 0) > generation && groups.contains(games[$0]?.group ?? "")
        }
        var check = RibbonTransferCheck(generation: generation, nextGeneration: later.compactMap { games[$0]?.gen }.min(), canAssess: true)
        for award in ribbonIDs where !p.ribbons.contains(award) {
            guard !generationEarningGames(for: award, from: game, pokemon: p).isEmpty else { continue }
            if laterGames(for: award, after: game, pokemon: p).isEmpty { check.lastChance.append(award) }
            else { check.canWait.append(award) }
        }
        let current = p.currentgame.isEmpty ? p.origingame : p.currentgame
        if !p.ribbons.contains("footprint-ribbon"), p.metLevel == nil, p.currentlevel > 70, p.origingame != "go",
           !["3", "4", "3DSVC"].contains(group(for: current) ?? ""),
           compatibleGames(for: p).contains(where: {
               games[$0]?.gen == generation && groups.contains(games[$0]?.group ?? "") &&
               unavailableReason("footprint-ribbon", game: $0, pokemon: p, checkCompatibility: false) == "Set the met level to check the 30-level requirement"
           }) {
            check.warnings.append("Set Met level in Edit Pokémon to check whether Footprint can still be earned.")
        }
        return check
    }

    func footprintTransferWarning(from game: String, pokemon p: RibbonPokemon) -> String? {
        guard !p.ribbons.contains("footprint-ribbon"),
              !generationEarningGames(for: "footprint-ribbon", from: game, pokemon: p).isEmpty,
              laterGames(for: "footprint-ribbon", after: game, pokemon: p).isEmpty,
              ["3", "4"].contains(group(for: p.currentgame.isEmpty ? p.origingame : p.currentgame) ?? ""),
              p.currentlevel > 70 else { return nil }
        return "Last chance · Met level resets to \(p.currentlevel) in Gen V. The later 30-level requirement cannot be met."
    }
}

enum RibbonPageSize {
    static let options = [6, 12, 24]
    static func validated(_ value: Int) -> Int { value == 32 ? 24 : options.contains(value) ? value : 12 }
    static func next(_ value: Int) -> Int { options[((options.firstIndex(of: validated(value)) ?? 0) + 1) % options.count] }
}

extension RibbonPokemon {
    /// Original records remain editable and retain their individual earning locations.
    var ownedRibbonIDs: [String] { RibbonCatalog.shared.chronologicalAwards(ribbons.filter { RibbonRules.shared.awards[$0]?.mark == false }) }
    /// The current game's visible ribbons, including automatic Gen VI+ Memory consolidation.
    var displayedRibbonIDs: [String] {
        let catalog = RibbonCatalog.shared
        return catalog.chronologicalAwards(catalog.awards(for: self).filter { RibbonRules.shared.awards[$0]?.mark == false })
    }
    func originalRibbonIDs(representedBy memory: String) -> [String] {
        guard let group = ["contest", "battle"].first(where: { memory == "\($0)-memory-ribbon" || memory == "\($0)-memory-ribbon-gold" }) else { return [] }
        return ownedRibbonIDs.filter { RibbonCatalog.shared.merges[$0] == group }
    }
    func awards(earnedInGame game: String) -> [String] { RibbonCatalog.shared.chronologicalAwards(ribbons.filter { earnedGames?[$0] == game }) }
    func earningLocation(_ award: String) -> String {
        if let game = earnedGames?[award] { return RibbonCatalog.shared.gameName(game) }
        if let gen = earnedGenerations?[award] { return "Gen \(gen.roman) · Game not set" }
        return "Game not set"
    }
    @discardableResult mutating func recordRibbon(_ award: String, game: String) -> Bool {
        guard !ribbons.contains(award), RibbonRules.shared.awards[award]?.mark == false,
              RibbonRules.shared.unavailableReason(award, game: game, pokemon: self) == nil else { return false }
        ribbons.append(award)
        assignAward(award, game: game)
        return true
    }
    mutating func assignAward(_ award: String, game: String) {
        guard ribbons.contains(award), RibbonRules.shared.games[game]?.service == false,
              RibbonRules.shared.unavailableReason(award, game: game, pokemon: self, historical: true) == nil else { return }
        if earnedGames == nil { earnedGames = [:] }
        if earnedGenerations == nil { earnedGenerations = [:] }
        earnedGames?[award] = game
        earnedGenerations?[award] = RibbonRules.shared.games[game]?.gen
        var all = recordedVisits
        if !all.contains(where: { $0.game == game }) { all.append(JourneyVisit(game: game)) }
        visits = all
    }
    mutating func removeAward(_ award: String) {
        ribbons.removeAll { $0 == award }; earnedGames?[award] = nil; earnedGenerations?[award] = nil
        if title == award { title = "None"; titleText = "" }
    }
}
