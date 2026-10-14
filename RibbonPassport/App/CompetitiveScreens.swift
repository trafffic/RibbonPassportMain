import SwiftUI
import WidgetKit

struct RetroTeamsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @State private var showdown = false
    @State private var creating = false
    @State private var filter = "Showdown"
    private var kind: TeamKind { filter == "Showdown" ? .showdown : .ribbon }
    private var theme: PassportTheme { PassportTheme(dark: scheme == .dark, game: "") }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text("Teams").font(PixelFont.font(31))
                        Spacer()
                        Menu {
                            Button("Import Showdown team") { showdown = true }
                            Button("Create ribbon team") { creating = true }
                        } label: { Label("Add", systemImage: "plus") }.buttonStyle(RetroAction())
                    }
                    Picker("Teams", selection: $filter) { Text("Showdown").tag("Showdown"); Text("Ribbon teams").tag("Ribbons") }
                        .pickerStyle(.segmented)
                    if store.snapshot.teams(for: kind).isEmpty {
                        VStack(spacing: 12) {
                            Text("No teams").font(PixelFont.font(22))
                            Button(filter == "Showdown" ? "Import team" : "Create team") { if filter == "Showdown" { showdown = true } else { creating = true } }
                                .buttonStyle(RetroAction(prominent: true))
                        }.frame(maxWidth: .infinity).retroPanel()
                    }
                    ForEach(store.snapshot.teams(for: kind)) { team in
                        NavigationLink { RetroTeamDetailView(teamID: team.id) } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(team.name).font(PixelFont.font(24)).lineLimit(1)
                                    Spacer()
                                    if team.id == store.snapshot.selectedTeamID { Image(systemName: "checkmark.circle.fill").foregroundStyle(theme.accent) }
                                    Text("\(team.memberIDs.count)").font(PixelFont.font(14)).foregroundStyle(theme.muted)
                                    Image(systemName: "chevron.right").font(.system(size: 12))
                                }
                                HStack(spacing: 3) {
                                    ForEach(store.snapshot.members(teamID: team.id).prefix(6)) { p in PokemonSprite(pokemon: p, download: true).frame(maxWidth: .infinity).frame(height: 48) }
                                }
                            }.frame(maxWidth: .infinity, alignment: .leading).retroPanel()
                        }.buttonStyle(.plain)
                    }
                }.padding(16)
            }.background(theme.paper).toolbar(.hidden, for: .navigationBar)
                .navigationDestination(item: $store.openTeamID) { id in RetroTeamDetailView(teamID: id) }
                .sheet(isPresented: $showdown) { RetroShowdownImportView() }
                .sheet(isPresented: $creating) { NavigationStack { RetroTeamArrangeView(team: RibbonTeam(name: "Ribbon team", memberIDs: []), showdown: false) } }
        }
    }
}

struct RetroTeamDetailView: View {
    var teamID: String
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    private var team: RibbonTeam? { store.snapshot.teams.first { $0.id == teamID } }
    private var members: [RibbonPokemon] { store.snapshot.members(teamID: teamID) }
    private var theme: PassportTheme { PassportTheme(dark: scheme == .dark, game: "") }
    var body: some View {
        ScrollView {
            if let team {
                let showdown = store.snapshot.kind(of: team) == .showdown
                VStack(alignment: .leading, spacing: 16) {
                    Text(team.name).font(PixelFont.font(31))
                    HStack {
                        Text("\(members.count) Pokémon").font(PixelFont.font(14)).foregroundStyle(theme.muted)
                        Spacer()
                        NavigationLink("Widget") { WidgetStudioView(initialContent: showdown ? .showdownTeam : .ribbonTeam, initialSelection: team.id) }
                    }
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(members) { p in
                            NavigationLink {
                                if showdown { CompetitiveBuildView(pokemonID: p.id) } else { StampAlbumView(pokemonID: p.id) }
                            } label: {
                                VStack(alignment: .leading, spacing: 7) {
                                    PokemonName(pokemon: p, theme: theme, size: 19)
                                    PokemonSprite(pokemon: p, download: true).frame(height: 76).frame(maxWidth: .infinity)
                                    if let b = p.showdownSet {
                                        HeldItemLabel(item: b.item, theme: theme).font(PixelFont.font(14))
                                        Text(b.ability).font(PixelFont.font(13)).lineLimit(2).foregroundStyle(theme.muted)
                                        Text(b.teraType.isEmpty ? "Tera not set" : "Tera · \(b.teraType)").font(PixelFont.font(12)).foregroundStyle(theme.accent)
                                    } else {
                                        EquippedTitleLabel(pokemon: p, theme: theme).font(PixelFont.font(13))
                                        Text("\(RibbonCatalog.shared.awards(for: p).count) awards").font(PixelFont.font(13)).foregroundStyle(theme.muted)
                                    }
                                }.frame(maxWidth: .infinity, alignment: .leading).retroPanel(padding: 10)
                            }.buttonStyle(.plain)
                        }
                    }
                    Button("Use as default team") { store.chooseTeam(team.id) }.buttonStyle(RetroAction())
                    Button("Delete team", role: .destructive) { confirmDelete = true }.font(PixelFont.font(14)).padding(.top, 9)
                }.padding(16)
            } else { ContentUnavailableView("Team removed", systemImage: "person.3") }
        }.background(theme.paper).navigationTitle("Team").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
            .toolbar {
                if let team {
                    NavigationLink("Edit") { RetroTeamArrangeView(team: team, showdown: store.snapshot.kind(of: team) == .showdown) }
                    if store.snapshot.kind(of: team) == .showdown { ShareLink(item: ShowdownExporter.export(members)) { Image(systemName: "square.and.arrow.up") } }
                }
            }
            .confirmationDialog("Delete this team?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete team", role: .destructive) {
                    var next = store.snapshot; next.teams.removeAll { $0.id == teamID }
                    if next.selectedTeamID == teamID { next.selectedTeamID = next.teams.first?.id ?? "" }
                    store.commit(next); if store.error == nil { dismiss() }
                }
            }
    }
}

struct CompetitiveBuildView: View {
    var pokemonID: String
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @State private var editing = false
    private var p: RibbonPokemon? { store.snapshot.pokemon.first { $0.id == pokemonID } }
    private var theme: PassportTheme { PassportTheme(dark: scheme == .dark, game: p?.currentgame ?? "") }
    var body: some View {
        ScrollView {
            if let p, let b = p.showdownSet {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        PokemonSprite(pokemon: p, download: true).frame(width: 104, height: 100)
                        VStack(alignment: .leading, spacing: 8) {
                            PokemonName(pokemon: p, theme: theme, size: 27)
                            Text("\(RibbonCatalog.shared.pokemon[p.species]?.name ?? p.species) · Lv. \(p.currentlevel)").font(PixelFont.font(13)).foregroundStyle(theme.muted)
                            HeldItemLabel(item: b.item, theme: theme).font(PixelFont.font(16))
                        }
                    }.retroPanel()
                    VStack(spacing: 10) {
                        buildField("Ability", b.ability)
                        Divider()
                        buildField("Nature", b.nature)
                        Divider()
                        buildField("Tera type", b.teraType)
                    }.retroPanel()
                    RetroHeading(title: "Moves", value: "\(b.moves.count) / 4")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Array(b.moves.enumerated()), id: \.offset) { _, move in
                            Text(move).font(PixelFont.font(16)).fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading).frame(minHeight: 44).retroPanel(padding: 9)
                        }
                    }
                    RetroHeading(title: "Stats")
                    VStack(spacing: 0) {
                        HStack { Text("").frame(maxWidth: .infinity); Text("EV").frame(width: 44); Text("IV").frame(width: 44) }
                            .font(PixelFont.font(13)).foregroundStyle(theme.muted).padding(8).background(theme.board)
                        ForEach(Array(ShowdownStats.labels.enumerated()), id: \.offset) { i, label in
                            HStack {
                                Text(label).frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(ShowdownStats.values(b.evs, fallback: 0)[i])").frame(width: 44)
                                Text("\(ShowdownStats.values(b.ivs, fallback: 31)[i])").frame(width: 44)
                            }.font(PixelFont.font(16)).padding(9)
                            if i < 5 { Divider() }
                        }
                    }.retroPanel(padding: 0)
                }.padding(16)
            } else { ContentUnavailableView("Build unavailable", systemImage: "tray") }
        }.background(theme.paper).navigationTitle("Build").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
            .toolbar { Button("Edit") { editing = true }.disabled(p?.showdownSet == nil) }
            .sheet(isPresented: $editing) { if let p { CompetitiveBuildEditor(pokemon: p) } }
    }
    private func buildField(_ name: String, _ value: String) -> some View {
        HStack { Text(name).font(PixelFont.font(13)).foregroundStyle(theme.muted); Spacer(); Text(value.isEmpty ? "Not set" : value).font(PixelFont.font(17)) }
    }
}

struct CompetitiveBuildEditor: View {
    var pokemon: RibbonPokemon
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var build: ShowdownSet
    @State private var level: Int
    @State private var nickname: String
    init(pokemon: RibbonPokemon) {
        self.pokemon = pokemon; _build = State(initialValue: pokemon.showdownSet ?? ShowdownSet())
        _level = State(initialValue: pokemon.currentlevel); _nickname = State(initialValue: pokemon.nickname)
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("Pokémon") { TextField("Nickname", text: $nickname); Stepper("Level \(level)", value: $level, in: 1...100) }
                Section("Build") {
                    TextField("Held item", text: $build.item)
                    TextField("Ability", text: $build.ability)
                    TextField("Nature", text: $build.nature)
                    TextField("Tera type", text: $build.teraType)
                    TextField("EVs", text: $build.evs)
                    TextField("IVs", text: $build.ivs)
                }
                Section("Moves") {
                    ForEach(0..<4, id: \.self) { i in
                        TextField("Move \(i + 1)", text: Binding(get: { i < build.moves.count ? build.moves[i] : "" }, set: { value in
                            while build.moves.count <= i { build.moves.append("") }; build.moves[i] = value
                        }))
                    }
                }
            }.font(PixelFont.font(17)).navigationTitle("Edit build")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") {
                        guard var next = store.snapshot.pokemon.first(where: { $0.id == pokemon.id }) else { dismiss(); return }
                        build.moves = build.moves.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                        next.showdownSet = build; next.currentlevel = level; next.nickname = nickname; store.update(next)
                        if store.error == nil { dismiss() }
                    } }
                }
        }
    }
}

struct RetroTeamArrangeView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State var team: RibbonTeam
    var showdown: Bool
    @State private var adding = false
    private var theme: PassportTheme { PassportTheme(dark: scheme == .dark, game: "") }
    private var members: [RibbonPokemon] { team.memberIDs.compactMap { id in store.snapshot.pokemon.first { $0.id == id } } }
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Team name").font(PixelFont.font(13)).foregroundStyle(theme.muted)
                    TextField("Team name", text: $team.name).font(PixelFont.font(20)).textFieldStyle(.roundedBorder)
                }
                RetroHeading(title: "Display order", value: "\(members.count) / 6")
                ForEach(Array(members.enumerated()), id: \.element.id) { i, p in
                    HStack(spacing: 8) {
                        Text("\(i + 1)").font(PixelFont.font(13)).foregroundStyle(theme.muted)
                        PokemonSprite(pokemon: p, download: true).frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(p.displayName).font(PixelFont.font(18)).lineLimit(1)
                            if let b = p.showdownSet { HeldItemLabel(item: b.item, theme: theme).font(PixelFont.font(12)) }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        Button { move(i, -1) } label: { Image(systemName: "chevron.up").frame(width: 27, height: 44) }.disabled(i == 0).accessibilityLabel("Move \(p.displayName) up")
                        Button { move(i, 1) } label: { Image(systemName: "chevron.down").frame(width: 27, height: 44) }.disabled(i == members.count - 1).accessibilityLabel("Move \(p.displayName) down")
                    }.buttonStyle(.plain).retroPanel(padding: 8)
                        .contextMenu { Button("Remove", role: .destructive) { team.memberIDs.removeAll { $0 == p.id } } }
                }
                Button("Choose members") { adding = true }.buttonStyle(RetroAction())
                Button("Save team") { save() }.buttonStyle(RetroAction(prominent: true)).disabled(!canSave)
            }.padding(16)
        }.background(theme.paper).navigationTitle("Edit team").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
            .toolbar { Button("Save") { save() }.disabled(!canSave) }
            .sheet(isPresented: $adding) {
                NavigationStack {
                    List {
                        ForEach(store.snapshot.pokemon.filter { ($0.showdownSet != nil) == showdown }) { p in
                            Button {
                                if team.memberIDs.contains(p.id) { team.memberIDs.removeAll { $0 == p.id } }
                                else if team.memberIDs.count < 6 { team.memberIDs.append(p.id) }
                            } label: {
                                HStack { PokemonRow(pokemon: p); if let i = team.memberIDs.firstIndex(of: p.id) { Text("\(i + 1)") } }
                            }.disabled(!team.memberIDs.contains(p.id) && team.memberIDs.count >= 6)
                        }
                    }.font(PixelFont.font(17)).navigationTitle("Members").toolbar { Button("Done") { adding = false } }
                }
            }
    }
    private var canSave: Bool { !team.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !members.isEmpty }
    private func move(_ i: Int, _ delta: Int) {
        guard team.memberIDs.indices.contains(i + delta) else { return }; team.memberIDs.swapAt(i, i + delta)
    }
    private func save() { team.memberIDs = members.map(\.id); store.saveTeam(team); if store.error == nil { dismiss() } }
}

struct RetroShowdownImportView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var name = "Showdown Team"
    @State private var export = ""
    @State private var origin = ""
    @State private var current = ""
    @State private var error = ""
    var body: some View {
        let theme = PassportTheme(dark: scheme == .dark, game: "")
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Showdown import").font(PixelFont.font(29))
                    Text("Team name").font(PixelFont.font(14))
                    TextField("Team name", text: $name).textFieldStyle(.roundedBorder)
                    Text("Showdown export").font(PixelFont.font(14))
                    TextEditor(text: $export).font(PixelFont.font(15)).frame(minHeight: 300).padding(7)
                        .scrollContentBackground(.hidden).background(theme.panel).overlay(Rectangle().stroke(theme.border, lineWidth: 1))
                        .autocorrectionDisabled().textInputAutocapitalization(.never).accessibilityIdentifier("showdown.export")
                    HStack {
                        PasteButton(payloadType: String.self) { values in if let text = values.first { export = text } }
                        Spacer()
                        Button("Example") { export = ShowdownExporter.export(SharedStore.showdownPreview().pokemon) }
                        Text("1–6 Pokémon").font(PixelFont.font(12)).foregroundStyle(theme.muted)
                    }
                    DisclosureGroup("Games") { GamePicker(title: "Origin", value: $origin); GamePicker(title: "Current", value: $current) }
                    if !error.isEmpty { Text(error).font(PixelFont.font(14)).foregroundStyle(.red).accessibilityAddTraits(.updatesFrequently) }
                    Button("Import team") {
                        do {
                            try store.addShowdown(export, name: name, current: current, origin: origin)
                            if store.error == nil { dismiss(); store.tab = 1; store.openTeamID = store.snapshot.selectedTeamID }
                        } catch { self.error = error.localizedDescription }
                    }.buttonStyle(RetroAction(prominent: true)).disabled(export.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }.font(PixelFont.font(17)).padding(16)
            }.background(theme.paper).navigationTitle("Import team").navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Cancel") { dismiss() } }
        }
    }
}

enum ShowdownStats {
    static let labels = ["HP", "Attack", "Defense", "Sp. Atk", "Sp. Def", "Speed"]
    static func values(_ text: String, fallback: Int) -> [Int] {
        let keys = ["hp", "atk", "def", "spa", "spd", "spe"]
        var result = Array(repeating: fallback, count: 6)
        for chunk in text.split(separator: "/") {
            let parts = chunk.trimmingCharacters(in: .whitespaces).split(separator: " ", maxSplits: 1)
            if parts.count == 2, let value = Int(parts[0]), let i = keys.firstIndex(of: parts[1].lowercased()) { result[i] = value }
        }
        return result
    }
}
