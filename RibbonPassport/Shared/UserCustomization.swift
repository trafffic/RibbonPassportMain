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
        box.wallpaper ?? WallpaperSettings(design: PixelWallpaper.allCases[(boxes.firstIndex { $0.id == box.id } ?? 0) % PixelWallpaper.allCases.count])
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
        var result = storage ?? StorageLayout(); result.reconcile(pokemonIDs: pokemon.map(\.id)); return result
    }
}

enum ShowdownExporter {
    static func export(_ pokemon: [RibbonPokemon]) -> String {
        pokemon.compactMap { p -> String? in
            guard let build = p.showdownSet else { return nil }
            let species = RibbonCatalog.shared.pokemon[p.species]?.showdown ?? RibbonCatalog.shared.pokemon[p.species]?.name ?? p.species
            var header = p.nickname.isEmpty ? species : "\(p.nickname) (\(species))"
            if p.gender == "female" { header += " (F)" }; if p.gender == "male" { header += " (M)" }
            if !build.item.isEmpty { header += " @ " + build.item }
            var lines = [header]
            if !build.ability.isEmpty { lines.append("Ability: " + build.ability) }
            lines.append("Level: \(p.currentlevel)")
            if p.shiny { lines.append("Shiny: Yes") }; if p.gmax { lines.append("Gigantamax: Yes") }
            if !build.teraType.isEmpty { lines.append("Tera Type: " + build.teraType) }
            if !build.evs.isEmpty { lines.append("EVs: " + build.evs) }
            if !build.ivs.isEmpty { lines.append("IVs: " + build.ivs) }
            if !build.nature.isEmpty { lines.append(build.nature + " Nature") }
            lines.append(contentsOf: build.moves.prefix(4).map { "- " + $0 })
            return lines.joined(separator: "\n")
        }.joined(separator: "\n\n")
    }
}
