import SwiftUI
import UniformTypeIdentifiers

extension AppStore {
    func editStorage(kind: TeamKind = .ribbon, _ change: (inout StorageLayout) -> Void) {
        var next = snapshot
        var layout = next.storage(for: kind)
        change(&layout)
        layout.reconcile(pokemonIDs: next.pokemon(for: kind).map(\.id))
        if kind == .ribbon { next.storage = layout } else { next.competitiveStorage = layout }; commit(next)
    }
    func savePreset(_ preset: WidgetPreset, makeDefault: Bool = false) {
        var next = snapshot
        var presets = next.widgetPresets ?? []
        if let i = presets.firstIndex(where: { $0.id == preset.id }) { presets[i] = preset } else { presets.append(preset) }
        next.widgetPresets = presets
        if makeDefault {
            if next.widgetDefaults == nil { next.widgetDefaults = [:] }
            next.widgetDefaults?[preset.content.rawValue] = preset.id
        }
        commit(next)
    }
    func useThemePack(_ pack: WidgetThemePack, section: TeamKind? = nil) {
        var next = snapshot
        if next.widgetDefaults == nil { next.widgetDefaults = [:] }
        for content in section?.widgetContents ?? WidgetContent.allCases { next.widgetDefaults?[content.rawValue] = pack.preset(for: content).id }
        commit(next)
    }
    func addPokemon(_ pokemon: RibbonPokemon, toBox boxID: String?) -> Bool {
        do {
            var next = snapshot
            try next.addManualPokemon(pokemon, toBox: boxID)
            commit(next)
            return error == nil
        } catch { self.error = error.localizedDescription; return false }
    }
    func deletePreset(_ id: String) {
        var next = snapshot
        next.widgetPresets?.removeAll { $0.id == id }
        next.widgetDefaults = next.widgetDefaults?.filter { $0.value != id }
        commit(next)
    }
}

struct PCStorageView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    var kind: TeamKind = .ribbon
    @AppStorage private var partyVisible: Bool
    init(kind: TeamKind = .ribbon) {
        self.kind = kind
        _partyVisible = AppStorage(wrappedValue: false, "pc.\(kind.key).partyVisible")
    }
    @State private var boxIndex = 0
    @State private var adding = false
    @State private var editingWallpaper = false
    @State private var importing = false
    @State private var showdown = false
    @State private var moving = false
    @State private var renaming = false
    @State private var boxName = ""
    private var theme: PassportTheme { PassportTheme(dark: scheme == .dark, game: "") }
    private var layout: StorageLayout { store.snapshot.storage(for: kind) }
    private var box: PCBox { layout.boxes[min(boxIndex, layout.boxes.count - 1)] }
    private var selection: RibbonPokemon? { store.snapshot.pokemon.first { $0.id == store.snapshot.selectedPokemonID(for: kind) } }
    private func pokemon(_ id: String?) -> RibbonPokemon? { store.snapshot.pokemon(for: kind).first { $0.id == id } }
    private var pokemonRoute: Binding<String?> {
        Binding(get: { store.snapshot.section(forPokemon: store.openPokemonID ?? "") == kind ? store.openPokemonID : nil }, set: { id in
            if id != nil || store.snapshot.section(forPokemon: store.openPokemonID ?? "") == kind { store.openPokemonID = id }
        })
    }
    private var teamRoute: Binding<String?> {
        Binding(get: {
            guard let team = store.snapshot.teams.first(where: { $0.id == store.openTeamID }) else { return nil }
            return store.snapshot.kind(of: team) == kind ? team.id : nil
        }, set: { id in
            if id != nil || store.snapshot.teams.first(where: { $0.id == store.openTeamID }).map({ store.snapshot.kind(of: $0) == kind }) == true { store.openTeamID = id }
        })
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    HStack {
                        Text(kind.title.uppercased()).font(PixelFont.font(29))
                        Spacer(minLength: 4)
                        Menu {
                            Button("Add Pokémon", systemImage: "plus.circle") { adding = true }
                            if kind == .ribbon {
                                Button("Import backup", systemImage: "square.and.arrow.down") { importing = true }
                                Button("Refresh demo", systemImage: "sparkles") { store.demo() }
                            } else { Button("Import Showdown team", systemImage: "doc.on.clipboard") { showdown = true } }
                            Button("New box", systemImage: "plus.square") {
                                store.editStorage(kind: kind) { $0.boxes.append(PCBox(name: String(format: "Box %02d", $0.boxes.count + 1))) }
                                boxIndex = layout.boxes.count - 1
                            }
                        } label: { Image(systemName: "plus").frame(width: 44, height: 44) }.buttonStyle(RetroAction())
                    }
                    HStack(spacing: 10) {
                        NavigationLink { RetroTeamsView(kind: kind) } label: { Label("Teams", systemImage: "person.3") }.frame(maxWidth: .infinity)
                        NavigationLink { WidgetStudioView(initialContent: kind == .showdown ? .showdownTeam : .pokemon, section: kind) } label: { Label("Widgets", systemImage: "rectangle.3.group") }.frame(maxWidth: .infinity)
                    }.buttonStyle(RetroAction())
                    if store.snapshot.pokemon(for: kind).isEmpty { emptyCollection }
                    VStack(spacing: 0) {
                        boxHeader
                        HStack(alignment: .top, spacing: 7) {
                            if partyVisible { partyBar }
                            boxGrid
                        }.padding(7).background { BoxWallpaperView(settings: layout.wallpaper(for: box)) }.overlay(Rectangle().stroke(theme.border, lineWidth: 2))
                    }
                    HStack {
                        Text("\(box.slots.compactMap { $0 }.count) / 30")
                        Spacer()
                        Button("Wallpaper") { editingWallpaper = true }.foregroundStyle(theme.accent)
                        Spacer()
                        Text("Box \(min(boxIndex + 1, layout.boxes.count)) / \(layout.boxes.count)")
                    }.font(PixelFont.font(13)).foregroundStyle(theme.muted)
                    if let p = selection { selectionStrip(p) }
                    if selection != nil {
                        HStack(spacing: 9) {
                            Button(moving ? "Cancel move" : "Move") { moving.toggle() }
                                .frame(maxWidth: .infinity).disabled(selection == nil)
                            Button("Add to party") {
                                guard let p = selection else { return }
                                if layout.partyIDs.count >= 6 { store.error = "The party already has six Pokémon."; return }
                                store.editStorage(kind: kind) { _ = $0.moveToParty(p.id) }; partyVisible = true
                            }.frame(maxWidth: .infinity).disabled(selection == nil || layout.partyIDs.contains(selection?.id ?? ""))
                        }.buttonStyle(RetroAction())
                    }
                    if moving { Text("Select a destination slot").font(PixelFont.font(14)).foregroundStyle(theme.accent) }
                }.padding(16)
            }.background(theme.paper).toolbar(.hidden, for: .navigationBar)
                .navigationDestination(item: pokemonRoute) { id in
                    if let p = pokemon(id), p.showdownSet != nil { CompetitiveBuildView(pokemonID: id) }
                    else { StampAlbumView(pokemonID: id) }
                }
                .navigationDestination(item: teamRoute) { id in RetroTeamDetailView(teamID: id) }
                .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                    switch result { case .success(let url): store.importBackup(url); case .failure(let e): store.error = e.localizedDescription }
                }
                .sheet(isPresented: $adding) { AddPokemonView(boxID: box.id, kind: kind) { id in
                    if let index = layout.boxes.firstIndex(where: { $0.slots.contains(id) }) { boxIndex = index }
                } }
                .sheet(isPresented: $editingWallpaper) { BoxWallpaperEditor(box: box, settings: layout.wallpaper(for: box), kind: kind) }
                .sheet(isPresented: $showdown) { RetroShowdownImportView() }
                .alert("Box name", isPresented: $renaming) {
                    TextField("Name", text: $boxName)
                    Button("Save") {
                        let id = box.id, name = boxName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        store.editStorage(kind: kind) { l in if let i = l.boxes.firstIndex(where: { $0.id == id }) { l.boxes[i].name = name } }
                    }
                    Button("Cancel", role: .cancel) { }
                }
        }
    }
    private var emptyCollection: some View {
        VStack(spacing: 10) {
            Text("No Pokémon").font(PixelFont.font(22))
            Button("Add Pokémon") { adding = true }
        }.buttonStyle(RetroAction()).frame(maxWidth: .infinity).retroPanel()
    }
    private var boxHeader: some View {
        HStack(spacing: 5) {
            Button { boxIndex = (boxIndex + layout.boxes.count - 1) % layout.boxes.count } label: { Image(systemName: "chevron.left").frame(width: 33, height: 44) }
                .accessibilityLabel("Previous box")
            Button { boxName = box.name; renaming = true } label: {
                Text(box.name.uppercased()).font(PixelFont.font(17)).lineLimit(1).minimumScaleFactor(0.65).frame(maxWidth: .infinity)
            }.accessibilityLabel("Rename \(box.name)")
            Button { withAnimation(.easeInOut(duration: 0.2)) { partyVisible.toggle() } } label: {
                Label("Party", systemImage: "person.2").font(PixelFont.font(13)).padding(.horizontal, 8).frame(minHeight: 38)
                    .background(partyVisible ? theme.board : theme.panel).foregroundStyle(theme.ink)
            }.accessibilityIdentifier("pc.partyToggle").accessibilityValue(partyVisible ? "Shown" : "Hidden")
            Button { boxIndex = (boxIndex + 1) % layout.boxes.count } label: { Image(systemName: "chevron.right").frame(width: 33, height: 44) }
                .accessibilityLabel("Next box")
        }.buttonStyle(.plain).padding(.horizontal, 3).padding(.vertical, 5).background(theme.ink).foregroundStyle(theme.paper)
    }
    private var boxGrid: some View {
        GeometryReader { geometry in
            let columns = max(1, min(6, Int(geometry.size.width / 44)))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: columns), spacing: 4) {
                ForEach(0..<30, id: \.self) { slot in
                    let p = pokemon(box.slots[slot])
                    Button {
                        if moving, let id = selection?.id { move(id, slot: slot) }
                        else if let p { store.choose(p.id) }
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            if let p {
                                PokemonSprite(pokemon: p, download: true).padding(3)
                                if p.shiny { AssetImage(key: "shiny-" + theme.appearance).frame(width: 10, height: 10).padding(2) }
                            } else { Rectangle().fill(theme.border.opacity(0.5)).frame(width: 4, height: 4).frame(maxWidth: .infinity, maxHeight: .infinity) }
                        }.frame(height: 49).frame(maxWidth: .infinity)
                            .background(p?.id == selection?.id && p != nil ? theme.panel.opacity(0.65) : .clear)
                            .overlay(Rectangle().stroke(p?.id == selection?.id && p != nil ? theme.accent : .clear, lineWidth: 2))
                    }.buttonStyle(.plain).accessibilityLabel(p?.displayName ?? "Empty slot \(slot + 1)")
                        .contextMenu { if let p { pokemonMenu(p) } }
                        .draggable(p?.id ?? "")
                        .dropDestination(for: String.self) { ids, _ in
                            guard let id = ids.first, pokemon(id) != nil else { return false }; move(id, slot: slot); return true
                        }
                }
            }
        }.frame(height: partyVisible ? 370 : 290)
    }
    private var partyBar: some View {
        VStack(spacing: 7) {
            Text("PARTY").font(PixelFont.font(10))
            ForEach(0..<6, id: \.self) { i in
                let p = i < layout.partyIDs.count ? pokemon(layout.partyIDs[i]) : nil
                Button {
                    if let p { store.choose(p.id) }
                    else if let id = selection?.id { store.editStorage(kind: kind) { _ = $0.moveToParty(id) } }
                } label: {
                    Group {
                        if let p { PokemonSprite(pokemon: p, download: true) }
                        else { Text("·").foregroundStyle(theme.muted) }
                    }.frame(width: 39, height: 43).background(theme.board)
                        .overlay(Rectangle().stroke(theme.border, style: StrokeStyle(lineWidth: 1, dash: [2])))
                }.buttonStyle(.plain).accessibilityLabel(p?.displayName ?? "Empty party slot")
                    .contextMenu { if let p { Button("Return to box") { store.editStorage(kind: kind) { $0.returnToBox(p.id) } }; pokemonMenu(p) } }
                    .draggable(p?.id ?? "")
                    .dropDestination(for: String.self) { ids, _ in
                        guard let id = ids.first, pokemon(id) != nil, layout.partyIDs.count < 6 else { return false }
                        store.editStorage(kind: kind) { _ = $0.moveToParty(id) }; return true
                    }
            }
        }.padding(5).background(theme.panel).overlay(Rectangle().stroke(theme.border, lineWidth: 1))
    }
    @ViewBuilder private func pokemonMenu(_ p: RibbonPokemon) -> some View {
        Button(kind == .ribbon ? "Open passport" : "Open build") { store.openPokemonID = p.id }
        Button("Add to party") { store.editStorage(kind: kind) { _ = $0.moveToParty(p.id) }; partyVisible = true }
            .disabled(layout.partyIDs.count >= 6 || layout.partyIDs.contains(p.id))
        Button("Delete", role: .destructive) { store.deletePokemon(p.id) }
    }
    private func selectionStrip(_ p: RibbonPokemon) -> some View {
        HStack(spacing: 9) {
            PokemonSprite(pokemon: p, download: true).frame(width: 42, height: 42)
            VStack(alignment: .leading, spacing: 3) {
                PokemonName(pokemon: p, theme: theme)
                HStack(spacing: 4) {
                    GameMascot(game: p.currentgame)
                    Text("Lv. \(p.currentlevel) · \(RibbonCatalog.shared.compactGameName(p.currentgame))")
                        .font(PixelFont.font(12)).lineLimit(1).minimumScaleFactor(0.75).foregroundStyle(theme.muted)
                }
            }
            Button(kind == .ribbon ? "Passport ▸" : "Build ▸") { store.openPokemonID = p.id }.font(PixelFont.font(13)).buttonStyle(.plain)
        }.retroPanel(padding: 9)
    }
    private func move(_ id: String, slot: Int) {
        let boxID = box.id
        store.editStorage(kind: kind) { _ = $0.move(id, toBox: boxID, slot: slot) }; moving = false
    }
}

struct AwardLocationSelection: Identifiable { var id: String }
struct StampAlbumView: View {
    var pokemonID: String
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @State private var generation = 0
    @State private var editing = false
    @State private var editingVisits = false
    @State private var selectedAward: AwardLocationSelection?
    private var p: RibbonPokemon? { store.snapshot.pokemon.first { $0.id == pokemonID } }
    private var theme: PassportTheme { PassportTheme(dark: scheme == .dark, game: p?.currentgame ?? "") }
    var body: some View {
        ScrollView {
            if let p {
                let active = p.visitedGenerations.contains(generation) ? generation : p.visitedGenerations.first ?? 0
                VStack(spacing: 16) {
                    HStack(spacing: 10) {
                        PokemonSprite(pokemon: p, download: true).frame(width: 94, height: 90)
                        VStack(alignment: .leading, spacing: 7) {
                            PokemonName(pokemon: p, theme: theme, size: 26)
                            EquippedTitleLabel(pokemon: p, theme: theme).font(PixelFont.font(15))
                            Text("Lv. \(p.currentlevel) · \(RibbonCatalog.shared.awards(for: p).count) awards").font(PixelFont.font(14)).foregroundStyle(theme.muted)
                        }
                    }.retroPanel()
                    HStack(alignment: .top, spacing: 10) {
                        endpoint("ORIGIN", game: p.origingame)
                        endpoint("CURRENT", game: p.currentgame)
                    }.retroPanel()
                    RetroHeading(title: "Stamp album", value: "\(p.visitedGenerations.count) generations")
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 9) {
                        ForEach(p.visitedGenerations, id: \.self) { gen in
                            let games = p.games(in: gen)
                            let representative = games.contains(p.currentgame) ? p.currentgame : games.first ?? ""
                            Button { generation = gen } label: {
                                VStack(spacing: 5) {
                                    Text("GEN \(gen.roman)").font(PixelFont.font(12))
                                    GameMascot(game: representative, size: representative == "scar" ? 42 : 52).frame(height: 54)
                                    Text("\(games.count) \(games.count == 1 ? "game" : "games")").font(PixelFont.font(14))
                                    Text("\(p.awards(earnedIn: gen).count) earned").font(PixelFont.font(12)).foregroundStyle(theme.muted)
                                }.frame(maxWidth: .infinity).padding(.vertical, 10).padding(.horizontal, 3)
                                    .background(gen == active ? theme.board : theme.panel)
                                    .overlay(Rectangle().strokeBorder(theme.border, style: StrokeStyle(lineWidth: gen == active ? 2 : 1, dash: gen == active ? [] : [3])))
                            }.buttonStyle(.plain).accessibilityIdentifier("album.generation.\(gen)")
                        }
                    }
                    if active > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            RetroHeading(title: "Generation \(active.roman)", value: "\(p.awards(earnedIn: active).count) earned")
                            ForEach(p.games(in: active), id: \.self) { game in
                                HStack(spacing: 8) {
                                    GameMascot(game: game, size: 25)
                                    Text(RibbonCatalog.shared.gameName(game)).font(PixelFont.font(16)).fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 3)
                                    if game == p.origingame || game == p.currentgame {
                                        Text(game == p.origingame && game == p.currentgame ? "Origin · Current" : game == p.origingame ? "Origin" : "Current")
                                            .font(PixelFont.font(12)).foregroundStyle(theme.accent).fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            Divider()
                            if p.awards(earnedIn: active).isEmpty { Text("No ribbons assigned").font(PixelFont.font(15)).foregroundStyle(theme.muted) }
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 6), spacing: 8) {
                                ForEach(p.awards(earnedIn: active), id: \.self) { id in
                                    Button { selectedAward = AwardLocationSelection(id: id) } label: {
                                        AssetImage(key: "award-" + id).frame(height: 34).padding(4).frame(maxWidth: .infinity).background(theme.board)
                                    }.buttonStyle(.plain).accessibilityLabel(RibbonCatalog.shared.ribbons[id] ?? id)
                                }
                            }
                            Button("Assign / move a ribbon") { selectedAward = AwardLocationSelection(id: p.ribbons.first ?? "") }
                                .buttonStyle(RetroAction(prominent: true)).disabled(p.ribbons.isEmpty)
                        }.retroPanel()
                    }
                    let unspecified = p.ribbons.filter { p.earnedGenerations?[$0] == nil }.count
                    RetroHeading(title: "Original awards", value: "\(p.ribbons.count) · \(unspecified) unassigned")
                    if !p.ribbons.isEmpty {
                        Text("Memory Ribbons combine older awards in the current game.").font(PixelFont.font(13)).foregroundStyle(theme.muted)
                    }
                    HStack {
                        Button("Edit visits") { editingVisits = true }
                        Button("Edit Pokémon") { editing = true }
                    }.buttonStyle(RetroAction())
                }.padding(16)
            } else { ContentUnavailableView("Pokémon removed", systemImage: "tray") }
        }.background(theme.paper).navigationTitle("Passport").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
            .toolbar { Button("Edit") { editing = true }.disabled(p == nil) }
            .sheet(isPresented: $editing) { if let p { NavigationStack { PokemonEditor(pokemon: p) }.font(PixelFont.font(16)) } }
            .sheet(isPresented: $editingVisits) { JourneyEditorView(pokemonID: pokemonID) }
            .sheet(item: $selectedAward) { choice in AwardLocationEditor(pokemonID: pokemonID, initialAward: choice.id) }
    }
    private func endpoint(_ title: String, game: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(PixelFont.font(12)).foregroundStyle(theme.muted)
            HStack(alignment: .center, spacing: 6) {
                if !game.isEmpty { GameMascot(game: game, size: 27) }
                Text(RibbonCatalog.shared.gameName(game)).font(PixelFont.font(16)).fixedSize(horizontal: false, vertical: true)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).accessibilityElement(children: .combine)
    }
}

struct AwardLocationEditor: View {
    var pokemonID: String
    var initialAward: String
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var award = ""
    @State private var generation = 0
    private var p: RibbonPokemon? { store.snapshot.pokemon.first { $0.id == pokemonID } }
    var body: some View {
        NavigationStack {
            Form {
                if let p {
                    SearchableChoicePicker(title: "Ribbon", value: $award, choices: RibbonCatalog.shared.awardChoices(p.ribbons)).onChange(of: award) { _, id in generation = p.earnedGenerations?[id] ?? 0 }
                    if !award.isEmpty { AssetImage(key: "award-" + award).frame(height: 64).frame(maxWidth: .infinity) }
                    Picker("Earned in", selection: $generation) {
                        Text("Not specified").tag(0)
                        ForEach(p.visitedGenerations, id: \.self) { gen in Text("Generation \(gen.roman)").tag(gen) }
                    }
                }
            }.navigationTitle("Ribbon location").font(PixelFont.font(17))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if var p { p.assignAward(award, generation: generation == 0 ? nil : generation); store.update(p) }
                            if store.error == nil { dismiss() }
                        }.disabled(award.isEmpty)
                    }
                }
                .onAppear { award = initialAward; generation = p?.earnedGenerations?[initialAward] ?? 0 }
        }
    }
}

struct JourneyEditorView: View {
    var pokemonID: String
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var game = ""
    private var p: RibbonPokemon? { store.snapshot.pokemon.first { $0.id == pokemonID } }
    var body: some View {
        NavigationStack {
            List {
                if let p {
                    Section("Recorded visits") {
                        ForEach(p.recordedVisits) { visit in
                            HStack {
                                GameMascot(game: visit.game, size: 30)
                                Text(RibbonCatalog.shared.gameName(visit.game))
                                Spacer()
                                Text("Gen \(visit.generation.roman)").foregroundStyle(.secondary)
                            }.deleteDisabled(visit.game == p.origingame || visit.game == p.currentgame)
                        }.onDelete { indices in
                            var next = p
                            let games = indices.map { p.recordedVisits[$0].game }.filter { $0 != p.origingame && $0 != p.currentgame }
                            next.visits = next.recordedVisits.filter { !games.contains($0.game) }
                            let remaining = Set(next.recordedVisits.map(\.generation))
                            next.earnedGenerations = next.earnedGenerations?.filter { remaining.contains($0.value) }
                            store.update(next)
                        }
                    }
                    Section("Add visit") {
                        GamePicker(title: "Game", value: $game)
                        Button("Add visit") {
                            guard !game.isEmpty else { return }
                            var next = p; var visits = next.recordedVisits
                            if !visits.contains(where: { $0.game == game }) { visits.append(JourneyVisit(game: game)) }
                            next.visits = visits; store.update(next); game = ""
                        }.disabled(game.isEmpty || p.recordedVisits.contains { $0.game == game })
                    }
                }
            }.navigationTitle("Visits").font(PixelFont.font(17)).toolbar { Button("Done") { dismiss() } }
        }
    }
}
