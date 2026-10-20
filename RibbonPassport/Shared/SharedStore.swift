import Foundation
import UIKit

enum SharedStore {
    static var groupID: String {
        Bundle.main.object(forInfoDictionaryKey: "RibbonAppGroup") as? String ?? "group.ie.liamburke1.ribbonpassport"
    }
    static func root() throws -> URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            throw ImportError.invalid("Shared storage is unavailable. Enable the same App Group for the app and widget targets in Xcode. See START-HERE.md.")
        }
        return url
    }
    static func load() throws -> CollectionSnapshot {
        let url = try root().appendingPathComponent("collection.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return CollectionSnapshot() }
        return restoringDemoHistory(in: try JSONDecoder().decode(CollectionSnapshot.self, from: Data(contentsOf: url)))
    }
    static func save(_ snapshot: CollectionSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: root().appendingPathComponent("collection.json"), options: .atomic)
    }
    static func restoringDemoHistory(in snapshot: CollectionSnapshot) -> CollectionSnapshot {
        guard snapshot.pokemon.contains(where: { $0.source == "demo" && $0.visits == nil }) else { return snapshot }
        let examples = demo().pokemon
        var result = snapshot
        for i in result.pokemon.indices {
            let p = result.pokemon[i]
            guard p.source == "demo", p.visits == nil,
                  let example = examples.first(where: { $0.species == p.species && $0.origingame == p.origingame && $0.currentgame == p.currentgame && Set($0.ribbons) == Set(p.ribbons) }) else { continue }
            result.pokemon[i].visits = example.visits
            if p.earnedGenerations == nil { result.pokemon[i].earnedGenerations = example.earnedGenerations }
        }
        return result
    }
    static func demo() -> CollectionSnapshot {
        guard let url = Bundle.main.url(forResource: "demo-backup", withExtension: "json", subdirectory: "RibbonAssets"),
              let data = try? Data(contentsOf: url), var pokemon = try? BackupImporter.parse(data) else { return CollectionSnapshot() }
        // These are authored demo journeys, never inferred visits for imported collections.
        let routes = ["pikachu": ["sw"], "lugia": ["xd", "diamond", "white", "as"],
                      "rayquaza": ["ruby", "xd", "platinum", "white", "as"],
                      "metagross": ["diamond", "platinum", "white", "x", "as", "sun", "sw", "scar"],
                      "gardevoir": ["as"], "sylveon": ["vio"]]
        for i in pokemon.indices {
            pokemon[i].visits = (routes[pokemon[i].species] ?? []).map { JourneyVisit(game: $0) }
            var locations: [String: Int] = [:]
            for award in pokemon[i].ribbons {
                let species = pokemon[i].species
                if species == "metagross" {
                    if RibbonCatalog.shared.merges[award] != nil || award == "sinnoh-champion-ribbon" { locations[award] = 4 }
                    else if ["kalos-champion-ribbon", "hoenn-champion-ribbon", "skillful-battler-ribbon", "expert-battler-ribbon"].contains(award) { locations[award] = 6 }
                    else if ["alola-champion-ribbon", "battle-tree-great-ribbon", "battle-tree-master-ribbon"].contains(award) { locations[award] = 7 }
                    else if ["galar-champion-ribbon", "tower-master-ribbon"].contains(award) { locations[award] = 8 }
                    else if ["paldea-champion-ribbon", "master-rank-ribbon"].contains(award) { locations[award] = 9 }
                } else if species == "rayquaza" {
                    locations[award] = award.hasSuffix("-sinnoh") || award == "sinnoh-champion-ribbon" ? 4 :
                        award.hasSuffix("-hoenn") || ["earth-ribbon", "artist-ribbon", "champion-ribbon"].contains(award) ? 3 : 6
                } else if species == "lugia" { locations[award] = ["national-ribbon", "earth-ribbon"].contains(award) ? 3 : 6 }
                else { locations[award] = RibbonCatalog.shared.gameInfo[pokemon[i].currentgame]?.gen }
            }
            pokemon[i].earnedGenerations = locations
        }
        let team = RibbonTeam(name: "Demo Ribbon Team", memberIDs: pokemon.map(\.id))
        return CollectionSnapshot(pokemon: pokemon, teams: [team], selectedID: pokemon.first?.id ?? "", selectedTeamID: team.id)
    }
    static func demoFeature(for species: String) -> String? {
        ["pikachu": "Shiny Gigantamax artwork, a nickname and Sword-earned battle ribbons.",
         "lugia": "Shadow Lugia artwork for an XD origin, with National and Earth Ribbons.",
         "rayquaza": "A shiny Ruby traveller. All 40 older contest ribbons combine into a gold Contest Memory Ribbon in Alpha Sapphire.",
         "metagross": "Diamond origin and DS icon. Older contests and Battle Tower ribbons become silver Memory Ribbons in Scarlet.",
         "gardevoir": "A shiny Alpha Sapphire contest star with all five Master Contest ribbons and a full ribbon board.",
         "sylveon": "A shiny Violet catch with a Rare Mark title. Its four marks count together with its four ribbons."][species]
    }
    static func showdownPreview() -> CollectionSnapshot {
        var snapshot = demo()
        let builds = [
            ShowdownSet(item: "Light Ball", ability: "Static", nature: "Timid", teraType: "Electric", moves: ["Thunderbolt", "Volt Switch", "Grass Knot", "Protect"]),
            ShowdownSet(item: "Leftovers", ability: "Multiscale", nature: "Bold", teraType: "Steel", moves: ["Aeroblast", "Roost", "Calm Mind", "Earth Power"]),
            ShowdownSet(item: "Life Orb", ability: "Air Lock", nature: "Jolly", teraType: "Normal", moves: ["Dragon Ascent", "Extreme Speed", "Dragon Dance", "Earthquake"]),
            ShowdownSet(item: "Assault Vest", ability: "Clear Body", nature: "Adamant", teraType: "Water", moves: ["Meteor Mash", "Bullet Punch", "Earthquake", "Ice Punch"]),
            ShowdownSet(item: "Choice Scarf", ability: "Trace", nature: "Timid", teraType: "Fairy", moves: ["Moonblast", "Psychic", "Focus Blast", "Trick"]),
            ShowdownSet(item: "Throat Spray", ability: "Pixilate", nature: "Modest", teraType: "Fire", moves: ["Hyper Voice", "Tera Blast", "Calm Mind", "Protect"])
        ]
        for i in snapshot.pokemon.indices {
            snapshot.pokemon[i].showdownSet = builds[i]; snapshot.pokemon[i].source = "showdown"
            snapshot.pokemon[i].ribbons = []; snapshot.pokemon[i].title = "None"
        }
        if !snapshot.teams.isEmpty { snapshot.teams[0].name = "Showdown Preview" }
        return snapshot
    }
    static func spriteURL(_ p: RibbonPokemon) throws -> URL {
        let dir = try root().appendingPathComponent("Sprites", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(p.spritePath.replacingOccurrences(of: "/", with: "_"))
    }
}

enum Artwork {
    struct Tint: Decodable { var light: String; var dark: String }
    private static let tints: [String: Tint] = {
        guard let url = Bundle.main.url(forResource: "art-colours", withExtension: "json", subdirectory: "RibbonAssets"),
              let data = try? Data(contentsOf: url), let colours = try? JSONDecoder().decode([String: Tint].self, from: data) else { return [:] }
        return colours
    }()
    static func tintHex(_ key: String, dark: Bool) -> String {
        guard let colour = tints[key] else { return dark ? "E8F2FF" : "17384F" }
        return dark ? colour.dark : colour.light
    }
    static func image(_ key: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: key, withExtension: "png", subdirectory: "RibbonAssets/Art") else { return nil }
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        // Primal Kyogre's padded sprite canvas otherwise makes this mascot much smaller than its slot.
        return key == "game-as-light" || key == "game-as-dark" ? trimmed(image) : image
    }
    static func sprite(_ p: RibbonPokemon) -> UIImage? {
        if p.spritePath == "regular/lugia-shadow.png" { return image("sprite-lugia-shadow") }
        if let url = try? SharedStore.spriteURL(p), let image = UIImage(contentsOfFile: url.path) { return image }
        let key = (p.spritePath as NSString).deletingPathExtension.replacingOccurrences(of: "/", with: "_")
        return image("sprite-" + key)
    }
    static func trimmed(_ image: UIImage) -> UIImage {
        guard let source = image.cgImage else { return image }
        let width = source.width, height = source.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let bounds: CGRect? = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
            context.draw(source, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            var left = width, right = -1, top = height, bottom = -1
            let bytes = buffer.bindMemory(to: UInt8.self)
            for y in 0..<height { for x in 0..<width where bytes[(y * width + x) * 4 + 3] > 8 {
                left = min(left, x); right = max(right, x); top = min(top, y); bottom = max(bottom, y)
            } }
            guard right >= left, bottom >= top else { return nil }
            return CGRect(x: CGFloat(left), y: CGFloat(top), width: CGFloat(right - left + 1), height: CGFloat(bottom - top + 1))
        }
        guard let bounds, let cropped = source.cropping(to: bounds) else { return image }
        return UIImage(cgImage: cropped)
    }
}

actor SpriteLoader {
    static let shared = SpriteLoader()
    private var pending: [String: Task<Void, Never>] = [:]
    func prepare(_ p: RibbonPokemon) async {
        if Artwork.sprite(p) != nil { return }
        let key = p.spritePath
        if let existing = pending[key] { await existing.value; return }
        let task = Task<Void, Never> {
            let catalog = RibbonCatalog.shared
            let primary = "https://raw.githubusercontent.com/msikma/pokesprite/master/pokemon-gen8/" + p.spritePath
            let name = catalog.pokemon[p.species]?.showdown ?? p.species
            let fallback = "https://play.pokemonshowdown.com/sprites/\(p.shiny ? "gen5-shiny" : "gen5")/\(name).png"
            // Gen 9's PokeAPI sprites are pixel art too; use them before the fallback.
            var sources = [primary]
            if let number = catalog.pokemon[p.species]?.pokeapiID, number >= 906 {
                sources.append("https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(p.shiny ? "shiny/" : "")\(number).png")
            }
            sources.append(fallback)
            for source in sources {
                guard let url = URL(string: source) else { continue }
                do {
                    let request = URLRequest(url: url, timeoutInterval: 7)
                    let (data, response) = try await URLSession.shared.data(for: request)
                    guard (response as? HTTPURLResponse)?.statusCode == 200, let image = UIImage(data: data),
                          let prepared = Artwork.trimmed(image).pngData() else { continue }
                    try prepared.write(to: SharedStore.spriteURL(p), options: .atomic)
                    break
                } catch { continue }
            }
        }
        pending[key] = task
        await task.value
        pending[key] = nil
    }
}
