import SwiftUI
import WidgetKit

struct PassportTheme {
    var dark: Bool
    var game: String
    var accent: Color {
        let colours = ["as": "4A88D8", "or": "DA6157", "ruby": "D74B55", "sapphire": "4A88D8",
            "emerald": "32A383", "scar": "DF6552", "vio": "9872D9", "sun": "DC9A48", "moon": "8D85D1",
            "sw": "55A8DB", "sh": "D7789F", "pla": "78A791", "plza": "4BA992"]
        return Color(hex: colours[game] ?? "69A0CC")
    }
    var paper: Color { Color(hex: dark ? "101C2C" : "EBF3FA") }
    var panel: Color { Color(hex: dark ? "192B40" : "FFFFFF") }
    var ink: Color { Color(hex: dark ? "E8F2FF" : "17384F") }
    var muted: Color { Color(hex: dark ? "B8CEE4" : "587389") }
    var board: Color { Color(hex: dark ? "233044" : "FFF6DF") }
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
            Text(pokemon.displayName).font(.system(size: size, weight: .bold)).lineLimit(1).minimumScaleFactor(0.6)
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
            Text(RibbonCatalog.shared.compactGameName(game)).font(.system(size: size, weight: .semibold))
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
    var download: Bool = false
    private var catalog: RibbonCatalog { .shared }
    var body: some View {
        VStack(spacing: size == .small ? 2 : 5) {
            GameLabel(game: pokemon.currentgame, theme: theme, size: size == .small ? 10 : 12)
                .padding(.horizontal, 6).padding(.vertical, size == .small ? 1 : 3).background(theme.panel, in: RoundedRectangle(cornerRadius: 8))
            if size == .small {
                PokemonName(pokemon: pokemon, theme: theme, size: 16)
                title.font(.system(size: 9))
                HStack(spacing: 5) {
                    portrait.frame(maxWidth: .infinity)
                    VStack(spacing: 1) {
                        Text("\(catalog.awards(for: pokemon).count)").font(.system(size: 22, weight: .bold)).foregroundStyle(theme.accent)
                        Text("RIBBONS").font(.system(size: 6, weight: .bold)).foregroundStyle(theme.muted)
                        HStack(spacing: 6) { Text("Lv.\(pokemon.currentlevel)").font(.system(size: 6.5)); ConsoleIcon(pokemon: pokemon, theme: theme, compact: true) }.foregroundStyle(theme.muted)
                    }.frame(width: 46)
                }.frame(maxHeight: .infinity)
                GameLabel(game: pokemon.origingame, theme: theme, size: 8).frame(height: 13)
                RibbonTriplet(pokemon: pokemon, theme: theme).frame(height: 21)
            } else if size == .medium {
                HStack(alignment: .top, spacing: 9) {
                    VStack(spacing: 5) {
                        PokemonName(pokemon: pokemon, theme: theme, size: 17)
                        title.font(.system(size: 10))
                        portrait.frame(maxHeight: .infinity)
                        HStack(spacing: 7) {
                            Text("Lv.\(pokemon.currentlevel) · \(catalog.awards(for: pokemon).count) ribbons")
                                .font(.system(size: 8)).lineLimit(1).minimumScaleFactor(0.6).frame(maxWidth: .infinity, alignment: .leading)
                            ConsoleIcon(pokemon: pokemon, theme: theme)
                        }.foregroundStyle(theme.muted)
                    }.frame(maxWidth: .infinity)
                    RibbonBoard(pokemon: pokemon, theme: theme).frame(maxWidth: .infinity)
                }.frame(maxHeight: .infinity)
            } else {
                PokemonName(pokemon: pokemon, theme: theme, size: 23)
                title.font(.system(size: 12))
                HStack(spacing: 12) {
                    portrait.frame(maxWidth: .infinity)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(catalog.awards(for: pokemon).count)").font(.system(size: 33, weight: .bold)).foregroundStyle(theme.accent)
                        Text("RIBBONS").font(.system(size: 9, weight: .bold)).foregroundStyle(theme.muted)
                        HStack(spacing: 10) { Text("Lv.\(pokemon.currentlevel)").font(.caption2); ConsoleIcon(pokemon: pokemon, theme: theme) }.foregroundStyle(theme.muted)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.frame(height: 82)
                RibbonBoard(pokemon: pokemon, theme: theme).frame(maxHeight: .infinity)
            }
        }.padding(10).background(theme.paper)
    }
    private var title: some View {
        EquippedTitleLabel(pokemon: pokemon, theme: theme, iconSize: size == .small ? 11 : size == .medium ? 13 : 16)
    }
    private var portrait: some View {
        PokemonSprite(pokemon: pokemon, download: download).padding(4)
            .background(theme.panel, in: RoundedRectangle(cornerRadius: 10))
    }
}
struct TeamPassport: View {
    var pokemon: [RibbonPokemon]
    var name: String
    var large: Bool
    var theme: PassportTheme
    var download: Bool = false
    var body: some View {
        VStack(spacing: 7) {
            Text(name.uppercased()).font(.system(size: 11, weight: .bold)).lineLimit(1).minimumScaleFactor(0.7)
                .foregroundStyle(theme.accent).frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 7) {
                ForEach(0..<(large ? 2 : 1), id: \.self) { row in
                    HStack(spacing: 7) {
                        ForEach(0..<3, id: \.self) { column in
                            let index = row * 3 + column
                            if index < pokemon.count { card(pokemon[index]).frame(maxWidth: .infinity, maxHeight: .infinity) }
                            else { Text("Add Pokémon").font(.system(size: 9)).foregroundStyle(theme.muted).frame(maxWidth: .infinity, maxHeight: .infinity).background(theme.panel, in: RoundedRectangle(cornerRadius: 9)) }
                        }
                    }.frame(maxHeight: .infinity)
                }
            }.frame(maxHeight: .infinity)
        }.padding(10).background(theme.paper)
    }
    private func card(_ p: RibbonPokemon) -> some View {
        let t = PassportTheme(dark: theme.dark, game: p.currentgame)
        return VStack(spacing: 4) {
            GameLabel(game: p.currentgame, theme: t, size: large ? 8 : 7)
            PokemonName(pokemon: p, theme: t, size: large ? 14 : 12)
            HStack(spacing: 6) {
                EquippedTitleLabel(pokemon: p, theme: t, iconSize: 10).font(.system(size: large ? 8 : 7))
                ConsoleIcon(pokemon: p, theme: t)
            }.foregroundStyle(t.muted)
            PokemonSprite(pokemon: p, download: download).frame(maxHeight: .infinity)
            RibbonTriplet(pokemon: p, theme: t).frame(height: large ? 23 : 19)
        }.padding(6).background(t.panel, in: RoundedRectangle(cornerRadius: 9))
    }
}

struct ShowdownTeamPassport: View {
    var pokemon: [RibbonPokemon]
    var name: String
    var large: Bool
    var theme: PassportTheme
    var download: Bool = false
    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                Text(name.uppercased()).lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                Text("SHOWDOWN").font(.system(size: 7, weight: .bold))
            }.font(.system(size: 11, weight: .bold)).foregroundStyle(theme.accent)
            VStack(spacing: 7) {
                ForEach(0..<(large ? 2 : 1), id: \.self) { row in
                    HStack(spacing: 7) {
                        ForEach(0..<3, id: \.self) { column in
                            let index = row * 3 + column
                            if index < pokemon.count {
                                card(pokemon[index]).frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                Text("Empty slot").font(.system(size: 9)).foregroundStyle(theme.muted)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(theme.panel, in: RoundedRectangle(cornerRadius: 9))
                            }
                        }
                    }.frame(maxHeight: .infinity)
                }
            }.frame(maxHeight: .infinity)
        }.padding(10).background(theme.paper)
    }
    private func card(_ p: RibbonPokemon) -> some View {
        let build = p.showdownSet ?? ShowdownSet()
        return VStack(alignment: .leading, spacing: large ? 3 : 4) {
            PokemonName(pokemon: p, theme: theme, size: large ? 13 : 12)
            HStack(spacing: 4) {
                PokemonSprite(pokemon: p, download: download).frame(maxWidth: .infinity, maxHeight: .infinity)
                Text("Lv.\(p.currentlevel)").font(.system(size: 8, weight: .semibold)).foregroundStyle(theme.muted)
            }.frame(minHeight: 24, maxHeight: .infinity)
            HeldItemLabel(item: build.item, theme: theme).font(.system(size: 10, weight: .semibold))
            detail(build.ability.isEmpty ? "Ability not set" : build.ability, symbol: "bolt.fill", size: 9, colour: theme.muted)
            detail(build.teraType.isEmpty ? "Tera not set" : "Tera: " + build.teraType, symbol: "diamond.fill", size: 8, colour: theme.accent)
            if large {
                if !build.nature.isEmpty { Text(build.nature + " nature").font(.system(size: 8)).foregroundStyle(theme.muted).lineLimit(1).minimumScaleFactor(0.75) }
                Text(build.moves.isEmpty ? "Moves not set" : build.moves.prefix(4).joined(separator: "\n"))
                    .font(.system(size: 8, weight: .medium)).foregroundStyle(theme.ink).lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }.padding(6).background(theme.panel, in: RoundedRectangle(cornerRadius: 9))
    }
    private func detail(_ text: String, symbol: String, size: CGFloat, colour: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol).font(.system(size: 7)).frame(width: 9)
            Text(text).font(.system(size: size, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .leading)
        }.foregroundStyle(colour)
    }
}
