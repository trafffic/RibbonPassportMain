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
                if let layout = style.pokemonLayout, layout != .passport {
                    PokemonFeatureWidget(pokemon: p, layout: layout, size: size, theme: theme, download: download)
                } else {
                    if size == .small { smallPassport(p) }
                    else if size == .medium { mediumPassport(p) }
                    else { largePassport(p) }
                }
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

/// Shared by Widget Studio and the Home Screen so the saved design matches its preview.
struct PokemonFeatureWidget: View {
    var pokemon: RibbonPokemon
    var layout: PokemonWidgetLayout
    var size: PassportSize
    var theme: PassportTheme
    var download = false
    private var style: WidgetStyle { theme.style }
    private var small: Bool { size == .small }
    private var large: Bool { size == .large }
    private var catalog: RibbonCatalog { .shared }
    private func font(_ value: CGFloat) -> Font { PixelFont.font(value, style: style) }

    var body: some View {
        Group {
            switch layout {
            case .pocketCompanion: companion
            case .ribbonCabinet: cabinet
            case .journeyTicket: journey
            case .nextRibbon: nextRibbon
            case .passport: EmptyView()
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    private func kicker(_ label: String) -> some View {
        Text(label.uppercased()).font(font(10)).foregroundStyle(theme.muted)
            .lineLimit(1).minimumScaleFactor(0.8)
    }
    private func name(_ value: CGFloat = 21) -> some View {
        HStack(spacing: 4) {
            Text(pokemon.displayName).font(font(value)).lineLimit(1).minimumScaleFactor(0.7)
            if style.showShiny && pokemon.shiny { AssetImage(key: "shiny-" + theme.appearance).frame(width: 11, height: 11) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private var sprite: some View { PokemonSprite(pokemon: pokemon, download: download) }
    private var companion: some View {
        VStack(alignment: .leading, spacing: small ? 4 : 7) {
            if style.showGame { kicker(catalog.compactGameName(pokemon.currentgame)) }
            name(small ? 20 : 24)
            sprite.padding(4).frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    PixelWallpaperView(settings: style.wallpaper ?? WallpaperSettings(design: .meadow, strength: 0.35), dark: theme.dark, base: theme.board)
                }.clipShape(RoundedRectangle(cornerRadius: 7))
            if large && style.showTitle { title }
            HStack {
                if style.showLevel { Text("Lv. \(pokemon.currentlevel)").font(font(11)).foregroundStyle(theme.muted) }
                Spacer(minLength: 0)
                if style.showAwards {
                    HStack(spacing: 3) {
                        if let id = style.orderedAwards(pokemon, ribbonsOnly: true).first { AssetImage(key: "award-" + id).frame(width: 13, height: 16) }
                        Text("\(catalog.awards(for: pokemon).count) awards").font(font(12))
                    }.foregroundStyle(theme.accent)
                }
            }
        }
    }
    private var title: some View {
        HStack(spacing: 5) {
            let id = catalog.equippedID(for: pokemon)
            if !id.isEmpty { AssetImage(key: "award-" + id).frame(width: 20, height: 24) }
            Text(catalog.titleText(for: pokemon)).font(font(12)).lineLimit(2).minimumScaleFactor(0.8)
        }.foregroundStyle(theme.muted)
    }
    private var cabinet: some View {
        let ids = style.orderedAwards(pokemon, ribbonsOnly: true)
        let limit = large ? 12 : small ? 4 : 8
        let shown = Array(ids.prefix(limit))
        return VStack(alignment: .leading, spacing: small ? 5 : 9) {
            HStack(alignment: .top, spacing: 6) {
                VStack(alignment: .leading, spacing: 3) {
                    kicker(small ? "RIBBON CABINET" : "\(pokemon.displayName)'s collection")
                    if !small { Text("Ribbon cabinet").font(font(22)).lineLimit(1).minimumScaleFactor(0.75) }
                }
                Spacer(minLength: 0)
                if style.showAwards { Text("\(ids.count)").font(font(small ? 23 : 28)).foregroundStyle(theme.accent) }
            }
            if style.showAwards {
                if shown.isEmpty {
                    VStack(spacing: 6) { sprite; Text("No ribbons recorded").font(font(12)).foregroundStyle(theme.muted) }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    cabinetShelf(shown)
                }
                if ids.count > shown.count { Text("+\(ids.count - shown.count) more in passport").font(font(10)).foregroundStyle(theme.muted).lineLimit(1) }
            } else { sprite.frame(maxWidth: .infinity, maxHeight: .infinity) }
            if style.showTitle && large {
                HStack(spacing: 8) {
                    sprite.frame(width: 40, height: 36)
                    VStack(alignment: .leading, spacing: 3) { kicker("Equipped title"); title }
                    Spacer(minLength: 0)
                }.padding(.top, 6).overlay(alignment: .top) { Rectangle().fill(theme.border).frame(height: 1) }
            }
        }
    }
    private func cabinetShelf(_ ids: [String]) -> some View {
        GeometryReader { geometry in
            let columns = small ? 2 : 4
            let rows = max(1, (ids.count + columns - 1) / columns)
            let height = max(1, (geometry.size.height - 12 - CGFloat(rows - 1) * 6) / CGFloat(rows))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: columns), spacing: 6) {
                ForEach(ids, id: \.self) { id in
                    VStack(spacing: 4) {
                        AssetImage(key: "award-" + id).frame(maxWidth: .infinity, maxHeight: .infinity)
                            .accessibilityLabel(catalog.ribbons[id] ?? id)
                        if large {
                            Text((catalog.ribbons[id] ?? id).replacingOccurrences(of: " Ribbon", with: ""))
                                .font(font(10)).lineLimit(1).minimumScaleFactor(0.85).foregroundStyle(theme.muted)
                        }
                    }.padding(.bottom, 4).frame(height: height)
                        .overlay(alignment: .bottom) { Rectangle().fill(theme.board).frame(height: 2) }
                }
            }.padding(6)
        }.background(theme.panel, in: RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(theme.border, lineWidth: 1))
    }
    private var journey: some View {
        let visits = pokemon.recordedVisits
        return Group {
            if small {
                VStack(alignment: .leading, spacing: 5) {
                    kicker("Journey ticket")
                    name(19)
                    sprite.frame(maxWidth: .infinity, maxHeight: .infinity)
                    if style.showJourney { visitStrip(Array(visits.suffix(2))) }
                    if style.showGame { kicker(catalog.compactGameName(pokemon.currentgame)) }
                }
            } else {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        VStack(spacing: 6) {
                            kicker("Passport")
                            sprite.frame(maxHeight: .infinity)
                            if let gen = catalog.gameInfo[pokemon.origingame]?.gen { kicker("Origin · \(gen.roman)") }
                        }.padding(8).frame(width: 88).background(theme.board, in: RoundedRectangle(cornerRadius: 7))
                        VStack(alignment: .leading, spacing: 8) {
                            kicker("The journey so far")
                            name(22)
                            if style.showJourney {
                                if visits.isEmpty { Text("No visits recorded").font(font(12)).foregroundStyle(theme.muted) }
                                else { visitStrip(Array(visits.suffix(4))) }
                            }
                            Spacer(minLength: 0)
                            if style.showGame { Text("Now: \(catalog.compactGameName(pokemon.currentgame))").font(font(11)).foregroundStyle(theme.muted).lineLimit(1).minimumScaleFactor(0.8) }
                            if style.showJourney { Text("\(visits.count) \(visits.count == 1 ? "visit" : "visits")\(visits.count > 4 && !large ? " · latest 4 shown" : "")").font(font(10)).foregroundStyle(theme.muted) }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.frame(maxHeight: large ? 140 : .infinity)
                    if large && style.showJourney {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 7) {
                            ForEach(Array(visits.prefix(8))) { visit in
                                HStack(spacing: 6) {
                                    AssetImage(key: "game-\(visit.game)-\(theme.appearance)").frame(width: 25, height: 25)
                                    Text(catalog.compactGameName(visit.game)).font(font(12)).lineLimit(2).minimumScaleFactor(0.8)
                                    Spacer(minLength: 0)
                                }.padding(5).frame(height: 33).background(theme.panel, in: RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        if visits.count > 8 { Text("+\(visits.count - 8) more in your journey").font(font(11)).foregroundStyle(theme.muted) }
                    }
                    if large { Spacer(minLength: 0) }
                }
            }
        }
    }
    private func visitStrip(_ visits: [JourneyVisit]) -> some View {
        HStack(spacing: 4) {
            ForEach(visits) { visit in
                VStack(spacing: 3) {
                    AssetImage(key: "game-\(visit.game)-\(theme.appearance)").frame(height: small ? 19 : 26)
                    Text(visit.generation.roman).font(font(10)).foregroundStyle(theme.muted)
                }.frame(maxWidth: .infinity).accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(catalog.gameName(visit.game)), generation \(visit.generation)")
            }
        }
    }
    private var nextRibbon: some View {
        let goal = WidgetRibbonGoal.next(for: pokemon)
        return VStack(alignment: .leading, spacing: small ? 5 : 9) {
            HStack(spacing: 6) {
                kicker("Next ribbon")
                Spacer(minLength: 0)
                if !small { sprite.frame(width: 25, height: 24); Text(pokemon.displayName).font(font(11)).lineLimit(1).minimumScaleFactor(0.8) }
            }
            if small { name(18) }
            if let id = goal.awardID {
                if small {
                    AssetImage(key: "award-" + id).frame(maxWidth: .infinity, maxHeight: .infinity).padding(4)
                    Text(catalog.ribbons[id] ?? id).font(font(15)).lineLimit(2).minimumScaleFactor(0.8)
                } else {
                    HStack(spacing: 10) {
                        AssetImage(key: "award-" + id).padding(9).frame(width: 57, height: 61)
                            .background(theme.panel, in: RoundedRectangle(cornerRadius: 7))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(catalog.ribbons[id] ?? id).font(font(21)).lineLimit(2).minimumScaleFactor(0.75)
                            if style.showGame { Text(catalog.compactGameName(goal.game)).font(font(12)).lineLimit(1).minimumScaleFactor(0.8).foregroundStyle(theme.muted) }
                            Text("Open your ribbon checklist").font(font(11)).foregroundStyle(theme.muted).lineLimit(1).minimumScaleFactor(0.8)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.frame(maxHeight: large ? 90 : .infinity)
                    if large, let description = RibbonRules.shared.awards[id]?.description {
                        Text(description).font(font(14)).lineLimit(5).foregroundStyle(theme.muted)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    if !small { sprite.frame(maxHeight: large ? 100 : 40) }
                    Text(goal.transfer.canAssess ? "No reachable ribbon goals" : "Choose a compatible current game")
                        .font(font(small ? 15 : 18)).lineLimit(3).minimumScaleFactor(0.8)
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            if large { Spacer(minLength: 0) }
            goalNotice(goal)
        }
    }
    private func goalNotice(_ goal: WidgetRibbonGoal) -> some View {
        let urgent = goal.isLastChance || !goal.transfer.warnings.isEmpty
        let label: String = if goal.isLastChance, let gen = catalog.gameInfo[goal.game]?.gen { "! Last chance in Gen \(gen.roman)" }
            else if !goal.transfer.warnings.isEmpty { "! Check Footprint eligibility" }
            else { "Open ribbon checklist ›" }
        return Text(label).font(font(small ? 10 : 12)).lineLimit(2).minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading).padding(7)
            .foregroundStyle(urgent ? theme.warningInk : theme.muted)
            .background(urgent ? theme.warningSurface : theme.panel, in: RoundedRectangle(cornerRadius: 5))
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
