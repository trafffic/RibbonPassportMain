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
    var sunMoon: SunMoonWallpaper? = nil
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
        let kind: TeamKind = entry.showdownSet == nil ? .ribbon : .showdown
        var layout = storage(for: kind)
        self.pokemon.append(entry); selectedID = entry.id
        if kind == .ribbon { selectedRibbonID = entry.id } else { selectedCompetitiveID = entry.id }
        if let boxID, let i = layout.boxes.firstIndex(where: { $0.id == boxID }), let slot = layout.boxes[i].slots.firstIndex(where: { $0 == nil }) {
            layout.boxes[i].slots[slot] = entry.id
        } else { layout.placeInFirstSlot(entry.id) }
        if kind == .ribbon { storage = layout } else { competitiveStorage = layout }
    }
}

enum SunMoonWallpaper: String, Codable, CaseIterable, Identifiable {
    case forest = "sm01", city = "sm02", desert = "sm03", savanna = "sm04"
    case crag = "sm05", volcano = "sm06", snow = "sm07", cave = "sm08"
    case beach = "sm09", seafloor = "sm10", river = "sm11", sky = "sm12"
    case pokemonCenter = "sm13", machine = "sm14", checks = "sm15", simple = "sm16"
    var id: String { rawValue }
    var name: String {
        switch self {
        case .forest: "Forest"; case .city: "City"; case .desert: "Desert"; case .savanna: "Savanna"
        case .crag: "Crag"; case .volcano: "Volcano"; case .snow: "Snow"; case .cave: "Cave"
        case .beach: "Beach"; case .seafloor: "Seafloor"; case .river: "River"; case .sky: "Sky"
        case .pokemonCenter: "Pokémon Center"; case .machine: "Machine"; case .checks: "Checks"; case .simple: "Simple"
        }
    }
    var filename: String { "sm-" + rawValue.suffix(2) }
}

struct SearchChoice: Identifiable, Equatable {
    var id: String
    var name: String
    var aliases: [String] = []
    func matches(_ search: String) -> Bool {
        let query = RibbonCatalog.normalise(search)
        return query.isEmpty || ([name, id] + aliases).contains { RibbonCatalog.normalise($0).contains(query) }
    }
}
extension RibbonCatalog {
    var gameChoices: [SearchChoice] {
        chronologicalGames.map { SearchChoice(id: $0, name: gameName($0), aliases: [compactGameName($0)]) }
    }
    func awardChoices(_ ids: [String]) -> [SearchChoice] {
        chronologicalAwards(ids).map { SearchChoice(id: $0, name: awardPickerName($0)) }
    }
}

extension TeamKind {
    var title: String { self == .ribbon ? "Ribbon Masters" : "Competitive" }
    var key: String { self == .ribbon ? "ribbon" : "competitive" }
    var widgetContents: [WidgetContent] { self == .ribbon ? [.pokemon, .ribbonTeam] : [.showdownTeam] }
}
extension CollectionSnapshot {
    func pokemon(for kind: TeamKind) -> [RibbonPokemon] { pokemon.filter { ($0.showdownSet != nil) == (kind == .showdown) } }
    func storage(for kind: TeamKind) -> StorageLayout {
        // Split legacy boxes without creating empty copies of the other section's boxes.
        var layout = (kind == .ribbon ? storage : competitiveStorage ?? storage) ?? StorageLayout()
        if competitiveStorage == nil, let legacy = storage {
            let ribbonIDs = Set(pokemon(for: .ribbon).map(\.id)), battleIDs = Set(pokemon(for: .showdown).map(\.id))
            layout.boxes = legacy.boxes.filter { box in
                let contents = Set(box.slots.compactMap { $0 })
                if kind == .showdown { return !contents.isDisjoint(with: battleIDs) }
                return contents.isEmpty || !contents.isDisjoint(with: ribbonIDs)
            }
        }
        layout.reconcile(pokemonIDs: pokemon(for: kind).map(\.id))
        return layout
    }
    mutating func organizeSections() {
        let ribbon = storage(for: .ribbon), competitive = storage(for: .showdown)
        storage = ribbon; competitiveStorage = competitive
    }
    func selectedPokemonID(for kind: TeamKind) -> String {
        let preferred = kind == .ribbon ? selectedRibbonID : selectedCompetitiveID
        let records = pokemon(for: kind)
        return records.first { $0.id == preferred }?.id ?? records.first { $0.id == selectedID }?.id ?? records.first?.id ?? ""
    }
    func section(forPokemon id: String) -> TeamKind? { pokemon.first { $0.id == id }.map { $0.showdownSet == nil ? .ribbon : .showdown } }
}

/// Sun/Moon's interior is six 32-pixel columns by five 30-pixel rows.
enum PCGridMetrics {
    static let columns = 6, rows = 5
    static let artworkWidth: Double = 208, artworkHeight: Double = 192
    static let originX: Double = 8, originY: Double = 36
    static let gridWidth: Double = 192, gridHeight: Double = 150
    static var aspectRatio: Double { gridWidth / gridHeight }
}
enum AlbumGrouping: String, CaseIterable, Identifiable {
    case generations, games
    var id: String { rawValue }
    var name: String { rawValue.capitalized }
}

extension CollectionSnapshot {
    @discardableResult mutating func movePokemon(_ id: String, in kind: TeamKind, toBox boxID: String, slot: Int) -> Bool {
        guard section(forPokemon: id) == kind else { return false }
        var layout = storage(for: kind)
        guard layout.move(id, toBox: boxID, slot: slot) else { return false }
        if kind == .ribbon { storage = layout; selectedRibbonID = id } else { competitiveStorage = layout; selectedCompetitiveID = id }
        selectedID = id
        return true
    }
}
