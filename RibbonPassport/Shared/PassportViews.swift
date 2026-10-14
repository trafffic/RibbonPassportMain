import SwiftUI
import WidgetKit

struct PassportTheme {
    var dark: Bool
    var game: String
    var style = WidgetStyle()
    var accent: Color {
        switch style.palette {
        case .sage: return Color(hex: dark ? "BEDB8C" : "4B7030")
        case .ocean: return Color(hex: dark ? "A3D7E0" : "326678")
        case .parchment: return Color(hex: dark ? "E0BF81" : "856438")
        case .graphite: return Color(hex: dark ? "C5CADE" : "555D77")
        case .game: break
        }
        let colours = ["as": "4A88D8", "or": "DA6157", "ruby": "D74B55", "sapphire": "4A88D8",
            "emerald": "32A383", "scar": "DF6552", "vio": "9872D9", "sun": "DC9A48", "moon": "8D85D1",
            "sw": "55A8DB", "sh": "D7789F", "pla": "78A791", "plza": "4BA992"]
        return Color(hex: colours[game] ?? "69A0CC")
    }
    private func colour(_ light: [String], _ night: [String]) -> Color {
        let i: Int = switch style.palette { case .sage: 0; case .ocean, .game: 1; case .parchment: 2; case .graphite: 3 }
        return Color(hex: dark ? night[i] : light[i])
    }
    var paper: Color { colour(["E6EDDB", "E5EFF2", "EEE8DA", "E9EAF0"], ["1E2C1F", "1C2C35", "28251D", "232630"]) }
    var panel: Color { colour(["F7F9EE", "F4F9FC", "FCF6E8", "F7F7FC"], ["2C3D2A", "293D49", "393126", "343947"]) }
    var ink: Color { colour(["2D412B", "263F4D", "4C3B26", "32384B"], ["EBF3D8", "E4F1F8", "F2E4C7", "E9EDF9"]) }
    var muted: Color { colour(["566C48", "526A79", "78684D", "626B80"], ["B5C9A3", "ABC5D5", "C4B397", "B9C2D8"]) }
    var board: Color { colour(["D2DFBA", "D5E7ED", "E4D6B7", "D9DDE8"], ["3C5132", "344E5B", "504329", "424B61"]) }
    var border: Color { colour(["9BAD80", "8DA9B5", "B3A078", "9DA6BC"], ["667D52", "60808F", "89734D", "68748E"]) }
    var appearance: String { dark ? "dark" : "light" }
}
extension Color {
    init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0
        self.init(.sRGB, red: Double((value >> 16) & 255) / 255,
                  green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, opacity: 1)
    }
}
struct AssetImage: View {
    var key: String
    var body: some View {
        if let image = Artwork.image(key) { Image(uiImage: image).resizable().interpolation(.none).scaledToFit() }
        else { Image(systemName: "circle.lefthalf.filled").resizable().scaledToFit().foregroundStyle(.secondary) }
    }
}
struct PokemonSprite: View {
    var pokemon: RibbonPokemon
    var download: Bool = false
    @State private var image: UIImage?
    var body: some View {
        Group {
            if let loaded = image ?? Artwork.sprite(pokemon) {
                Image(uiImage: Artwork.trimmed(loaded)).resizable().interpolation(.none).scaledToFit()
            } else {
                Image(systemName: "circle.lefthalf.filled").resizable().scaledToFit().foregroundStyle(.secondary).padding(14)
            }
        }
        .task(id: pokemon.spritePath) {
            guard download else { return }
            let wasCached = Artwork.sprite(pokemon) != nil
            image = nil
            await SpriteLoader.shared.prepare(pokemon)
            image = Artwork.sprite(pokemon)
            if !wasCached && image != nil { WidgetCenter.shared.reloadAllTimelines() }
        }
        .accessibilityLabel(pokemon.displayName + (pokemon.shiny ? ", shiny" : ""))
    }
}
struct PokemonName: View {
    var pokemon: RibbonPokemon
    var theme: PassportTheme
    var size: CGFloat = 17
    var body: some View {
        HStack(spacing: 4) {
            Text(pokemon.displayName).font(PixelFont.font(size, style: theme.style)).lineLimit(1).minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
            if pokemon.shiny { AssetImage(key: "shiny-" + theme.appearance).frame(width: 13, height: 13) }
        }.foregroundStyle(theme.ink)
    }
}
struct GameLabel: View {
    var game: String
    var theme: PassportTheme
    var size: CGFloat = 11
    var body: some View {
        HStack(spacing: 5) {
            if !game.isEmpty { AssetImage(key: "game-\(game)-\(theme.appearance)").frame(width: size <= 8 ? 12 : size <= 10 ? 16 : 20, height: size <= 8 ? 10 : size <= 10 ? 14 : 18) }
            Text(RibbonCatalog.shared.compactGameName(game)).font(PixelFont.font(size, style: theme.style))
                .lineLimit(1).minimumScaleFactor(0.65).frame(maxWidth: .infinity, alignment: .leading)
        }.foregroundStyle(theme.accent)
    }
}
struct ConsoleIcon: View {
    var pokemon: RibbonPokemon
    var theme: PassportTheme
    var compact: Bool = false
    var body: some View {
        if let console = RibbonCatalog.shared.consoleByGame[pokemon.origingame] {
            AssetImage(key: "console-\(console)-\(theme.appearance)").frame(width: compact ? 13 : 18, height: compact ? 10 : 14)
                .accessibilityLabel("Origin console: " + console)
        }
    }
}
struct AwardIcon: View {
    var id: String
    var theme: PassportTheme
    var body: some View {
        AssetImage(key: "award-" + id).padding(2)
            .background(theme.panel, in: RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(tierColour, lineWidth: 1))
            .accessibilityLabel(RibbonCatalog.shared.ribbons[id] ?? id)
    }
    private var tierColour: Color {
        let score = RibbonCatalog.shared.rarity[id]?.score ?? 0
        return Color(hex: score >= 90 ? "BA63C4" : score >= 75 ? "D4A437" : score >= 60 ? "598FC8" : score >= 40 ? "77AA86" : "ABB6BF")
    }
}
struct EquippedTitleLabel: View {
    var pokemon: RibbonPokemon
    var theme: PassportTheme
    var iconSize: CGFloat = 13
    var body: some View {
        let id = RibbonCatalog.shared.equippedID(for: pokemon)
        HStack(spacing: 3) {
            if !id.isEmpty { AssetImage(key: "award-" + id).frame(width: iconSize, height: iconSize) }
            Text(RibbonCatalog.shared.titleText(for: pokemon)).lineLimit(1).minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(id.isEmpty ? theme.muted : Color(hex: Artwork.tintHex("award-" + id, dark: theme.dark)))
        }
    }
}
struct HeldItemLabel: View {
    var item: String
    var theme: PassportTheme
    var body: some View {
        let key = "item-" + RibbonCatalog.normalise(item)
        HStack(spacing: 3) {
            if !item.isEmpty {
                AssetImage(key: Artwork.image(key) == nil ? "item-unknown" : key).frame(width: 14, height: 14)
            }
            Text(item.isEmpty ? "No held item" : item).lineLimit(1).minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(item.isEmpty ? theme.muted : Color(hex: Artwork.tintHex(key, dark: theme.dark)))
        }
    }
}
struct RibbonTriplet: View {
    var pokemon: RibbonPokemon
    var theme: PassportTheme
    var body: some View {
        let ids = Array(RibbonCatalog.shared.ranked(RibbonCatalog.shared.awards(for: pokemon), ribbonsOnly: true).prefix(3))
        HStack(spacing: 5) {
            ForEach(ids, id: \.self) { AwardIcon(id: $0, theme: theme).frame(maxWidth: .infinity) }
            if ids.isEmpty { Text("No ribbons yet").font(.system(size: 9)).foregroundStyle(theme.muted).frame(maxWidth: .infinity) }
        }
    }
}
struct RibbonBoard: View {
    var pokemon: RibbonPokemon
    var theme: PassportTheme
    var body: some View {
        let ids = RibbonCatalog.shared.ranked(RibbonCatalog.shared.awards(for: pokemon))
        VStack(spacing: 5) {
            Text("RIBBON BOARD · \(ids.count)").font(.system(size: 9, weight: .bold))
                .foregroundStyle(theme.muted).frame(maxWidth: .infinity, alignment: .leading)
            GeometryReader { geometry in
                if ids.isEmpty {
                    Text("Your first ribbon goes here.").font(.caption2).foregroundStyle(theme.muted)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    let grid = gridSize(count: ids.count, size: geometry.size)
                    VStack(spacing: 2) {
                        ForEach(0..<grid.rows, id: \.self) { row in
                            HStack(spacing: 2) {
                                ForEach(0..<grid.columns, id: \.self) { column in
                                    let index = row * grid.columns + column
                                    if index < ids.count { AwardIcon(id: ids[index], theme: theme).frame(width: grid.cell, height: grid.cell) }
                                    else { Color.clear.frame(width: grid.cell, height: grid.cell) }
                                }
                            }
                        }
                    }.frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }.padding(8).background(theme.board, in: RoundedRectangle(cornerRadius: 10))
    }
    private func gridSize(count: Int, size: CGSize) -> (columns: Int, rows: Int, cell: CGFloat) {
        var best = (columns: 1, rows: count, cell: CGFloat(0))
        for columns in 1...max(1, count) {
            let rows = Int(ceil(Double(count) / Double(columns)))
            let cell = min(42, min((size.width - CGFloat(columns - 1) * 2) / CGFloat(columns), (size.height - CGFloat(rows - 1) * 2) / CGFloat(rows)))
            if cell > best.cell { best = (columns, rows, cell) }
        }
        return best
    }
}
enum PassportSize { case small, medium, large }
struct SinglePassport: View {
    var pokemon: RibbonPokemon
    var size: PassportSize
    var theme: PassportTheme
    var download = false
    var body: some View { ConfiguredWidgetView(pokemon: [pokemon], name: "", content: .pokemon, size: size, theme: theme, download: download) }
}
struct TeamPassport: View {
    var pokemon: [RibbonPokemon]
    var name: String
    var large: Bool
    var theme: PassportTheme
    var download = false
    var body: some View { ConfiguredWidgetView(pokemon: pokemon, name: name, content: .ribbonTeam, size: large ? .large : .medium, theme: theme, download: download) }
}
struct ShowdownTeamPassport: View {
    var pokemon: [RibbonPokemon]
    var name: String
    var large: Bool
    var theme: PassportTheme
    var download = false
    var body: some View { ConfiguredWidgetView(pokemon: pokemon, name: name, content: .showdownTeam, size: large ? .large : .medium, theme: theme, download: download) }
}
