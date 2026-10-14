import SwiftUI

struct ConfiguredWidgetView: View {
    var pokemon: [RibbonPokemon]
    var name: String
    var content: WidgetContent
    var size: PassportSize
    var theme: PassportTheme
    var download = false
    private var style: WidgetStyle { theme.style }
    private func font(_ size: CGFloat) -> Font { PixelFont.font(size, style: style) }
    private var large: Bool { size == .large }
    var body: some View {
        Group {
            if content == .pokemon, let p = pokemon.first {
                if size == .small { smallPassport(p) }
                else if size == .medium { mediumPassport(p) }
                else { largePassport(p) }
            } else {
                VStack(spacing: 7) {
                    HStack {
                        Text(name.uppercased()).lineLimit(1).minimumScaleFactor(0.7)
                        Spacer(minLength: 3)
                        Text(content == .showdownTeam ? "SHOWDOWN" : "RIBBON TEAM").font(font(10))
                    }.font(font(13)).foregroundStyle(theme.accent)
                    GeometryReader { geometry in
                        let height = max(1, (geometry.size.height - (large ? 6 : 0)) / (large ? 2 : 1))
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                            ForEach(Array(pokemon.prefix(large ? 6 : 3))) { p in
                                if content == .showdownTeam { showdownCard(p, height: height) } else { ribbonCard(p, height: height) }
                            }
                        }
                    }
                }
            }
        }.padding(size == .small ? 10 : 12).background {
            if let wallpaper = style.wallpaper { PixelWallpaperView(settings: wallpaper, dark: theme.dark, base: theme.paper) }
            else { theme.paper }
        }.foregroundStyle(theme.ink)
            .font(font(13)).dynamicTypeSize(.medium)
    }
    private func pokemonName(_ p: RibbonPokemon, size: CGFloat = 15) -> some View {
        HStack(spacing: 3) {
            Text(p.displayName).font(font(size)).lineLimit(1).minimumScaleFactor(0.7)
            if style.showShiny && p.shiny { AssetImage(key: "shiny-" + theme.appearance).frame(width: 11, height: 11) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private func equippedTitle(_ p: RibbonPokemon) -> some View {
        let id = RibbonCatalog.shared.equippedID(for: p)
        return HStack(spacing: 3) {
            if !id.isEmpty { AssetImage(key: "award-" + id).frame(width: 13, height: 15) }
            Text(RibbonCatalog.shared.titleText(for: p)).font(font(11)).lineLimit(2).minimumScaleFactor(0.75)
        }.foregroundStyle(id.isEmpty ? theme.muted : Color(hex: Artwork.tintHex("award-" + id, dark: theme.dark)))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    private func game(_ p: RibbonPokemon) -> some View {
        HStack(spacing: 4) {
            AssetImage(key: "game-\(p.currentgame)-\(theme.appearance)").frame(width: 18, height: 18)
            Text(RibbonCatalog.shared.compactGameName(p.currentgame)).font(font(11)).lineLimit(1).minimumScaleFactor(0.75)
        }.foregroundStyle(theme.muted)
    }
    private func portrait(_ p: RibbonPokemon) -> some View {
        PokemonSprite(pokemon: p, download: download).padding(3).background(theme.panel, in: RoundedRectangle(cornerRadius: 6))
    }
    private func triplet(_ p: RibbonPokemon) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(style.orderedAwards(p, ribbonsOnly: true).prefix(3)), id: \.self) { id in
                AssetImage(key: "award-" + id).frame(maxWidth: .infinity).accessibilityLabel(RibbonCatalog.shared.ribbons[id] ?? id)
            }
        }.frame(height: 22)
    }
    private func metadata(_ p: RibbonPokemon) -> some View {
        HStack(spacing: 4) {
            if style.showLevel { Text("Lv. \(p.currentlevel)").font(font(11)).lineLimit(1) }
            Spacer(minLength: 0)
            if style.showConsole { ConsoleIcon(pokemon: p, theme: theme, compact: true) }
        }.foregroundStyle(theme.muted)
    }
    private func smallPassport(_ p: RibbonPokemon) -> some View {
        VStack(spacing: 3) {
            if style.showGame { game(p).frame(maxWidth: .infinity, alignment: .leading) }
            pokemonName(p, size: 18)
            if style.showTitle { equippedTitle(p).frame(maxHeight: 22) }
            HStack(spacing: 6) {
                portrait(p)
                if style.showAwards {
                    VStack(spacing: 1) { Text("\(RibbonCatalog.shared.awards(for: p).count)").font(font(26)); Text("awards").font(font(11)) }
                        .foregroundStyle(theme.accent)
                }
            }.frame(maxHeight: .infinity)
            metadata(p)
            if style.showAwards { triplet(p) }
        }
    }
    private func mediumPassport(_ p: RibbonPokemon) -> some View {
        VStack(spacing: 6) {
            if style.showGame { game(p).frame(maxWidth: .infinity, alignment: .leading) }
            HStack(spacing: 9) {
                VStack(spacing: 4) {
                    pokemonName(p, size: 19)
                    if style.showTitle { equippedTitle(p).frame(maxHeight: 26) }
                    portrait(p).frame(maxHeight: .infinity)
                    metadata(p)
                }.frame(maxWidth: .infinity)
                if style.showAwards { awardBoard(p).frame(maxWidth: .infinity) }
            }.frame(maxHeight: .infinity)
        }
    }
    private func largePassport(_ p: RibbonPokemon) -> some View {
        VStack(spacing: 9) {
            if style.showGame { game(p).frame(maxWidth: .infinity, alignment: .leading) }
            HStack(spacing: 12) {
                portrait(p).frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 6) {
                    pokemonName(p, size: 24)
                    if style.showTitle { equippedTitle(p) }
                    metadata(p)
                    if style.showAwards { Text("\(RibbonCatalog.shared.awards(for: p).count) awards").font(font(22)).foregroundStyle(theme.accent) }
                }.frame(maxWidth: .infinity)
            }.frame(height: 102)
            if style.showAwards { awardBoard(p).frame(maxHeight: .infinity) }
            else { Spacer(minLength: 0) }
            if style.showJourney {
                HStack(spacing: 4) {
                    ForEach(p.visitedGenerations, id: \.self) { generation in
                        let visit = p.recordedVisits.last { $0.generation == generation }
                        VStack(spacing: 3) {
                            if let visit { AssetImage(key: "game-\(visit.game)-\(theme.appearance)").frame(height: visit.game == "scar" ? 24 : 30) }
                            Text("GEN \(generation.roman)").font(font(10)).lineLimit(1).minimumScaleFactor(0.75)
                        }.padding(4).frame(maxWidth: .infinity).background(theme.panel)
                            .overlay(Rectangle().strokeBorder(theme.border, style: StrokeStyle(lineWidth: 1, dash: [2])))
                    }
                }.frame(height: 54)
            }
        }
    }
    private func awardBoard(_ p: RibbonPokemon) -> some View {
        VStack(spacing: 5) {
            HStack { Text("RIBBONS & MARKS"); Spacer(minLength: 2); Text("\(RibbonCatalog.shared.awards(for: p).count)") }
                .font(font(10)).foregroundStyle(theme.muted).lineLimit(1).minimumScaleFactor(0.7)
            AwardMosaic(ids: style.orderedAwards(p), theme: theme)
        }.padding(8).background(theme.panel, in: RoundedRectangle(cornerRadius: 7))
    }
    private func ribbonCard(_ p: RibbonPokemon, height: CGFloat) -> some View {
        VStack(spacing: 4) {
            pokemonName(p, size: large ? 14 : 13)
            if style.showTitle { equippedTitle(p).frame(height: 25, alignment: .top) }
            PokemonSprite(pokemon: p, download: download).frame(maxHeight: .infinity)
            if style.showGame {
                HStack(spacing: 4) {
                    AssetImage(key: "game-\(p.currentgame)-\(theme.appearance)").frame(width: 16, height: 16)
                    if large { Text(RibbonCatalog.shared.compactGameName(p.currentgame)).font(font(10)).lineLimit(1).minimumScaleFactor(0.65) }
                    Spacer(minLength: 0)
                    if style.showAwards { Text("\(RibbonCatalog.shared.awards(for: p).count)").font(font(11)) }
                }
            }
            if style.showAwards { triplet(p).frame(height: 20) }
            if large { metadata(p) }
        }.padding(6).frame(height: height).frame(maxWidth: .infinity)
            .background(theme.panel, in: RoundedRectangle(cornerRadius: 6))
    }
    private func showdownCard(_ p: RibbonPokemon, height: CGFloat) -> some View {
        let build = p.showdownSet ?? ShowdownSet()
        return VStack(alignment: .leading, spacing: 3) {
            pokemonName(p, size: 13)
            HStack(spacing: 3) {
                PokemonSprite(pokemon: p, download: download).frame(maxWidth: .infinity, maxHeight: .infinity)
                if style.showLevel { Text("\(p.currentlevel)").font(font(10)).foregroundStyle(theme.muted) }
            }.frame(maxHeight: large ? 30 : .infinity)
            if style.showItem { HeldItemLabel(item: build.item, theme: theme).font(font(11)).frame(height: 17) }
            if style.showAbility { Text(build.ability.isEmpty ? "Ability not set" : build.ability).font(font(11)).lineLimit(1).minimumScaleFactor(0.75).foregroundStyle(theme.muted) }
            if style.showTera { Text(build.teraType.isEmpty ? "Tera not set" : "Tera: \(build.teraType)").font(font(11)).lineLimit(1).minimumScaleFactor(0.75).foregroundStyle(theme.accent) }
            if large && style.showNature && !build.nature.isEmpty { Text(build.nature).font(font(11)).foregroundStyle(theme.muted) }
            if large && style.showMoves {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(build.moves.prefix(4).enumerated()), id: \.offset) { _, move in
                        Text(move).font(font(11)).lineLimit(1).minimumScaleFactor(0.7).frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel(move)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }.padding(6).frame(height: height).frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.panel, in: RoundedRectangle(cornerRadius: 6))
    }
}

struct AwardMosaic: View {
    var ids: [String]
    var theme: PassportTheme
    var body: some View {
        GeometryReader { geometry in
            let width = max(1, geometry.size.width), height = max(1, geometry.size.height)
            let columns = max(1, Int(ceil(sqrt(Double(max(1, ids.count)) * Double(width / height)))))
            let rows = max(1, Int(ceil(Double(ids.count) / Double(columns))))
            let cell = max(1, min(28, (width - CGFloat(columns - 1) * 3) / CGFloat(columns), (height - CGFloat(rows - 1) * 3) / CGFloat(rows)))
            VStack(spacing: 3) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 3) {
                        ForEach(0..<columns, id: \.self) { column in
                            let i = row * columns + column
                            if i < ids.count {
                                AssetImage(key: "award-" + ids[i]).frame(width: cell, height: cell)
                                    .accessibilityLabel(RibbonCatalog.shared.ribbons[ids[i]] ?? ids[i])
                            } else { Color.clear.frame(width: cell, height: cell) }
                        }
                    }
                }
            }.frame(width: width, height: height)
        }.accessibilityElement(children: .combine)
    }
}
extension Int {
    var roman: String { [1: "I", 2: "II", 3: "III", 4: "IV", 5: "V", 6: "VI", 7: "VII", 8: "VIII", 9: "IX", 10: "X"][self] ?? String(self) }
}
