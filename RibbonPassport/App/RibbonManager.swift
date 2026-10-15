import SwiftUI

struct ManageRibbonsButton: View {
    var pokemon: RibbonPokemon
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AssetImage(key: "award-contest-star-ribbon").frame(width: 30, height: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Manage ribbons").font(PixelFont.font(22))
                    Text("\(pokemon.ownedRibbonIDs.count) owned").font(PixelFont.font(13))
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.system(size: 17))
            }.frame(maxWidth: .infinity, alignment: .leading)
        }.buttonStyle(RetroAction(prominent: true)).accessibilityIdentifier("ribbons.manage")
    }
}

struct RibbonMetLevelEditor: View {
    @Binding var pokemon: RibbonPokemon
    var body: some View {
        Toggle("Met level known", isOn: Binding(get: { pokemon.metLevel != nil }, set: { pokemon.metLevel = $0 ? pokemon.currentlevel : nil }))
        if pokemon.metLevel != nil {
            Stepper("Met at level \(pokemon.metLevel ?? 1)", value: Binding(get: { pokemon.metLevel ?? 1 }, set: { pokemon.metLevel = $0 }), in: 1...100)
        }
    }
}

/// Edits a local copy; one successful save updates collection storage and widget timelines.
struct StoredRibbonManager: View {
    var pokemonID: String
    var entryTitle = "Passport"
    var showOwned = false
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: RibbonPokemon?
    var body: some View {
        Group {
            if draft != nil {
                RibbonManager(pokemon: Binding(get: { draft! }, set: { draft = $0 }), entryTitle: entryTitle, initiallyOwned: showOwned) {
                    guard let draft, store.snapshot.pokemon.contains(where: { $0.id == pokemonID }) else { return }
                    store.update(draft)
                    if store.error == nil { dismiss() }
                }
            } else { ProgressView().onAppear { draft = store.snapshot.pokemon.first { $0.id == pokemonID } } }
        }
    }
}

private enum RibbonCategory: String, CaseIterable { case all = "All", last = "Last chance", later = "Later gens" }
private enum RibbonPanel: String, Identifiable { case games, owned; var id: String { rawValue } }
private struct RibbonDetails: Identifiable { var id: String }

struct RibbonManager: View {
    @Binding private var destinationPokemon: RibbonPokemon
    @State private var pokemon: RibbonPokemon
    var entryTitle = "Edit Pokémon"
    var initiallyOwned = false
    var onSave: () -> Void
    init(pokemon: Binding<RibbonPokemon>, entryTitle: String = "Edit Pokémon", initiallyOwned: Bool = false, allGames: Bool = false, earnableOnly: Bool = true, onSave: @escaping () -> Void) {
        _destinationPokemon = pokemon
        _pokemon = State(initialValue: pokemon.wrappedValue)
        _catalogue = State(initialValue: allGames); _earnable = State(initialValue: earnableOnly)
        self.entryTitle = entryTitle; self.initiallyOwned = initiallyOwned; self.onSave = onSave
    }
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var typeSize
    @AppStorage("ribbons.pageSize") private var savedSize = 12
    @State private var game = ""
    @State private var catalogue = false
    @State private var earnable = true
    @State private var category = RibbonCategory.all
    @State private var page = 0
    @State private var panel: RibbonPanel?
    @State private var detail: RibbonDetails?
    @State private var pending: String?
    @State private var undo: RibbonPokemon?
    @State private var message = ""
    private let rules = RibbonRules.shared
    private var size: Int { RibbonPageSize.validated(savedSize) }
    private var theme: PassportTheme { PassportTheme(dark: scheme == .dark, game: game) }
    private var availableGames: [String] { rules.compatibleGames(for: pokemon) }
    private var matching: [String] {
        let candidates = rules.ribbonIDs.filter { id in
            if !catalogue && !(rules.awards[id]?.games.contains(game) ?? false) { return false }
            let owned = pokemon.ribbons.contains(id)
            if earnable && (owned || (catalogue ? rules.earningGames(for: id, pokemon: pokemon).isEmpty : rules.unavailableReason(id, game: game, pokemon: pokemon) != nil)) { return false }
            if category == .last { return rules.isLastChance(id, game: game, pokemon: pokemon) }
            if category == .later { return !owned && !rules.laterGames(for: id, after: game, pokemon: pokemon).isEmpty }
            return true
        }
        let priorities = Dictionary(uniqueKeysWithValues: candidates.map { ($0, priority($0)) })
        return candidates.sorted {
            let a = priorities[$0] ?? 4, b = priorities[$1] ?? 4
            return a == b ? CatalogOrder.awardIndex($0) < CatalogOrder.awardIndex($1) : a < b
        }
    }
    private var pageCount: Int { max(1, (matching.count + size - 1) / size) }
    private func priority(_ id: String) -> Int {
        if pokemon.ribbons.contains(id) { return 3 }
        if rules.isLastChance(id, game: game, pokemon: pokemon) { return 0 }
        if !rules.laterGames(for: id, after: game, pokemon: pokemon).isEmpty { return 2 }
        return rules.unavailableReason(id, game: game, pokemon: pokemon) == nil ? 1 : 4
    }
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if typeSize.isAccessibilitySize {
                    ScrollView { managerContent(gridHeight: CGFloat(size == 32 ? 8 : 4) * 80).padding(12) }
                } else {
                    GeometryReader { geometry in
                        let minimum: CGFloat = size == 32 ? 259 : 239
                        if geometry.size.height < minimum + 334 {
                            ScrollView { managerContent(gridHeight: minimum).padding(12) }
                        } else { managerContent(gridHeight: geometry.size.height - 334).padding(12) }
                    }
                }
                footer
            }.background(theme.paper).foregroundStyle(theme.ink)
                .navigationTitle("Ribbons").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) { Text("RIBBONS").font(PixelFont.font(21)) }
                    ToolbarItem(placement: .cancellationAction) { Button("‹ \(entryTitle)") { dismiss() }.font(PixelFont.font(14)) }
                }
                .onAppear {
                    savedSize = size
                    if game.isEmpty { game = availableGames.contains(pokemon.currentgame) ? pokemon.currentgame : availableGames.first ?? "" }
                    if initiallyOwned { panel = .owned }
                }
                .sheet(item: $panel, onDismiss: { pending = nil }) { target in
                    if target == .owned { ownedDrawer }
                    else { gamePicker }
                }
                .sheet(item: $detail) { choice in detailView(choice.id) }
        }.tint(theme.accent)
    }
    private func managerContent(gridHeight: CGFloat) -> some View {
        let list = matching
        let pages = max(1, (list.count + size - 1) / size)
        let ids = Array(list.dropFirst(min(page, pages - 1) * size).prefix(size))
        return VStack(spacing: 8) {
            HStack(spacing: 9) {
                PokemonSprite(pokemon: pokemon, download: true).frame(width: 40, height: 43)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(pokemon.displayName.uppercased()).font(PixelFont.font(19)).lineLimit(1).minimumScaleFactor(0.7)
                        if let label = rules.category(for: pokemon) { Text(label).font(PixelFont.font(10)).padding(4).background(theme.board) }
                    }
                    Text("Lv. \(pokemon.currentlevel) · \(RibbonCatalog.shared.compactGameName(pokemon.currentgame))").font(PixelFont.font(12)).foregroundStyle(theme.muted)
                }
                Spacer(minLength: 0)
            }.frame(height: 49)
            HStack(spacing: 7) {
                if !game.isEmpty { GameMascot(game: game, size: 25) }
                VStack(alignment: .leading, spacing: 2) {
                    Text(game.isEmpty ? "Choose a game" : RibbonCatalog.shared.compactGameName(game)).font(PixelFont.font(17)).lineLimit(1).minimumScaleFactor(0.75)
                    if let gen = rules.games[game]?.gen { Text("GEN \(gen.roman)").font(PixelFont.font(11)).foregroundStyle(theme.muted) }
                }
                Spacer(minLength: 0)
                Button("Change") { pending = nil; panel = .games }.font(PixelFont.font(13)).buttonStyle(.bordered).disabled(availableGames.isEmpty)
            }.frame(minHeight: 38)
            HStack {
                Toggle("Earnable only", isOn: $earnable).toggleStyle(.switch).labelsHidden().scaleEffect(0.8).frame(width: 42)
                    .accessibilityLabel("Earnable only").accessibilityIdentifier("ribbons.earnable")
                Text("Earnable only").font(PixelFont.font(14))
                Spacer()
                Button { catalogue.toggle(); page = 0 } label: { Text("All").font(PixelFont.font(14)).padding(.horizontal, 11).padding(.vertical, 7).background(catalogue ? theme.board : theme.panel).overlay(Rectangle().stroke(theme.border)) }
                    .buttonStyle(.plain).accessibilityLabel("All games").accessibilityValue(catalogue ? "On" : "Off").accessibilityIdentifier("ribbons.allGames")
            }.frame(height: 34)
            HStack(spacing: 5) {
                ForEach(RibbonCategory.allCases, id: \.self) { value in
                    Button { category = value; page = 0 } label: {
                        Text(value.rawValue).font(PixelFont.font(13)).frame(maxWidth: .infinity).padding(.vertical, 8)
                            .background(category == value ? (value == .last ? theme.warningSurface : theme.board) : theme.panel)
                            .foregroundStyle(value == .last ? theme.warningInk : theme.ink)
                            .overlay(Rectangle().stroke(value == .last ? theme.warningBorder : theme.border, lineWidth: category == .last && value == .last ? 2 : 1))
                    }.buttonStyle(.plain).accessibilityAddTraits(category == value ? .isSelected : [])
                }
            }
            HStack {
                Text("\(list.count) shown · \(category == .all ? "Last chance first" : category.rawValue)").font(PixelFont.font(11)).foregroundStyle(theme.muted)
                Spacer(minLength: 4)
                Button { savedSize = RibbonPageSize.next(size); page = 0 } label: {
                    Text("\(size)/pg").font(PixelFont.font(11)).padding(.horizontal, 5).padding(.vertical, 3)
                        .background(theme.panel).overlay(RoundedRectangle(cornerRadius: 3).stroke(theme.border))
                        .frame(minWidth: 44, minHeight: 30).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityLabel("\(size) ribbons per page. Change to \(RibbonPageSize.next(size))")
                    .accessibilityIdentifier("ribbons.pageSize")
            }.frame(height: 25)
            ribbonGrid(height: gridHeight, ids: ids)
            HStack {
                Button("‹ Previous") { page -= 1 }.disabled(page == 0)
                Spacer(); Text("\(min(page + 1, pages)) / \(pages)").foregroundStyle(theme.muted); Spacer()
                Button("Next ›") { page += 1 }.disabled(page + 1 >= pages)
            }.font(PixelFont.font(13)).frame(minHeight: 28)
            Button { panel = .owned } label: {
                HStack {
                    Text("Owned ribbons · \(pokemon.ownedRibbonIDs.count) ▴").font(PixelFont.font(16))
                    Spacer(minLength: 2)
                    ForEach(Array(pokemon.ownedRibbonIDs.suffix(3)), id: \.self) { id in AssetImage(key: "award-" + id).frame(width: 22, height: 26) }
                }.padding(.horizontal, 9).frame(minHeight: 43).background(theme.board).overlay(Rectangle().stroke(theme.border))
            }.buttonStyle(.plain).accessibilityIdentifier("ribbons.owned")
        }.onChange(of: earnable) { _, _ in page = 0 }
    }
    private func ribbonGrid(height: CGFloat, ids: [String]) -> some View {
        let columns = size == 12 ? 3 : 4
        let rows = size / columns
        let cellHeight = max(28, (height - CGFloat(rows - 1) * 5) / CGFloat(rows))
        return ZStack {
            if ids.isEmpty { Text(game.isEmpty ? "Set a current game to choose ribbons." : "No unearned ribbons in this selection.").font(PixelFont.font(16)).foregroundStyle(theme.muted).multilineTextAlignment(.center) }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: columns), spacing: 5) {
                ForEach(ids, id: \.self) { id in ribbonTile(id, height: cellHeight) }
            }.frame(maxHeight: .infinity, alignment: .top)
        }.frame(height: height)
    }
    private func ribbonTile(_ id: String, height: CGFloat) -> some View {
        let owned = pokemon.ribbons.contains(id)
        let last = rules.isLastChance(id, game: game, pokemon: pokemon)
        let allowed = catalogue ? !rules.earningGames(for: id, pokemon: pokemon).isEmpty : rules.unavailableReason(id, game: game, pokemon: pokemon) == nil
        let name = RibbonCatalog.shared.awardPickerName(id)
        return ZStack(alignment: .topTrailing) {
            Button { if owned { remove(id) } else if allowed { add(id) } else { detail = RibbonDetails(id: id) } } label: {
                VStack(spacing: 3) {
                    AssetImage(key: "award-" + id).frame(height: size == 32 ? min(26, height - 5) : min(28, height * 0.36))
                    if size != 32 {
                        Text(name.replacingOccurrences(of: " Ribbon", with: "")).font(PixelFont.font(size == 16 ? 11 : 12)).lineLimit(2).multilineTextAlignment(.center).frame(maxWidth: .infinity)
                        Text(owned ? "✓ Owned" : last ? "LAST CHANCE" : laterLabel(id)).font(PixelFont.font(10)).lineLimit(1)
                            .foregroundStyle(last ? theme.warningInk : theme.muted)
                    }
                }.padding(.horizontal, size == 32 ? 12 : 3).frame(maxWidth: .infinity).frame(height: height)
                    .background(owned ? theme.board : last ? theme.warningSurface : theme.panel)
                    .overlay(Rectangle().stroke(last ? theme.warningBorder : owned ? theme.accent : theme.border, lineWidth: last ? 2 : owned ? 2 : 1))
                    .overlay(alignment: .topLeading) {
                        if last {
                            Text("!").font(PixelFont.font(12)).frame(width: 15, height: 17)
                                .background(theme.warningBorder).foregroundStyle(theme.warningSurface).accessibilityHidden(true)
                        }
                    }
            }.buttonStyle(.plain).accessibilityLabel(owned ? "Remove \(name), \(pokemon.earningLocation(id))" : "\(name), \(status(id))")
                .accessibilityIdentifier("ribbons.tile.\(id)")
            Button { detail = RibbonDetails(id: id) } label: { Text("i").font(PixelFont.font(12)).frame(width: 20, height: 22).background(theme.panel.opacity(0.9)) }
                .buttonStyle(.plain).accessibilityLabel("Details for \(name)")
        }
    }
    private func laterLabel(_ id: String) -> String {
        let gens = Set(rules.laterGames(for: id, after: game, pokemon: pokemon).compactMap { rules.games[$0]?.gen }).sorted()
        return gens.isEmpty ? "Details" : "Later · " + gens.map(\.roman).joined(separator: ", ")
    }
    private func status(_ id: String) -> String {
        if pokemon.ribbons.contains(id) { return "Owned · " + pokemon.earningLocation(id) }
        if rules.isLastChance(id, game: game, pokemon: pokemon) { return "Last chance before leaving this generation" }
        return rules.unavailableReason(id, game: game, pokemon: pokemon) ?? laterLabel(id)
    }
    private var footer: some View {
        HStack(spacing: 8) {
            Text(message.isEmpty ? "\(pokemon.ownedRibbonIDs.count) owned ribbons" : message).font(PixelFont.font(12)).foregroundStyle(theme.muted).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading).accessibilityAddTraits(.updatesFrequently)
            Button("Undo") { restore() }.disabled(undo == nil).font(PixelFont.font(14)).buttonStyle(.bordered)
            Button("Save") { destinationPokemon = pokemon; onSave() }.buttonStyle(RetroAction(prominent: true)).accessibilityIdentifier("ribbons.save")
        }.padding(.horizontal, 12).padding(.vertical, 7).background(theme.paper).overlay(alignment: .top) { Rectangle().fill(theme.border).frame(height: 1) }
    }
    private var gamePicker: some View {
        RibbonGamePicker(pokemon: pokemon, selected: game, award: pending) { chosen in
            game = chosen; page = 0
            if let id = pending { pending = nil; record(id, in: chosen) }
            panel = nil
        }
    }
    private var ownedDrawer: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if pokemon.ownedRibbonIDs.isEmpty { Text("No ribbons recorded").font(PixelFont.font(17)).padding(24) }
                        ForEach(pokemon.ownedRibbonIDs.reversed(), id: \.self) { id in
                            HStack(spacing: 9) {
                                Button { remove(id) } label: {
                                    HStack(spacing: 8) {
                                        AssetImage(key: "award-" + id).frame(width: 28, height: 34)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(RibbonCatalog.shared.awardPickerName(id)).font(PixelFont.font(16))
                                            Text(pokemon.earningLocation(id)).font(PixelFont.font(12)).foregroundStyle(theme.muted)
                                        }.frame(maxWidth: .infinity, alignment: .leading)
                                    }.padding(.vertical, 10)
                                }.buttonStyle(.plain).accessibilityLabel("Remove \(RibbonCatalog.shared.awardPickerName(id))")
                                if pokemon.earnedGames?[id] == nil {
                                    NavigationLink {
                                        RibbonGamePicker(pokemon: pokemon, selected: "", award: id, historical: true) { chosen in
                                            undo = pokemon; pokemon.assignAward(id, game: chosen); message = "Earning game saved"; panel = nil
                                        }
                                    } label: { Text("Set game").font(PixelFont.font(12)) }
                                }
                                Button("Remove") { remove(id) }.font(PixelFont.font(12)).buttonStyle(.bordered)
                            }.overlay(alignment: .bottom) { Rectangle().fill(theme.border).frame(height: 1) }
                        }
                    }.padding(.horizontal, 14)
                }.scrollIndicators(.visible)
                HStack { Text(message).font(PixelFont.font(12)).frame(maxWidth: .infinity, alignment: .leading); Button("Undo") { restore() }.disabled(undo == nil) }.padding(14)
            }.background(theme.panel).foregroundStyle(theme.ink).navigationTitle("Owned ribbons · \(pokemon.ownedRibbonIDs.count)").navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Done") { panel = nil }.font(PixelFont.font(15)) }
        }.presentationDetents([.fraction(0.75), .large]).presentationDragIndicator(.visible)
    }
    private func detailView(_ id: String) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    HStack { AssetImage(key: "award-" + id).frame(width: 43, height: 50); Text(RibbonCatalog.shared.awardPickerName(id)).font(PixelFont.font(23)) }
                    Text(rules.awards[id]?.description ?? "").font(PixelFont.font(17))
                    Text(status(id)).font(PixelFont.font(15)).padding(12).frame(maxWidth: .infinity, alignment: .leading)
                        .background(rules.isLastChance(id, game: game, pokemon: pokemon) ? theme.warningSurface : theme.board)
                        .foregroundStyle(rules.isLastChance(id, game: game, pokemon: pokemon) ? theme.warningInk : theme.ink)
                    ForEach(Array(Set(rules.laterGames(for: id, after: game, pokemon: pokemon).compactMap { rules.games[$0]?.gen })).sorted(), id: \.self) { gen in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("GEN \(gen.roman)").font(PixelFont.font(18))
                            Text(rules.laterGames(for: id, after: game, pokemon: pokemon).filter { rules.games[$0]?.gen == gen }.map { RibbonCatalog.shared.gameName($0) }.joined(separator: " · ")).font(PixelFont.font(15))
                        }
                    }
                    if pokemon.ribbons.contains(id) {
                        if pokemon.earnedGames?[id] == nil {
                            NavigationLink("Choose earning game") {
                                RibbonGamePicker(pokemon: pokemon, selected: "", award: id, historical: true) { chosen in
                                    undo = pokemon; pokemon.assignAward(id, game: chosen); message = "Earning game saved"; detail = nil
                                }
                            }.buttonStyle(RetroAction())
                        }
                        Button("Remove ribbon") { remove(id); detail = nil }.buttonStyle(RetroAction())
                    }
                }.padding(16)
            }.background(theme.paper).foregroundStyle(theme.ink).navigationTitle("Ribbon details").navigationBarTitleDisplayMode(.inline).toolbar { Button("Done") { detail = nil } }
        }
    }
    private func add(_ id: String) {
        if rules.unavailableReason(id, game: game, pokemon: pokemon) == nil { record(id, in: game) }
        else { pending = id; panel = .games }
    }
    private func record(_ id: String, in game: String) {
        let before = pokemon
        if pokemon.recordRibbon(id, game: game) { undo = before; message = "Added · \(RibbonCatalog.shared.compactGameName(game))" }
    }
    private func remove(_ id: String) { undo = pokemon; pokemon.removeAward(id); message = "\(RibbonCatalog.shared.ribbons[id] ?? id) removed"; page = min(page, pageCount - 1) }
    private func restore() { if let previous = undo { pokemon = previous; undo = nil; message = "Change undone" } }
}

struct RibbonGamePicker: View {
    var pokemon: RibbonPokemon
    var selected: String
    var award: String?
    var historical = false
    var onSelect: (String) -> Void
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @State private var generation: Int?
    @State private var page = 0
    private let rules = RibbonRules.shared
    private var choices: [String] {
        rules.compatibleGames(for: pokemon, reachableOnly: !historical).filter { game in
            if historical && !pokemon.recordedVisits.contains(where: { $0.game == game }) { return false }
            return award.map { rules.unavailableReason($0, game: game, pokemon: pokemon, historical: historical) == nil } ?? true
        }
    }
    var body: some View {
        let theme = PassportTheme(dark: scheme == .dark, game: selected)
        let generations = Array(Set(choices.compactMap { rules.games[$0]?.gen })).sorted()
        let games = choices.filter { rules.games[$0]?.gen == generation }
        let pages = max(1, (games.count + 5) / 6)
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if let generation {
                    Button("‹ Generations") { self.generation = nil; page = 0 }.font(PixelFont.font(15))
                    Text("GEN \(generation.roman)").font(PixelFont.font(23))
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                        ForEach(Array(games.dropFirst(min(page, pages - 1) * 6).prefix(6)), id: \.self) { game in
                            Button { onSelect(game) } label: {
                                HStack(spacing: 8) {
                                    GameMascot(game: game, size: 29)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(RibbonCatalog.shared.compactGameName(game)).font(PixelFont.font(16))
                                        Text(game == pokemon.currentgame ? "Current game" : "Compatible").font(PixelFont.font(11)).foregroundStyle(theme.muted)
                                    }
                                    Spacer(minLength: 0)
                                }.frame(maxWidth: .infinity, minHeight: 77, alignment: .leading).padding(8)
                                    .background(game == selected ? theme.board : theme.panel).overlay(Rectangle().stroke(theme.border))
                            }.buttonStyle(.plain).accessibilityIdentifier("ribbons.game.\(game)")
                        }
                    }
                    if pages > 1 {
                        HStack {
                            Button("‹ Previous") { page -= 1 }.disabled(page == 0)
                            Spacer(); Text("\(page + 1) / \(pages)"); Spacer()
                            Button("Next ›") { page += 1 }.disabled(page + 1 >= pages)
                        }.font(PixelFont.font(14))
                    }
                } else {
                    Text(historical ? "Recorded generations" : "Reachable generations").font(PixelFont.font(22))
                    if choices.isEmpty { Text("No compatible recorded games for this ribbon.").font(PixelFont.font(16)).foregroundStyle(theme.muted) }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(generations, id: \.self) { gen in
                            Button { generation = gen; page = 0 } label: {
                                VStack(spacing: 8) {
                                    Text("GEN \(gen.roman)").font(PixelFont.font(21))
                                    Text("\(choices.filter { rules.games[$0]?.gen == gen }.count) games").font(PixelFont.font(12)).foregroundStyle(theme.muted)
                                }.frame(maxWidth: .infinity, minHeight: 82).background(theme.panel).overlay(Rectangle().stroke(theme.border))
                            }
                            .buttonStyle(.plain).accessibilityIdentifier("ribbons.generation.\(gen)")
                        }
                    }
                }
                Spacer(minLength: 0)
            }.padding(14).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).background(theme.paper).foregroundStyle(theme.ink)
                .navigationTitle(award == nil ? "Choose game" : "Earned in which game?").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.font(PixelFont.font(15)) } }
        }
    }
}
