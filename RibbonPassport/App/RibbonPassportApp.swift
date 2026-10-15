import SwiftUI
import WidgetKit
import UniformTypeIdentifiers

@MainActor
final class AppStore: ObservableObject {
    @Published var snapshot = CollectionSnapshot()
    @Published var error: String?
    @Published var notice: String?
    @Published var tab = 0
    @Published var openPokemonID: String?
    @Published var openTeamID: String?
    private let saveSnapshot: (CollectionSnapshot) throws -> Void
    private let refreshWidgets: Bool
    static var interactionTesting: Bool {
        #if DEBUG
        return ["1", "transfer", "recovery"].contains(ProcessInfo.processInfo.environment["RibbonPassportInteractionTest"] ?? "")
        #else
        return false
        #endif
    }
    var preferences: UserDefaults { Self.interactionTesting ? UserDefaults(suiteName: "RibbonPassport.InteractionTests")! : .standard }
    init(snapshot initial: CollectionSnapshot? = nil, save: @escaping (CollectionSnapshot) throws -> Void = SharedStore.save) {
        saveSnapshot = save
        refreshWidgets = initial == nil
        if var initial { initial.organizeSections(); snapshot = initial; return }
        #if DEBUG
        if Self.interactionTesting {
            preferences.removePersistentDomain(forName: "RibbonPassport.InteractionTests")
            preferences.set(true, forKey: "pc.ribbon.partyVisible")
            var a = RibbonPokemon(id: "drag-a", species: "metagross", currentgame: "bd", origingame: "diamond")
            if ProcessInfo.processInfo.environment["RibbonPassportInteractionTest"] == "transfer" {
                a.currentgame = "platinum"; a.origingame = "emerald"; a.metLevel = 5
                a.ribbons = RibbonRules.shared.ribbonIDs.filter {
                    (RibbonRules.shared.awards[$0]?.gen ?? 99) <= 4 &&
                    !["footprint-ribbon", "pair-ability-ribbon", "legend-ribbon"].contains($0)
                }
            }
            let b = RibbonPokemon(id: "drag-b", species: "rayquaza", currentgame: "bd", origingame: "ruby")
            let c = RibbonPokemon(id: "drag-c", species: "pikachu", currentgame: "sw", origingame: "sw")
            var first = PCBox(id: "drag-box-a", name: "Box 01"); first.slots[0] = a.id; first.slots[1] = b.id
            snapshot = CollectionSnapshot(pokemon: [a, b, c], selectedID: a.id, storage: StorageLayout(boxes: [first, PCBox(id: "drag-box-b", name: "Box 02")], partyIDs: [c.id]), selectedRibbonID: a.id)
            snapshot.organizeSections()
            if ProcessInfo.processInfo.environment["RibbonPassportInteractionTest"] == "recovery" {
                var edited = snapshot
                edited.pokemon[0].nickname = "Edited Metagross"
                edited.captureRecovery(from: snapshot)
                var deleted = edited
                deleted.removePokemon(id: b.id); deleted.organizeSections()
                deleted.captureRecovery(from: edited)
                snapshot = deleted
            }
            return
        }
        #endif
        reload()
    }
    func reload() {
        do { var loaded = try SharedStore.load(); loaded.organizeSections(); snapshot = loaded; error = nil }
        catch { self.error = error.localizedDescription }
    }
    func commit(_ value: CollectionSnapshot, recoveryAction: RecoveryAction = .edited) {
        do {
            var next = value; next.updatedAt = Date()
            next.organizeSections()
            next.captureRecovery(from: snapshot, action: recoveryAction)
            if Self.interactionTesting { snapshot = next; error = nil; return }
            try saveSnapshot(next); snapshot = next; error = nil
            if refreshWidgets { WidgetCenter.shared.reloadAllTimelines() }
        } catch { self.error = error.localizedDescription }
    }
    func choose(_ id: String) {
        var next = snapshot; next.selectedID = id
        if next.section(forPokemon: id) == .showdown { next.selectedCompetitiveID = id } else { next.selectedRibbonID = id }
        commit(next)
    }
    func chooseTeam(_ id: String) {
        var next = snapshot; next.selectedTeamID = id
        if let team = next.teams.first(where: { $0.id == id }), next.kind(of: team) == .showdown { next.selectedCompetitiveTeamID = id }
        else { next.selectedRibbonTeamID = id }
        commit(next)
    }
    func deletePokemon(_ id: String) {
        var next = snapshot; next.removePokemon(id: id); commit(next)
    }
    @discardableResult func restoreHistory(_ id: String) -> Bool {
        do {
            var next = snapshot
            try next.restoreRecoveryEntry(id)
            commit(next, recoveryAction: .restored)
            return error == nil
        } catch { self.error = error.localizedDescription; return false }
    }
    func update(_ pokemon: RibbonPokemon) {
        var next = snapshot
        guard let index = next.pokemon.firstIndex(where: { $0.id == pokemon.id }) else { return }
        var clean = pokemon
        clean.earnedGenerations = clean.earnedGenerations?.filter { clean.ribbons.contains($0.key) }
        clean.earnedGames = clean.earnedGames?.filter { clean.ribbons.contains($0.key) }
        next.pokemon[index] = clean; commit(next)
    }
    func importBackup(_ url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            var incoming = try BackupImporter.parse(Data(contentsOf: url))
            let existing = snapshot.pokemon.filter { $0.source == "ribbons.guide" }
            var used = Set<String>()
            for index in incoming.indices {
                let p = incoming[index]
                if let prior = existing.first(where: { !used.contains($0.id) && $0.species == p.species && $0.nickname == p.nickname && $0.origingame == p.origingame }) {
                    incoming[index].id = prior.id
                    incoming[index].visits = prior.visits
                    incoming[index].earnedGenerations = prior.earnedGenerations?.filter { incoming[index].ribbons.contains($0.key) }
                    incoming[index].earnedGames = prior.earnedGames?.filter { incoming[index].ribbons.contains($0.key) }
                    if incoming[index].metLevel == nil { incoming[index].metLevel = prior.metLevel }
                    used.insert(prior.id)
                } else { incoming[index].id = UUID().uuidString }
            }
            var next = snapshot
            next.pokemon = incoming + next.pokemon.filter { $0.source != "ribbons.guide" }
            if !next.pokemon.contains(where: { $0.id == next.selectedID }) { next.selectedID = next.pokemon.first?.id ?? "" }
            let valid = Set(next.pokemon.map(\.id))
            for index in next.teams.indices { next.teams[index].memberIDs.removeAll { !valid.contains($0) } }
            commit(next, recoveryAction: .imported)
            if error == nil { notice = "Imported \(incoming.count) Pokémon. Your Showdown teams have been kept." }
        } catch { self.error = error.localizedDescription }
    }
    func addShowdown(_ text: String, name: String, current: String, origin: String) throws {
        var pokemon = try ShowdownImporter.parse(text)
        for index in pokemon.indices { pokemon[index].currentgame = current; pokemon[index].origingame = origin }
        var next = snapshot
        let team = RibbonTeam(name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Showdown Team" : name, memberIDs: pokemon.map(\.id))
        next.pokemon.append(contentsOf: pokemon); next.teams.append(team)
        next.selectedTeamID = team.id; next.selectedCompetitiveTeamID = team.id; next.selectedCompetitiveID = pokemon.first?.id; next.selectedID = pokemon.first?.id ?? next.selectedID
        commit(next)
    }
    func saveTeam(_ team: RibbonTeam) {
        var next = snapshot
        if let index = next.teams.firstIndex(where: { $0.id == team.id }) { next.teams[index] = team }
        else { next.teams.append(team) }
        next.selectedTeamID = team.id
        if next.kind(of: team) == .showdown { next.selectedCompetitiveTeamID = team.id } else { next.selectedRibbonTeamID = team.id }
        commit(next)
    }
    func demo() {
        var next = snapshot
        next.replaceDemo(with: SharedStore.demo().pokemon); commit(next)
    }
}

@main
@MainActor
struct RibbonPassportApp: App {
    @StateObject private var store = AppStore()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store)
                .defaultAppStorage(store.preferences)
                .preferredColorScheme(store.snapshot.appearance == .automatic ? nil : store.snapshot.appearance == .dark ? .dark : .light)
                .onOpenURL { url in
                    if url.scheme == "ribbonpassport", url.host == "pokemon" {
                        store.choose(url.lastPathComponent)
                        store.tab = store.snapshot.section(forPokemon: url.lastPathComponent) == .showdown ? 1 : 0; store.openPokemonID = url.lastPathComponent
                    } else if url.scheme == "ribbonpassport", url.host == "team" {
                        store.chooseTeam(url.lastPathComponent)
                        store.tab = store.snapshot.teams.first(where: { $0.id == url.lastPathComponent }).map { store.snapshot.kind(of: $0) == .showdown ? 1 : 0 } ?? 0; store.openTeamID = url.lastPathComponent
                    } else if url.isFileURL { store.importBackup(url) }
                }
        }
    }
}
struct RootView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        TabView(selection: $store.tab) {
            PCStorageView(kind: .ribbon).tabItem { Label("Ribbons", systemImage: "rosette") }.tag(0)
            PCStorageView(kind: .showdown).tabItem { Label("Competitive", systemImage: "bolt.fill") }.tag(1)
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }.tag(2)
        }.font(PixelFont.font(17)).tint(Color(hex: "718F4E"))
        .alert("Something needs attention", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
            Button("OK") { store.error = nil }
        } message: { Text(store.error ?? "") }
        .alert("Collection updated", isPresented: Binding(get: { store.notice != nil }, set: { if !$0 { store.notice = nil } })) {
            Button("OK") { store.notice = nil }
        } message: { Text(store.notice ?? "") }
    }
}
struct CollectionView: View {
    @EnvironmentObject private var store: AppStore
    @State private var importing = false
    @State private var showdown = false
    @State private var search = ""
    var body: some View {
        NavigationStack {
            List {
                if store.snapshot.pokemon.isEmpty {
                    Section {
                        Text("Your ribbon journey").font(.title2.bold())
                        Text("Import a ribbons.guide backup, paste a Showdown team, or try the demo.").foregroundStyle(.secondary)
                        Button("Import ribbons.guide backup") { importing = true }
                        Button("Paste Showdown team") { showdown = true }
                        Button("Try demo Pokémon") { store.demo() }
                    }
                } else {
                    Section {
                        ForEach(store.snapshot.pokemon.filter { search.isEmpty || $0.displayName.localizedCaseInsensitiveContains(search) || $0.species.localizedCaseInsensitiveContains(search) }) { p in
                            NavigationLink { PokemonEditor(pokemon: p) } label: { PokemonRow(pokemon: p) }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) { store.deletePokemon(p.id) } label: { Label("Delete", systemImage: "trash") }
                                }
                        }
                    } header: { Text("\(store.snapshot.pokemon.count) Pokémon") }
                }
            }
            .navigationTitle("Ribbon Passport")
            .searchable(text: $search, prompt: "Find a Pokémon")
            .toolbar {
                Menu {
                    Button("Import backup", systemImage: "square.and.arrow.down") { importing = true }
                    Button("Paste Showdown team", systemImage: "doc.on.clipboard") { showdown = true }
                    Button("Add / refresh demo team", systemImage: "sparkles") { store.demo() }
                } label: { Image(systemName: "plus.circle") }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
                switch result { case .success(let urls): if let url = urls.first { store.importBackup(url) }; case .failure(let error): store.error = error.localizedDescription }
            }
            .sheet(isPresented: $showdown) { ShowdownImportView() }
        }
    }
}
struct PokemonRow: View {
    var pokemon: RibbonPokemon
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let theme = PassportTheme(dark: scheme == .dark, game: pokemon.currentgame)
        HStack(spacing: 12) {
            PokemonSprite(pokemon: pokemon, download: true).frame(width: 54, height: 48)
            VStack(alignment: .leading, spacing: 4) {
                PokemonName(pokemon: pokemon, theme: theme)
                if let build = pokemon.showdownSet {
                    HeldItemLabel(item: build.item, theme: theme).font(.caption)
                } else {
                    Text("\(RibbonCatalog.shared.awards(for: pokemon).count) ribbons · \(RibbonCatalog.shared.compactGameName(pokemon.currentgame))")
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            ConsoleIcon(pokemon: pokemon, theme: theme)
        }.padding(.vertical, 3)
    }
}
struct GamePicker: View {
    var title: String
    @Binding var value: String
    var body: some View {
        SearchableChoicePicker(title: title, value: $value, choices: RibbonCatalog.shared.gameChoices, emptyLabel: "Not set")
    }
}
struct PokemonEditor: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var pokemon: RibbonPokemon
    @State private var awards = false
    @State private var marks = false
    init(pokemon: RibbonPokemon) { _pokemon = State(initialValue: pokemon) }
    var body: some View {
        Form {
            Section {
                if pokemon.showdownSet != nil {
                    ShowdownTeamPassport(pokemon: [pokemon], name: "Showdown build", large: false, theme: PassportTheme(dark: scheme == .dark, game: pokemon.currentgame), download: true)
                        .frame(height: 180).listRowInsets(EdgeInsets())
                } else {
                    SinglePassport(pokemon: pokemon, size: .medium, theme: PassportTheme(dark: scheme == .dark, game: pokemon.currentgame), download: true)
                        .frame(height: 184).listRowInsets(EdgeInsets())
                }
                if pokemon.source == "demo", let note = SharedStore.demoFeature(for: pokemon.species) {
                    Label(note, systemImage: "sparkles").font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Pokémon") {
                Text(RibbonCatalog.shared.pokemon[pokemon.species]?.name ?? pokemon.species)
                TextField("Nickname", text: $pokemon.nickname)
                Stepper("Level \(pokemon.currentlevel)", value: $pokemon.currentlevel, in: 1...100)
                Toggle("Shiny", isOn: $pokemon.shiny)
                Picker("Gender", selection: $pokemon.gender) { Text("Not specified").tag(""); Text("Male").tag("male"); Text("Female").tag("female") }
                if RibbonRules.shared.species[pokemon.species]?.flags.contains(where: { ["colShadow", "xdShadow"].contains($0) }) == true { Toggle("Shadow Pokémon", isOn: $pokemon.shadow) }
                if RibbonCatalog.shared.gmaxSpecies.contains(pokemon.species) { Toggle("Gigantamax factor", isOn: $pokemon.gmax) }
            }
            Section("Journey") {
                GamePicker(title: "Current game", value: $pokemon.currentgame)
                GamePicker(title: "Origin game", value: $pokemon.origingame)
                RibbonMetLevelEditor(pokemon: $pokemon)
            }
            if let build = pokemon.showdownSet {
                Section("Showdown build") {
                    if !build.item.isEmpty {
                        LabeledContent { HeldItemLabel(item: build.item, theme: PassportTheme(dark: scheme == .dark, game: pokemon.currentgame)) } label: { Text("Held item") }
                    }
                    if !build.ability.isEmpty { LabeledContent("Ability", value: build.ability) }
                    if !build.nature.isEmpty { LabeledContent("Nature", value: build.nature) }
                    if !build.teraType.isEmpty { LabeledContent("Tera type", value: build.teraType) }
                    if !build.evs.isEmpty { LabeledContent("EVs", value: build.evs) }
                    if !build.ivs.isEmpty { LabeledContent("IVs", value: build.ivs) }
                    ForEach(Array(build.moves.enumerated()), id: \.offset) { _, move in Text(move) }
                }
            }
            Section("Ribbons and marks") {
                ManageRibbonsButton(pokemon: pokemon) { awards = true }
                Button("Edit marks (\(pokemon.ribbons.filter { $0.hasSuffix("-mark") }.count))") { marks = true }
                SearchableChoicePicker(title: "Equipped title", value: $pokemon.title,
                                       choices: RibbonCatalog.shared.awardChoices(pokemon.ribbons + (pokemon.title == "None" ? [] : [pokemon.title])), emptyLabel: "None", emptyID: "None").onChange(of: pokemon.title) { _, _ in pokemon.titleText = "" }
                Text("The displayed total includes marks and uses Memory Ribbons from Gen 6 onward.").font(.caption).foregroundStyle(.secondary)
            }
            Section {
                Button("Use for single-Pokémon widgets") { store.choose(pokemon.id) }
            }
        }.navigationTitle(pokemon.displayName).navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Save") { store.update(pokemon); dismiss() }.fontWeight(.semibold) }
            .sheet(isPresented: $awards) { RibbonManager(pokemon: $pokemon) { awards = false } }
            .sheet(isPresented: $marks) { AwardPicker(selection: $pokemon.ribbons) }
    }
}
struct AwardPicker: View {
    @Binding var selection: [String]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var search = ""
    private var matching: [String] {
        RibbonCatalog.shared.chronologicalAwards(Array(RibbonCatalog.shared.ribbons.keys)).filter { $0.hasSuffix("-mark") }.filter {
            search.isEmpty || RibbonCatalog.shared.awardPickerName($0).localizedCaseInsensitiveContains(search)
        }
    }
    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(Set(matching.map { CatalogOrder.awardGeneration($0) })).sorted(), id: \.self) { generation in
                    Section("Generation \(generation.roman)") {
                        ForEach(matching.filter { CatalogOrder.awardGeneration($0) == generation }, id: \.self) { id in
                            Button {
                                if selection.contains(id) { selection.removeAll { $0 == id } } else { selection.append(id) }
                            } label: {
                                HStack(spacing: 10) {
                                    AssetImage(key: "award-" + id).frame(width: 30, height: 30)
                                    Text(RibbonCatalog.shared.awardPickerName(id)).foregroundStyle(.primary)
                                    Spacer()
                                    if selection.contains(id) { Image(systemName: "checkmark.circle.fill") }
                                }
                            }
                        }
                    }
                }
            }.navigationTitle("Marks").searchable(text: $search)
                .toolbar { Button("Done") { dismiss() } }
        }
    }
}
struct TeamsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var create = false
    @State private var showdown = false
    var body: some View {
        NavigationStack {
            List {
                if store.snapshot.teams.isEmpty { Text("Create a team from your collection or paste one from Showdown.").foregroundStyle(.secondary) }
                ForEach(store.snapshot.teams) { team in
                    NavigationLink { TeamEditor(team: team) } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack { Text(team.name).font(.headline); if team.id == store.snapshot.selectedTeamID { Image(systemName: "checkmark.circle.fill") } }
                            Text("\(team.memberIDs.count) Pokémon").font(.caption).foregroundStyle(.secondary)
                            Text(store.snapshot.kind(of: team) == .showdown ? "Showdown widget · battle builds" : "Ribbon widget · top ribbons").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }.navigationTitle("Your teams")
                .toolbar { Menu { Button("Create team") { create = true }; Button("Paste Showdown team") { showdown = true } } label: { Image(systemName: "plus.circle") } }
                .sheet(isPresented: $create) { NavigationStack { TeamEditor(team: RibbonTeam(name: "My Ribbon Team", memberIDs: [])) } }
                .sheet(isPresented: $showdown) { ShowdownImportView() }
        }
    }
}
struct TeamEditor: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var team: RibbonTeam
    init(team: RibbonTeam) { _team = State(initialValue: team) }
    var body: some View {
        Form {
            Section {
                let pokemon = team.memberIDs.compactMap { id in store.snapshot.pokemon.first { $0.id == id } }
                if !pokemon.isEmpty && pokemon.allSatisfy({ $0.showdownSet != nil }) {
                    ShowdownTeamPassport(pokemon: Array(pokemon.prefix(3)), name: team.name, large: false, theme: PassportTheme(dark: scheme == .dark, game: pokemon.first?.currentgame ?? ""), download: true)
                        .frame(height: 180).listRowInsets(EdgeInsets())
                } else {
                    TeamPassport(pokemon: pokemon, name: team.name, large: false, theme: PassportTheme(dark: scheme == .dark, game: pokemon.first?.currentgame ?? ""), download: true)
                        .frame(height: 160).listRowInsets(EdgeInsets())
                }
                TextField("Team name", text: $team.name)
            }
            Section("Choose up to six Pokémon · tap in display order") {
                ForEach(store.snapshot.pokemon) { p in
                    Button {
                        if team.memberIDs.contains(p.id) { team.memberIDs.removeAll { $0 == p.id } }
                        else if team.memberIDs.count < 6 { team.memberIDs.append(p.id) }
                    } label: {
                        HStack { PokemonRow(pokemon: p); if let index = team.memberIDs.firstIndex(of: p.id) { Text("\(index + 1)").font(.caption.bold()) } }
                    }.disabled(!team.memberIDs.contains(p.id) && team.memberIDs.count == 6)
                }
            }
            Section { Text("Medium widgets show the first three members. Large widgets show up to six. Saving makes this your default widget team.").font(.caption).foregroundStyle(.secondary) }
        }.navigationTitle("Edit team").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Save") { store.saveTeam(team); dismiss() }.disabled(team.memberIDs.isEmpty || team.name.trimmingCharacters(in: .whitespaces).isEmpty) }
    }
}
struct ShowdownImportView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = "Showdown Team"
    @State private var export = ""
    @State private var current = ""
    @State private var origin = ""
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Your team") { TextField("Team name", text: $name) }
                Section {
                    TextEditor(text: $export).font(.system(.caption, design: .monospaced)).frame(minHeight: 230).autocorrectionDisabled().textInputAutocapitalization(.never)
                    Text("In Pokémon Showdown, open Teambuilder → your team → Import/Export. Copy the text and paste it here.").font(.caption).foregroundStyle(.secondary)
                    Button("Insert example") { export = "Sparky (Pikachu) (F) @ Light Ball\nAbility: Static\nLevel: 50\nShiny: Yes\n- Thunderbolt\n- Volt Switch\n\nLugia @ Leftovers\nAbility: Multiscale\n- Aeroblast\n- Roost" }
                } header: { Text("Paste Showdown export · up to six Pokémon") }
                Section("Optional journey details for this team") {
                    GamePicker(title: "Current game", value: $current)
                    GamePicker(title: "Origin game", value: $origin)
                    Text("Showdown exports have no ribbons, marks or origin games. New Pokémon start with zero awards. You can edit each Pokémon after importing.").font(.caption).foregroundStyle(.secondary)
                }
                if let error { Section { Text(error).foregroundStyle(.red) } }
            }.navigationTitle("Import Showdown team").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Import") {
                            do { try store.addShowdown(export, name: name, current: current, origin: origin); if store.error == nil { dismiss() } }
                            catch { self.error = error.localizedDescription }
                        }.disabled(export.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
        }
    }
}
struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: Binding(get: { store.snapshot.appearance }, set: { value in var next = store.snapshot; next.appearance = value; store.commit(next) })) {
                        Text("Follow iPhone").tag(Appearance.automatic); Text("Light").tag(Appearance.light); Text("Dark").tag(Appearance.dark)
                    }
                }
                Section("Home Screen widgets") {
                    NavigationLink("Ribbon widgets") { WidgetStudioView(section: .ribbon) }
                    NavigationLink("Competitive widgets") { WidgetStudioView(initialContent: .showdownTeam, section: .showdown) }
                    Button("Refresh widgets") { WidgetCenter.shared.reloadAllTimelines() }
                }
                Section("Collection") {
                    NavigationLink { RecoveryHistoryView() } label: { Text("Recovery history").font(PixelFont.font(17)) }
                        .accessibilityIdentifier("recovery.open")
                    Button("Reload saved collection") { store.reload() }
                    Text("Your collection stays on this device. Reimport your ribbons.guide backup after changes. Showdown teams are preserved when backups are reimported.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Rarity") {
                    NavigationLink("Estimated rarity guide") { RarityGuide() }
                    Text("Rankings are editorial estimates of availability and acquisition challenge, not measured ownership percentages. Top-three displays show ribbons; full boards and totals include marks.").font(.caption).foregroundStyle(.secondary)
                }
                Section("About") {
                    Link("Open ribbons.guide", destination: URL(string: "https://ribbons.guide/")!)
                    Text("Unofficial fan app. Pokémon artwork © its respective owners. Code and source credits are included in the project. Version 0.3 test build.").font(.caption).foregroundStyle(.secondary)
                }
            }.navigationTitle("Settings")
        }
    }
}
struct RarityGuide: View {
    var body: some View {
        List {
            ForEach(RibbonCatalog.shared.ranked(Array(RibbonCatalog.shared.ribbons.keys)), id: \.self) { id in
                HStack(spacing: 10) {
                    AssetImage(key: "award-" + id).frame(width: 35, height: 35)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(RibbonCatalog.shared.ribbons[id] ?? id).font(.headline)
                        Text("\(RibbonCatalog.shared.rarity[id]?.tier ?? "?") · \(RibbonCatalog.shared.rarity[id]?.reason ?? "Unranked")").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }.navigationTitle("Estimated rarity")
    }
}
