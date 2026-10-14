import Foundation

/// Explicit catalog order, so menus never depend on dictionary or rarity ordering.
private struct CatalogSequence: Decodable {
    var games: [String]
    var awards: [String]
    var awardGenerations: [String: Int]
}
enum CatalogOrder {
    private static let sequence: CatalogSequence = {
        guard let url = Bundle.main.url(forResource: "catalog-order", withExtension: "json", subdirectory: "RibbonAssets"),
              let data = try? Data(contentsOf: url), let result = try? JSONDecoder().decode(CatalogSequence.self, from: data) else {
            preconditionFailure("Missing catalog chronology")
        }
        return result
    }()
    private static let games = Dictionary(uniqueKeysWithValues: sequence.games.enumerated().map { ($0.element, $0.offset) })
    private static let awards = Dictionary(uniqueKeysWithValues: sequence.awards.enumerated().map { ($0.element, $0.offset) })
    static func gameIndex(_ id: String) -> Int { games[id] ?? Int.max }
    static func awardGeneration(_ id: String) -> Int { sequence.awardGenerations[id] ?? 0 }
    static func awardIndex(_ id: String) -> Int { awards[id] ?? Int.max }
}
extension RibbonCatalog {
    var chronologicalGames: [String] { games.keys.sorted { (CatalogOrder.gameIndex($0), $0) < (CatalogOrder.gameIndex($1), $1) } }
    func chronologicalAwards(_ ids: [String]) -> [String] {
        Set(ids).sorted { (CatalogOrder.awardIndex($0), $0) < (CatalogOrder.awardIndex($1), $1) }
    }
    func dexNumber(for id: String) -> Int {
        var candidate = id
        while !candidate.isEmpty {
            if let number = pokemon[candidate]?.natdex, number > 0 { return number }
            guard let separator = candidate.lastIndex(of: "-") else { break }
            candidate = String(candidate[..<separator])
        }
        return Int.max
    }
    func speciesPickerName(_ id: String) -> String {
        guard let info = pokemon[id] else { return id }
        if let showdown = info.showdown { return showdown }
        if Self.normalise(info.name) == Self.normalise(id) { return info.name }
        return id.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }
    func awardPickerName(_ id: String) -> String {
        let name = ribbons[id] ?? id
        if id.hasSuffix("-hoenn") { return name + " · Gen III" }
        if id.hasSuffix("-sinnoh") { return name + " · Gen IV" }
        if id.hasSuffix("memory-ribbon-gold") { return name + " · Gold" }
        return name
    }
    func dexOrdered(_ records: [RibbonPokemon]) -> [RibbonPokemon] {
        records.sorted {
            let a = dexNumber(for: $0.species), b = dexNumber(for: $1.species)
            if a != b { return a < b }
            return ($0.displayName, $0.species, $0.id) < ($1.displayName, $1.species, $1.id)
        }
    }
    var nationalDexSpecies: [String] {
        pokemon.keys.sorted {
            let a = dexNumber(for: $0), b = dexNumber(for: $1)
            if a != b { return a < b }
            if $1.hasPrefix($0 + "-") { return true }
            if $0.hasPrefix($1 + "-") { return false }
            return (speciesPickerName($0), $0) < (speciesPickerName($1), $1)
        }
    }
}

enum PixelWallpaper: String, Codable, CaseIterable, Identifiable {
    case classic, meadow, woodland, seaside, dunes, starfield
    var id: String { rawValue }
    var name: String {
        switch self { case .classic: "PC Grid"; case .meadow: "Meadow"; case .woodland: "Woodland"; case .seaside: "Seaside"; case .dunes: "Desert"; case .starfield: "Starfield" }
    }
    var color: String {
        switch self { case .classic: "719957"; case .meadow: "6C995A"; case .woodland: "46836F"; case .seaside: "468BA5"; case .dunes: "B48A4B"; case .starfield: "737AA8" }
    }
}
struct WallpaperSettings: Codable, Equatable {
    var design: PixelWallpaper = .classic
    var tint: String? = nil
    var strength: Double = 0.65
    var colorHex: String { tint ?? design.color }
}

enum WidgetThemePack: String, CaseIterable, Identifiable {
    case pocketGreen, oceanLink, contestAlbum, midnightCircuit, forestTrail
    var id: String { rawValue }
    var name: String {
        switch self { case .pocketGreen: "Pocket Green"; case .oceanLink: "Ocean Link"; case .contestAlbum: "Contest Album"; case .midnightCircuit: "Midnight Circuit"; case .forestTrail: "Forest Trail" }
    }
    var style: WidgetStyle {
        var result = WidgetStyle()
        switch self {
        case .pocketGreen: result.palette = .sage; result.wallpaper = WallpaperSettings(design: .classic, strength: 0.32)
        case .oceanLink: result.palette = .ocean; result.wallpaper = WallpaperSettings(design: .seaside, strength: 0.4)
        case .contestAlbum: result.palette = .parchment; result.wallpaper = WallpaperSettings(design: .dunes, strength: 0.3)
        case .midnightCircuit: result.palette = .graphite; result.appearance = .dark; result.wallpaper = WallpaperSettings(design: .starfield, strength: 0.5)
        case .forestTrail: result.palette = .sage; result.wallpaper = WallpaperSettings(design: .woodland, strength: 0.35)
        }
        return result
    }
    func preset(for content: WidgetContent) -> WidgetPreset {
        WidgetPreset(id: "starter.\(rawValue).\(content.rawValue)", name: name, content: content, style: style)
    }
    static func defaultPack(for content: WidgetContent) -> WidgetThemePack {
        switch content { case .pokemon: .pocketGreen; case .ribbonTeam: .contestAlbum; case .showdownTeam: .midnightCircuit }
    }
}

extension CollectionSnapshot {
    /// Manual entries remain independent of external backup refreshes.
    mutating func addManualPokemon(_ pokemon: RibbonPokemon, toBox boxID: String?) throws {
        let catalog = RibbonCatalog.shared
        guard catalog.pokemon[pokemon.species] != nil else { throw ImportError.invalid("Choose a Pokémon.") }
        guard (1...100).contains(pokemon.currentlevel) else { throw ImportError.invalid("Level must be between 1 and 100.") }
        guard [pokemon.origingame, pokemon.currentgame].allSatisfy({ $0.isEmpty || catalog.games[$0] != nil }) else { throw ImportError.invalid("Choose a game from the list.") }
        guard !self.pokemon.contains(where: { $0.id == pokemon.id }) else { throw ImportError.invalid("This Pokémon has already been added.") }
        var entry = pokemon
        entry.source = "manual"
        entry.nickname = entry.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.ribbons = catalog.chronologicalAwards(entry.ribbons.filter { catalog.ribbons[$0] != nil })
        entry.earnedGenerations = entry.earnedGenerations?.filter { entry.ribbons.contains($0.key) }
        if entry.title != "None" && !entry.ribbons.contains(entry.title) { entry.title = "None"; entry.titleText = "" }
        var layout = organizedStorage
        self.pokemon.append(entry); selectedID = entry.id
        if let boxID, let i = layout.boxes.firstIndex(where: { $0.id == boxID }), let slot = layout.boxes[i].slots.firstIndex(where: { $0 == nil }) {
            layout.boxes[i].slots[slot] = entry.id
        } else { layout.placeInFirstSlot(entry.id) }
        storage = layout
    }
}
