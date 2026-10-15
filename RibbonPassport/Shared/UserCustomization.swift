import Foundation

struct JourneyVisit: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var game: String
    var generation: Int { RibbonCatalog.shared.gameInfo[game]?.gen ?? 0 }
}

extension RibbonPokemon {
    /// Only recorded visits and known endpoints appear; transfers are never guessed.
    var recordedVisits: [JourneyVisit] {
        var seen = Set<String>()
        var result = (visits ?? []).filter { !$0.game.isEmpty && seen.insert($0.game).inserted }
        for game in [origingame, currentgame] where !game.isEmpty {
            if !result.contains(where: { $0.game == game }) { result.append(JourneyVisit(id: "endpoint-" + game, game: game)) }
        }
        return result.sorted { CatalogOrder.gameIndex($0.game) < CatalogOrder.gameIndex($1.game) }
    }
    func games(in generation: Int) -> [String] { recordedVisits.filter { $0.generation == generation }.map(\.game) }
    var visitedGenerations: [Int] { Array(Set(recordedVisits.map(\.generation).filter { $0 > 0 })).sorted() }
    func awards(earnedIn generation: Int) -> [String] {
        RibbonCatalog.shared.ranked(ribbons.filter { earnedGenerations?[$0] == generation })
    }
    mutating func assignAward(_ award: String, generation: Int?) {
        guard ribbons.contains(award) else { return }
        if earnedGenerations == nil { earnedGenerations = [:] }
        earnedGenerations?[award] = generation
    }
}

struct PCBox: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var name: String = "Box 01"
    var slots: [String?] = Array(repeating: nil, count: 30)
    var wallpaper: WallpaperSettings? = nil
}
struct StorageLayout: Codable, Equatable {
    var boxes: [PCBox] = [PCBox()]
    var partyIDs: [String] = []

    func wallpaper(for box: PCBox) -> WallpaperSettings {
        var settings = box.wallpaper ?? WallpaperSettings()
        if settings.sunMoon == nil { settings.sunMoon = SunMoonWallpaper.allCases[(boxes.firstIndex { $0.id == box.id } ?? 0) % SunMoonWallpaper.allCases.count] }
        return settings
    }

    mutating func reconcile(pokemonIDs: [String]) {
        let valid = Set(pokemonIDs)
        var seen = Set<String>()
        partyIDs = Array(partyIDs.filter { valid.contains($0) && seen.insert($0).inserted }.prefix(6))
        seen = Set(partyIDs)
        if boxes.isEmpty { boxes = [PCBox()] }
        for i in boxes.indices {
            boxes[i].slots = Array(boxes[i].slots.prefix(30))
            boxes[i].slots += Array(repeating: nil, count: 30 - boxes[i].slots.count)
            for j in boxes[i].slots.indices {
                if let id = boxes[i].slots[j], !valid.contains(id) || !seen.insert(id).inserted { boxes[i].slots[j] = nil }
            }
        }
        for id in pokemonIDs where seen.insert(id).inserted { placeInFirstSlot(id) }
    }
    mutating func placeInFirstSlot(_ id: String) {
        for i in boxes.indices {
            if let slot = boxes[i].slots.firstIndex(where: { $0 == nil }) { boxes[i].slots[slot] = id; return }
        }
        var box = PCBox(name: String(format: "Box %02d", boxes.count + 1)); box.slots[0] = id; boxes.append(box)
    }
    @discardableResult mutating func move(_ id: String, toBox boxID: String, slot: Int) -> Bool {
        guard let target = boxes.firstIndex(where: { $0.id == boxID }), (0..<30).contains(slot) else { return false }
        let oldParty = partyIDs.firstIndex(of: id)
        var source: (Int, Int)?
        for b in boxes.indices { if let s = boxes[b].slots.firstIndex(of: id) { source = (b, s); break } }
        guard source != nil || oldParty != nil else { return false }
        let displaced = boxes[target].slots[slot]
        if displaced == id { return true }
        if let (b, s) = source { boxes[b].slots[s] = displaced }
        if let p = oldParty {
            if let displaced { partyIDs[p] = displaced } else { partyIDs.remove(at: p) }
        }
        boxes[target].slots[slot] = id; return true
    }
    @discardableResult mutating func moveToParty(_ id: String) -> Bool {
        if partyIDs.contains(id) { return true }
        guard partyIDs.count < 6, boxes.contains(where: { $0.slots.contains(id) }) else { return false }
        for b in boxes.indices { for s in boxes[b].slots.indices where boxes[b].slots[s] == id { boxes[b].slots[s] = nil } }
        partyIDs.append(id); return true
    }
    mutating func returnToBox(_ id: String) {
        guard partyIDs.contains(id) else { return }
        partyIDs.removeAll { $0 == id }; placeInFirstSlot(id)
    }
}

enum WidgetContent: String, Codable, CaseIterable, Identifiable {
    case pokemon, ribbonTeam, showdownTeam
    var id: String { rawValue }
    var name: String { switch self { case .pokemon: "Pokémon Passport"; case .ribbonTeam: "Ribbon Team"; case .showdownTeam: "Showdown Team" } }
}
enum WidgetPalette: String, Codable, CaseIterable, Identifiable {
    case sage, ocean, parchment, graphite, game
    var id: String { rawValue }
    var name: String { rawValue.capitalized }
}
enum WidgetTypeface: String, Codable, CaseIterable, Identifiable {
    case pixel, system
    var id: String { rawValue }
    var name: String { rawValue.capitalized }
}
enum AwardOrdering: String, Codable, CaseIterable, Identifiable {
    case chronological, rarity, name
    var id: String { rawValue }
    var name: String { rawValue.capitalized }
}
struct WidgetStyle: Codable, Equatable {
    var wallpaper: WallpaperSettings? = nil
    var appearance: Appearance = .automatic
    var palette: WidgetPalette = .sage
    var typeface: WidgetTypeface = .pixel
    var textScale: Double = 1
    var showTitle = true
    var showShiny = true
    var showLevel = true
    var showGame = true
    var showConsole = true
    var showAwards = true
    var showJourney = true
    var showItem = true
    var showAbility = true
    var showNature = true
    var showTera = true
    var showMoves = true
    var awardOrdering: AwardOrdering = .rarity
    func orderedAwards(_ pokemon: RibbonPokemon, ribbonsOnly: Bool = false) -> [String] {
        let catalog = RibbonCatalog.shared
        let awards = catalog.awards(for: pokemon).filter { !ribbonsOnly || !$0.hasSuffix("-mark") }
        if awardOrdering == .chronological { return catalog.chronologicalAwards(awards) }
        return awardOrdering == .rarity ? catalog.ranked(awards) : awards.sorted { (catalog.ribbons[$0] ?? $0) < (catalog.ribbons[$1] ?? $1) }
    }
}
struct WidgetPreset: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var content: WidgetContent
    var selectionID: String = ""
    var style = WidgetStyle()
}
extension CollectionSnapshot {
    func preset(for content: WidgetContent, id: String? = nil) -> WidgetPreset? {
        if let id { return availableWidgetPresets.first { $0.id == id && $0.content == content } }
        let target = widgetDefaults?[content.rawValue]
        if let target, let chosen = availableWidgetPresets.first(where: { $0.id == target && $0.content == content }) { return chosen }
        return WidgetThemePack.defaultPack(for: content).preset(for: content)
    }
    var availableWidgetPresets: [WidgetPreset] {
        let saved = widgetPresets ?? []
        let ids = Set(saved.map(\.id))
        return saved + WidgetContent.allCases.flatMap { content in WidgetThemePack.allCases.map { $0.preset(for: content) }.filter { !ids.contains($0.id) } }
    }
    var organizedStorage: StorageLayout {
        storage(for: .ribbon)
    }
}

enum ShowdownExporter {
    private static func exportLine(_ text: String) -> String {
        text.components(separatedBy: .newlines).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    static func validatedExport(_ records: [RibbonPokemon]) throws -> String {
        guard (1...6).contains(records.count) else { throw ImportError.invalid("Showdown exports contain one to six Pokémon. Export an individual Pokémon or a team.") }
        var clean = records
        let natures = "Hardy Lonely Brave Adamant Naughty Bold Docile Relaxed Impish Lax Timid Hasty Serious Jolly Naive Modest Mild Quiet Bashful Rash Calm Gentle Sassy Careful Quirky".split(separator: " ").map(String.init)
        let types = "Normal Fire Water Electric Grass Ice Fighting Poison Ground Flying Psychic Bug Rock Ghost Dragon Dark Steel Fairy Stellar".split(separator: " ").map(String.init)
        for i in clean.indices {
            guard RibbonCatalog.shared.pokemon[clean[i].species] != nil, (1...100).contains(clean[i].currentlevel) else { throw ImportError.invalid("Check the species and level before exporting.") }
            guard var build = clean[i].showdownSet else { continue }
            guard build.moves.count <= 4 else { throw ImportError.invalid("\(clean[i].displayName) has more than four moves.") }
            build.evs = try canonicalStats(build.evs, ivs: false)
            build.ivs = try canonicalStats(build.ivs, ivs: true)
            if !build.nature.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                guard let nature = natures.first(where: { RibbonCatalog.normalise($0) == RibbonCatalog.normalise(build.nature).replacingOccurrences(of: "nature", with: "") }) else { throw ImportError.invalid("Check the nature for \(clean[i].displayName).") }
                build.nature = nature
            }
            if !build.teraType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                guard let type = types.first(where: { RibbonCatalog.normalise($0) == RibbonCatalog.normalise(build.teraType) }) else { throw ImportError.invalid("Check the Tera type for \(clean[i].displayName).") }
                build.teraType = type
            }
            build.moves = build.moves.map(exportLine).filter { !$0.isEmpty }
            clean[i].showdownSet = build
        }
        return export(clean)
    }
    private static func canonicalStats(_ text: String, ivs: Bool) throws -> String {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "" }
        let labels = ["HP", "Atk", "Def", "SpA", "SpD", "Spe"]
        let aliases = ["hp": "HP", "atk": "Atk", "attack": "Atk", "def": "Def", "defense": "Def", "spa": "SpA", "spatk": "SpA", "specialattack": "SpA", "spd": "SpD", "spdef": "SpD", "specialdefense": "SpD", "spe": "Spe", "speed": "Spe"]
        var values: [String: Int] = [:]
        for part in text.components(separatedBy: "/") {
            let chunks = part.split(whereSeparator: { $0.isWhitespace })
            guard let first = chunks.first, let value = Int(first), (0...(ivs ? 31 : 255)).contains(value),
                  let label = aliases[RibbonCatalog.normalise(chunks.dropFirst().joined(separator: " "))], values[label] == nil else { throw ImportError.invalid("Use \(ivs ? "IVs" : "EVs") such as 252 SpA / 4 SpD / 252 Spe, with valid values.") }
            values[label] = value
        }
        if !ivs && values.values.reduce(0, +) > 510 { throw ImportError.invalid("EVs cannot total more than 510.") }
        return labels.compactMap { label in values[label].map { "\($0) \(label)" } }.joined(separator: " / ")
    }
    static func export(_ pokemon: [RibbonPokemon]) -> String {
        pokemon.compactMap { p -> String? in
            let build = p.showdownSet ?? ShowdownSet()
            let species = RibbonCatalog.shared.pokemon[p.species]?.showdown ?? RibbonCatalog.shared.pokemon[p.species]?.name ?? p.species
            let nickname = exportLine(p.nickname).replacingOccurrences(of: #"[()@]"#, with: "", options: .regularExpression)
            var header = nickname.isEmpty ? species : "\(nickname) (\(species))"
            if p.gender == "female" { header += " (F)" }; if p.gender == "male" { header += " (M)" }
            if !build.item.isEmpty { header += " @ " + exportLine(build.item) }
            var lines = [header]
            if !build.ability.isEmpty { lines.append("Ability: " + exportLine(build.ability)) }
            lines.append("Level: \(p.currentlevel)")
            if p.shiny { lines.append("Shiny: Yes") }; if p.gmax { lines.append("Gigantamax: Yes") }
            if !build.teraType.isEmpty { lines.append("Tera Type: " + exportLine(build.teraType)) }
            if !build.evs.isEmpty { lines.append("EVs: " + exportLine(build.evs)) }
            if !build.ivs.isEmpty { lines.append("IVs: " + exportLine(build.ivs)) }
            if !build.nature.isEmpty { lines.append(exportLine(build.nature) + " Nature") }
            lines.append(contentsOf: build.moves.prefix(4).map { "- " + exportLine($0) })
            return lines.joined(separator: "\n")
        }.joined(separator: "\n\n")
    }
}

private struct ExportCompatibility: Decodable {
    var guideSpecies: [String: String]
    var guideGames: [String]
    var guideAwards: [String]
    var guideBalls: [String: String]
    var guideLanguages: [String: String]
    static let shared: Self = {
        guard let url = Bundle.main.url(forResource: "export-compatibility", withExtension: "json", subdirectory: "RibbonAssets"),
              let data = try? Data(contentsOf: url), let value = try? JSONDecoder().decode(Self.self, from: data) else { preconditionFailure("Missing export compatibility catalogue") }
        return value
    }()
}
enum RibbonsGuideExporter {
    static var balls: [SearchChoice] { ExportCompatibility.shared.guideBalls.map { SearchChoice(id: $0.key, name: $0.value) }.sorted { $0.name < $1.name } }
    static var languages: [SearchChoice] { ExportCompatibility.shared.guideLanguages.map { SearchChoice(id: $0.key, name: $0.value) }.sorted { $0.name < $1.name } }
    static func needsBall(_ p: RibbonPokemon) -> Bool { ExportCompatibility.shared.guideBalls[p.ball ?? ""] == nil }
    static func needsLanguage(_ p: RibbonPokemon) -> Bool { ExportCompatibility.shared.guideLanguages[p.language ?? ""] == nil }
    static func speciesID(for pokemon: RibbonPokemon) -> String? { ExportCompatibility.shared.guideSpecies[pokemon.species] }
    static func export(_ records: [RibbonPokemon], merging backup: Data? = nil, fallbackBall: String = "", fallbackLanguage: String = "", fallbackTrainer: String = "", date: Date = Date()) throws -> Data {
        guard !records.isEmpty else { throw ImportError.invalid("Choose at least one Pokémon to export.") }
        let compatibility = ExportCompatibility.shared
        let games = Set(compatibility.guideGames), awards = Set(compatibility.guideAwards)
        var entries: [[String: Any]] = [], boxes: [String] = [], settings: [String: Any] = [:]
        if let backup {
            guard let root = try JSONSerialization.jsonObject(with: backup) as? [String: Any], root["fileVersion"] as? Int == 5,
                  let original = root["pokemon"] as? [[String: Any]], let originalBoxes = root["boxes"] as? [String],
                  let originalSettings = root["settings"] as? [String: Any] else { throw ImportError.invalid("Choose a version 5 backup exported by ribbons.guide.") }
            let allowed = Set("species gender shiny nickname language ball strangeball currentlevel nature totem gmax shadow trainername trainerid originmark origingame currentgame box title scale ribbons metlevel metdate metlocation pokerus achievements notes".split(separator: " ").map(String.init))
            entries = original.map { $0.filter { allowed.contains($0.key) } }; boxes = originalBoxes; settings = originalSettings
        }
        for p in records {
            guard let species = speciesID(for: p) else { throw ImportError.invalid("ribbons.guide does not support the saved form of \(p.displayName).") }
            let ball = needsBall(p) ? fallbackBall : p.ball ?? ""
            let language = needsLanguage(p) ? fallbackLanguage : p.language ?? ""
            guard compatibility.guideBalls[ball] != nil, compatibility.guideLanguages[language] != nil else { throw ImportError.invalid("ribbons.guide needs a Poké Ball type and language. Choose them for Pokémon with missing capture details.") }
            let trainer = p.trainername?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? p.trainername! : fallbackTrainer
            if p.title == "partner-ribbon" && trainer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { throw ImportError.invalid("Enter the original trainer name for the equipped Partner Ribbon.") }
            let owned = RibbonCatalog.shared.chronologicalAwards(p.ribbons.filter { awards.contains($0) })
            let title = awards.contains(p.title) ? p.title : "None"
            let shiny: Any = p.shiny ? "star" as Any : false as Any
            let entry: [String: Any] = [
                "species": species, "nickname": p.nickname, "gender": ["male", "female"].contains(p.gender) ? p.gender : "unknown",
                "shiny": shiny, "currentlevel": String(max(1, min(100, p.currentlevel))),
                "origingame": games.contains(p.origingame) ? p.origingame : "", "currentgame": games.contains(p.currentgame) ? p.currentgame : "",
                "gmax": p.gmax || p.species.hasSuffix("-gmax"), "shadow": p.shadow || p.species == "lugia-shadow", "title": title,
                "ribbons": owned, "box": -1, "ball": ball, "language": language, "trainername": trainer,
                "achievements": [String]()
            ]
            entries.append(entry)
        }
        let root: [String: Any] = ["fileVersion": 5, "lastModified": Int64(date.timeIntervalSince1970 * 1000), "settings": settings, "boxes": boxes, "pokemon": entries]
        return try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    }
}
