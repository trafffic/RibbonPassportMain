import Foundation

struct SpeciesInfo: Codable {
    var name: String
    var sprite: String?
    var female: Bool?
    var natdex: Int?
    var showdown: String?
    var pokeapiID: Int?
}
struct RarityInfo: Codable { var score: Int; var tier: String; var reason: String }
struct GameInfo: Codable { var gen: Int; var group: String }
struct RibbonCatalog: Codable {
    var pokemon: [String: SpeciesInfo]
    var ribbons: [String: String]
    var games: [String: String]
    var titles: [String: String]
    var rarity: [String: RarityInfo]
    var merges: [String: String]
    var gameInfo: [String: GameInfo]
    var gmaxSpecies: [String]
    var consoleByGame: [String: String]
    var showdownAliases: [String: String]

    static let shared: RibbonCatalog = {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json", subdirectory: "RibbonAssets"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(RibbonCatalog.self, from: data) else {
            preconditionFailure("The bundled RibbonAssets/catalog.json is missing or invalid.")
        }
        return catalog
    }()
    static func normalise(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased().filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
    }
    func speciesID(_ name: String) -> String? {
        let key = Self.normalise(name)
        if let alias = showdownAliases[key] { return alias }
        if let exact = pokemon.keys.first(where: { Self.normalise($0) == key }) { return exact }
        // Only match a name when it uniquely identifies a species; forms often share names.
        let matches = pokemon.filter { Self.normalise($0.value.name) == key }.map(\.key)
        return matches.count == 1 ? matches.first : nil
    }
    func gameName(_ id: String) -> String { games[id] ?? (id.isEmpty ? "Game not set" : id) }
    func compactGameName(_ id: String) -> String {
        gameName(id).replacingOccurrences(of: #"\s*\([^)]*\)"#, with: "", options: .regularExpression)
    }
    func awards(for p: RibbonPokemon) -> [String] {
        let original = Array(Set(p.ribbons)).sorted()
        guard (gameInfo[p.currentgame]?.gen ?? 0) >= 6 else { return original }
        var awards = Set(original)
        for group in ["contest", "battle"] {
            let legacy = original.filter { merges[$0] == group }
            let regular = "\(group)-memory-ribbon", gold = "\(regular)-gold"
            guard !legacy.isEmpty || awards.contains(regular) || awards.contains(gold) else { continue }
            let threshold = group == "contest" ? 40 :
                ((gameInfo[p.currentgame]?.gen ?? 0) >= 9 || ["scar", "vio", "home", "homeza"].contains(p.currentgame) ? 7 : 8)
            let isGold = awards.contains(gold) || legacy.count >= threshold
            awards.subtract(legacy); awards.remove(regular); awards.remove(gold)
            awards.insert(isGold ? gold : regular)
        }
        return awards.sorted()
    }
    func ranked(_ ids: [String], ribbonsOnly: Bool = false) -> [String] {
        Set(ids).filter { !ribbonsOnly || !$0.hasSuffix("-mark") }.sorted {
            let a = rarity[$0]?.score ?? 0, b = rarity[$1]?.score ?? 0
            if a != b { return a > b }
            let an = ribbons[$0] ?? $0, bn = ribbons[$1] ?? $1
            return an == bn ? $0 < $1 : an < bn
        }
    }
    func equippedID(for p: RibbonPokemon) -> String {
        guard p.title != "None", !p.title.isEmpty else { return "" }
        guard (gameInfo[p.currentgame]?.gen ?? 0) >= 6, let group = merges[p.title] else { return p.title }
        let base = "\(group)-memory-ribbon"
        return awards(for: p).contains(base + "-gold") ? base + "-gold" : base
    }
    func titleText(for p: RibbonPokemon) -> String {
        let id = equippedID(for: p)
        guard !id.isEmpty else { return "No title equipped" }
        let wording = id == p.title && !p.titleText.isEmpty ? p.titleText : (titles[id] ?? "")
        return wording.isEmpty ? (ribbons[id] ?? id) : wording
    }
}

struct ShowdownSet: Codable, Equatable {
    var item: String = ""
    var ability: String = ""
    var nature: String = ""
    var evs: String = ""
    var ivs: String = ""
    var teraType: String = ""
    var moves: [String] = []
}
struct RibbonPokemon: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var species: String
    var nickname: String = ""
    var gender: String = ""
    var shiny: Bool = false
    var currentgame: String = ""
    var origingame: String = ""
    var shadow: Bool = false
    var gmax: Bool = false
    var currentlevel: Int = 100
    var title: String = "None"
    var titleText: String = ""
    var ribbons: [String] = []
    var source: String = "manual"
    var showdownSet: ShowdownSet? = nil
    var visits: [JourneyVisit]? = nil
    var earnedGenerations: [String: Int]? = nil

    var displayName: String { nickname.isEmpty ? (RibbonCatalog.shared.pokemon[species]?.name ?? species) : nickname }
    var spritePath: String {
        if species == "lugia-shadow" || (species == "lugia" && (shadow || ["xd", "xd-nso"].contains(origingame) || ["xd", "xd-nso"].contains(currentgame))) {
            return "regular/lugia-shadow.png"
        }
        let catalog = RibbonCatalog.shared
        let info = catalog.pokemon[species]
        let gigantamax = gmax && catalog.gmaxSpecies.contains(species)
        var slug = gigantamax ? species + "-gmax" : (info?.sprite ?? species)
        if shiny && slug.hasPrefix("alcremie-") {
            slug = slug.replacingOccurrences(of: #"caramel|lemon|matcha|mint|rainbow|rubycream|rubyswirl|salted|vanilla"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: "--", with: "-").replacingOccurrences(of: "-strawberry", with: "")
        }
        let female = !gigantamax && gender == "female" && (info?.female ?? false)
        return "\(shiny ? "shiny" : "regular")/\(female ? "female/" : "")\(slug).png"
    }
}
struct RibbonTeam: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var memberIDs: [String]
}
enum TeamKind: Equatable { case ribbon, showdown }
enum Appearance: String, Codable, CaseIterable { case automatic, light, dark }
struct CollectionSnapshot: Codable {
    var pokemon: [RibbonPokemon] = []
    var teams: [RibbonTeam] = []
    var selectedID: String = ""
    var selectedTeamID: String = ""
    var appearance: Appearance = .automatic
    var updatedAt: Date = Date()
    var storage: StorageLayout? = nil
    var competitiveStorage: StorageLayout? = nil
    var selectedRibbonID: String? = nil
    var selectedCompetitiveID: String? = nil
    var selectedRibbonTeamID: String? = nil
    var selectedCompetitiveTeamID: String? = nil
    var widgetPresets: [WidgetPreset]? = nil
    var widgetDefaults: [String: String]? = nil
    func members(teamID: String? = nil) -> [RibbonPokemon] {
        let id = teamID ?? selectedTeamID
        guard let team = teams.first(where: { $0.id == id }) else { return Array(pokemon.prefix(6)) }
        let kind = kind(of: team)
        return team.memberIDs.compactMap { id in pokemon.first { $0.id == id } }.filter { ($0.showdownSet != nil) == (kind == .showdown) }
    }
    func kind(of team: RibbonTeam) -> TeamKind {
        let members = team.memberIDs.compactMap { id in pokemon.first { $0.id == id } }
        return !members.isEmpty && members.allSatisfy { $0.showdownSet != nil } ? .showdown : .ribbon
    }
    func teams(for kind: TeamKind) -> [RibbonTeam] { teams.filter { self.kind(of: $0) == kind } }
    func widgetTeam(for kind: TeamKind, id: String? = nil) -> RibbonTeam? {
        let eligible = teams(for: kind)
        if let id { return eligible.first { $0.id == id } }
        let selected = kind == .ribbon ? selectedRibbonTeamID : selectedCompetitiveTeamID
        return eligible.first { $0.id == selected } ?? eligible.first { $0.id == selectedTeamID } ?? eligible.first
    }
    mutating func removePokemon(id: String) {
        pokemon.removeAll { $0.id == id }
        for index in teams.indices { teams[index].memberIDs.removeAll { $0 == id } }
        teams.removeAll { $0.memberIDs.isEmpty }
        if !pokemon.contains(where: { $0.id == selectedID }) { selectedID = pokemon.first?.id ?? "" }
        if !teams.contains(where: { $0.id == selectedTeamID }) { selectedTeamID = teams.first?.id ?? "" }
    }
    mutating func replaceDemo(with records: [RibbonPokemon]) {
        let old = pokemon.filter { $0.source == "demo" }
        let oldIDs = Set(old.map(\.id))
        let demoTeams = Set(teams.filter { $0.name == "Demo Ribbon Team" && !$0.memberIDs.isEmpty && Set($0.memberIDs).isSubset(of: oldIDs) }.map(\.id))
        var used = Set<String>()
        let refreshed = records.map { record -> RibbonPokemon in
            var p = record; p.source = "demo"
            if let prior = old.first(where: { $0.species == p.species && !used.contains($0.id) }) { p.id = prior.id }
            else { p.id = UUID().uuidString }
            used.insert(p.id); return p
        }
        pokemon.removeAll { $0.source == "demo" }; pokemon.append(contentsOf: refreshed)
        let valid = Set(pokemon.map(\.id))
        for index in teams.indices { teams[index].memberIDs.removeAll { !valid.contains($0) } }
        let team = RibbonTeam(id: teams.first(where: { demoTeams.contains($0.id) })?.id ?? UUID().uuidString,
                              name: "Demo Ribbon Team", memberIDs: refreshed.map(\.id))
        teams.removeAll { demoTeams.contains($0.id) || $0.memberIDs.isEmpty }; teams.append(team)
        selectedID = refreshed.first?.id ?? ""; selectedTeamID = team.id
    }
}
enum ImportError: LocalizedError {
    case invalid(String)
    var errorDescription: String? { switch self { case .invalid(let reason): return reason } }
}
enum BackupImporter {
    static func parse(_ data: Data, catalog: RibbonCatalog = .shared) throws -> [RibbonPokemon] {
        var input = data
        if input.starts(with: [0xEF, 0xBB, 0xBF]) { input.removeFirst(3) }
        guard let root = try JSONSerialization.jsonObject(with: input) as? [String: Any],
              root["fileVersion"] as? Int == 5, let entries = root["pokemon"] as? [[String: Any]] else {
            throw ImportError.invalid("Choose RibbonBackup.json exported by ribbons.guide (fileVersion 5).")
        }
        return try entries.enumerated().map { index, entry in
            guard let species = entry["species"] as? String, validID(species),
                  let ribbons = entry["ribbons"] as? [String], ribbons.allSatisfy(validID) else {
                throw ImportError.invalid("Pokémon \(index + 1) has an unsupported species or award format.")
            }
            let shinyString = String(describing: entry["shiny"] ?? "").lowercased()
            let shiny = ["star", "square", "shiny", "true", "1"].contains(shinyString)
            let title = entry["title"] as? String ?? "None"
            let safeTitle = validID(title) ? title : "None"
            let level = Int(String(describing: entry["currentlevel"] ?? 100)) ?? 100
            let trainer = entry["trainername"] as? String ?? "Original Trainer"
            return RibbonPokemon(id: "backup-\(index)", species: species,
                nickname: entry["nickname"] as? String ?? "", gender: entry["gender"] as? String ?? "",
                shiny: shiny, currentgame: entry["currentgame"] as? String ?? "",
                origingame: entry["origingame"] as? String ?? "", shadow: entry["shadow"] as? Bool ?? false,
                gmax: entry["gmax"] as? Bool ?? false, currentlevel: max(1, min(100, level)),
                title: safeTitle, titleText: (catalog.titles[safeTitle] ?? "").replacingOccurrences(of: "[Original Trainer]", with: trainer),
                ribbons: Array(Set(ribbons)).sorted(), source: "ribbons.guide")
        }
    }
    private static func validID(_ value: String) -> Bool {
        !value.isEmpty && value.range(of: #"^[a-z0-9-]+$"#, options: .regularExpression) != nil
    }
}
enum ShowdownImporter {
    static func parse(_ text: String, catalog: RibbonCatalog = .shared) throws -> [RibbonPokemon] {
        let input = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let lines = input.components(separatedBy: "\n")
        if lines.filter({ $0.trimmingCharacters(in: .whitespaces).hasPrefix("===") }).count > 1 {
            throw ImportError.invalid("Paste a single Showdown team, rather than a backup containing several teams.")
        }
        var blocks: [[String]] = [], current: [String] = []
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.hasPrefix("===") { continue }
            if line.isEmpty { if !current.isEmpty { blocks.append(current); current = [] } }
            else { current.append(line) }
        }
        if !current.isEmpty { blocks.append(current) }
        guard !blocks.isEmpty, blocks.count <= 6 else {
            throw ImportError.invalid("Paste one Showdown team containing one to six Pokémon. Use Teambuilder → Import/Export, not a replay URL or packed team.")
        }
        return try blocks.enumerated().map { position, block in
            var header = block[0].components(separatedBy: " @ ")[0]
            var gender = ""
            if header.hasSuffix(" (M)") { gender = "male"; header = String(header.dropLast(4)) }
            if header.hasSuffix(" (F)") { gender = "female"; header = String(header.dropLast(4)) }
            var speciesName = header, nickname = ""
            if header.hasSuffix(")"), let start = header.range(of: " (", options: .backwards) {
                nickname = String(header[..<start.lowerBound])
                speciesName = String(header[start.upperBound...].dropLast())
            }
            guard let species = catalog.speciesID(speciesName) else {
                throw ImportError.invalid("Cannot recognise Pokémon \(position + 1): \(speciesName). Check its Showdown export name. Custom/CAP species are not supported.")
            }
            if speciesName == "Meowstic-F" || speciesName == "Indeedee-F" { gender = "female" }
            var pokemon = RibbonPokemon(species: species, nickname: nickname, gender: gender, source: "showdown")
            var build = ShowdownSet()
            build.item = block[0].components(separatedBy: " @ ").dropFirst().joined(separator: " @ ")
            for line in block.dropFirst() {
                if line.hasPrefix("Ability: ") { build.ability = String(line.dropFirst(9)) }
                if line.hasPrefix("EVs: ") { build.evs = String(line.dropFirst(5)) }
                if line.hasPrefix("IVs: ") { build.ivs = String(line.dropFirst(5)) }
                if line.hasPrefix("Tera Type: ") { build.teraType = String(line.dropFirst(11)) }
                if line.hasSuffix(" Nature") { build.nature = String(line.dropLast(7)) }
                if line.hasPrefix("- ") { build.moves.append(String(line.dropFirst(2))) }
                if line.lowercased() == "shiny: yes" { pokemon.shiny = true }
                if line.lowercased().hasPrefix("level:") {
                    let value = line.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                    guard let level = Int(value), (1...100).contains(level) else { throw ImportError.invalid("Invalid level for \(speciesName).") }
                    pokemon.currentlevel = level
                }
                if line.lowercased() == "gigantamax: yes" { pokemon.gmax = true }
            }
            pokemon.showdownSet = build
            return pokemon
        }
    }
}
