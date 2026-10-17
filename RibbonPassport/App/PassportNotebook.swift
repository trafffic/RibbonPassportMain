import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

enum PassportNotes {
    static func games(for pokemon: RibbonPokemon) -> [String] {
        var origin = pokemon
        if !pokemon.origingame.isEmpty { origin.currentgame = pokemon.origingame }
        let valid = RibbonRules.shared.compatibleGames(for: origin)
        return RibbonCatalog.shared.orderedGames(Array(Set(valid + pokemon.recordedVisits.map(\.game))))
    }
    static func validDate(_ value: String) -> Bool {
        guard !value.isEmpty else { return true }
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"; formatter.isLenient = false
        return value.count == 10 && formatter.date(from: value).map { formatter.string(from: $0) == value } == true
    }
}
struct OptionalNotebookDate: View {
    @Binding var value: String
    var identifier: String
    private var formatter: DateFormatter {
        let result = DateFormatter(); result.locale = Locale(identifier: "en_US_POSIX")
        result.dateFormat = "yyyy-MM-dd"; result.isLenient = false
        return result
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Date known", isOn: Binding(get: { !value.isEmpty }, set: { known in
                value = known ? formatter.string(from: Date()) : ""
            })).accessibilityIdentifier(identifier + ".known")
            if !value.isEmpty {
                DatePicker("Date", selection: Binding(get: { formatter.date(from: value) ?? Date() }, set: { value = formatter.string(from: $0) }), displayedComponents: .date)
                    .datePickerStyle(.compact).accessibilityIdentifier(identifier)
            }
        }
    }
}

struct NotebookPhotoField: View {
    @Binding var data: Data?
    @State private var selection: PhotosPickerItem?
    @State private var failure = ""
    @State private var loading = false
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 240).accessibilityLabel("Attached screenshot")
                Button("Remove screenshot") { self.data = nil; selection = nil }.buttonStyle(RetroAction())
            }
            PhotosPicker(selection: $selection, matching: .images) { Text(loading ? "Loading screenshot…" : data == nil ? "Add screenshot" : "Replace screenshot") }
                .buttonStyle(RetroAction()).disabled(loading)
            if !failure.isEmpty { Text(failure).font(PixelFont.font(13)).foregroundStyle(.red) }
        }.task(id: selection) {
            guard let chosen = selection else { return }
            loading = true; failure = ""
            defer { loading = false }
            do {
                guard let raw = try await chosen.loadTransferable(type: Data.self), raw.count <= 25_000_000,
                      let image = UIImage(data: raw) else { failure = "Choose an image smaller than 25 MB."; return }
                guard !Task.isCancelled else { return }
                let factor = min(1, 1200 / max(image.size.width, image.size.height))
                let size = CGSize(width: image.size.width * factor, height: image.size.height * factor)
                let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
                let reduced = UIGraphicsImageRenderer(size: size, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
                guard let jpeg = reduced.jpegData(compressionQuality: 0.7), jpeg.count <= 2_000_000 else { failure = "This image is too large to attach."; return }
                data = jpeg
            } catch { if !Task.isCancelled { failure = "The screenshot could not be opened. Try choosing it again." } }
        }
    }
}
struct HonorAlbumView: View {
    var pokemonID: String
    @EnvironmentObject private var store: AppStore
    @State private var editing: PassportHonor?
    @State private var layout = "Grid"
    @State private var generation = 0
    @State private var page = 0
    private var p: RibbonPokemon? { store.snapshot.pokemon.first { $0.id == pokemonID } }
    private var definitions: [HonorDefinition] {
        guard let p else { return [] }
        let games = Set(PassportNotes.games(for: p))
        return CommunityContent.shared.honorDefinitions.filter {
            !games.isDisjoint(with: $0.games) && (generation == 0 || $0.games.contains { RibbonCatalog.shared.gameInfo[$0]?.gen == generation })
        }.sorted { (CatalogOrder.gameIndex($0.games.first ?? ""), $0.id) < (CatalogOrder.gameIndex($1.games.first ?? ""), $1.id) }
    }
    var body: some View {
        CommunityPage(title: "Milestones") {
            if let p {
                Text(p.displayName).font(PixelFont.font(25))
                Text("Optional milestones · separate from ribbons and Ribbon Master completion").font(PixelFont.font(13)).foregroundStyle(.secondary)
                TerminalSelector(title: "Generation", selection: $generation, values: [0, 3, 4, 5, 6, 7, 8, 9], name: { $0 == 0 ? "All" : "Gen " + $0.roman })
                TerminalSelector(title: "Layout", selection: $layout, values: ["Grid", "List"], name: { $0 }, inline: true)
                let shown = Array(definitions.dropFirst(page * 6).prefix(6))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: layout == "Grid" ? 2 : 1), spacing: 10) {
                    ForEach(shown) { definition in
                        let owned = (p.honors ?? []).filter { $0.catalogID == definition.id && $0.earned }.count
                        Button {
                            if let existing = p.honors?.first(where: { $0.catalogID == definition.id }) { editing = existing }
                            else {
                                let games = definition.games.filter { PassportNotes.games(for: p).contains($0) }
                                editing = PassportHonor(catalogID: definition.id, title: definition.title, game: games.first ?? "", trainerMilestone: definition.trainerMilestone)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 9) {
                                HStack { Text(owned > 0 ? "★" : "☆").font(PixelFont.font(25)); Spacer(); GameMascot(game: definition.games.first ?? "", size: 26) }
                                Text(definition.title).font(PixelFont.font(18)).fixedSize(horizontal: false, vertical: true)
                                Text(owned > 0 ? "Recorded" : definition.trainerMilestone ? "Trainer milestone" : "Pokémon achievement").font(PixelFont.font(12)).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading).retroPanel(padding: 12)
                        }.buttonStyle(.plain).accessibilityIdentifier("honor." + definition.id)
                    }
                }
                if definitions.count > 6 {
                    HStack {
                        Button("‹ Previous") { page -= 1 }.disabled(page == 0)
                        Spacer(); Text("\(page + 1) / \((definitions.count + 5) / 6)")
                        Spacer(); Button("Next ›") { page += 1 }.disabled((page + 1) * 6 >= definitions.count)
                    }.font(PixelFont.font(13)).buttonStyle(.plain).frame(minHeight: 44)
                }
                Button("Add custom milestone") { editing = PassportHonor(catalogID: "custom", title: "", game: p.currentgame) }
                    .buttonStyle(RetroAction()).accessibilityIdentifier("honors.custom")
                if definitions.isEmpty { Text("No preset milestones for these games. You can add your own.").font(PixelFont.font(13)).foregroundStyle(.secondary) }
                if !(p.honors ?? []).isEmpty {
                    RetroHeading(title: "Recorded milestones")
                    ForEach(p.honors ?? []) { honor in
                        Button { editing = honor } label: {
                            CommunityRow(title: honor.title, subtitle: RibbonCatalog.shared.gameName(honor.game) + (honor.date.isEmpty ? "" : " · " + honor.date), symbol: honor.earned ? "★" : "☆")
                        }.buttonStyle(.plain).accessibilityIdentifier("honors.record." + honor.id)
                    }
                }
            }
        }.onChange(of: generation) { _, _ in page = 0 }
            .sheet(item: $editing) { record in NavigationStack { HonorRecordEditor(pokemonID: pokemonID, record: record) } }
    }
}
struct HonorRecordEditor: View {
    var pokemonID: String
    @State var record: PassportHonor
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var failure = ""
    private var p: RibbonPokemon? { store.snapshot.pokemon.first { $0.id == pokemonID } }
    private var definition: HonorDefinition? { CommunityContent.shared.honorDefinitions.first { $0.id == record.catalogID } }
    private var games: [String] {
        let allowed = p.map { PassportNotes.games(for: $0) } ?? []
        let selected = definition.map { def in allowed.filter { def.games.contains($0) } } ?? allowed
        return RibbonCatalog.shared.orderedGames(Array(Set(selected + (record.game.isEmpty ? [] : [record.game]))))
    }
    var body: some View {
        CommunityPage(title: "Milestone", editing: true) {
            if let definition {
                Text(definition.title).font(PixelFont.font(26))
                Text(definition.summary).retroPanel()
            } else { TextField("Milestone name", text: $record.title).accessibilityIdentifier("honor.title") }
            Text(record.trainerMilestone ? "Manual milestone for this Pokémon · the game records this for the trainer/save" : "Manual Pokémon achievement · not a ribbon")
                .font(PixelFont.font(13)).foregroundStyle(.secondary)
            TerminalSelector(title: "Game", selection: $record.game, values: games, name: { RibbonCatalog.shared.gameName($0) })
            OptionalNotebookDate(value: $record.date, identifier: "honor.date")
            Toggle("Earned", isOn: $record.earned).toggleStyle(TerminalToggleStyle())
            if definition == nil { Toggle("Trainer / save milestone", isOn: $record.trainerMilestone).toggleStyle(TerminalToggleStyle()) }
            Text("Milestone notes").font(PixelFont.font(14)).foregroundStyle(.secondary)
            TextEditor(text: $record.note).scrollContentBackground(.hidden).font(PixelFont.font(16)).frame(minHeight: 120).retroPanel(padding: 8).accessibilityIdentifier("honor.note")
            NotebookPhotoField(data: $record.photo)
            Button("Save milestone") { save() }.buttonStyle(RetroAction(prominent: true)).accessibilityIdentifier("honor.save")
                .disabled(record.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || record.game.isEmpty)
            if p?.honors?.contains(where: { $0.id == record.id }) == true {
                Button("Remove milestone", role: .destructive) {
                    guard var p else { return }; p.honors?.removeAll { $0.id == record.id }; store.update(p)
                    if store.error == nil { dismiss() }
                }.buttonStyle(RetroAction()).accessibilityIdentifier("honor.remove")
            }
            if !failure.isEmpty { Text(failure).foregroundStyle(.red) }
            if let definition { CommunitySources(ids: definition.sourceIDs) }
        }.toolbar { TerminalToolbarItem(placement: .topBarTrailing) { TerminalCornerButton("Save") { save() }.disabled(record.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || record.game.isEmpty) } }
    }
    private func save() {
        guard PassportNotes.validDate(record.date) else { failure = "Use YYYY-MM-DD, or leave the date empty."; return }
        guard var p, !record.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, games.contains(record.game) else { return }
        var list = p.honors ?? []; list.removeAll { $0.id == record.id }; list.append(record); p.honors = list
        store.update(p); if store.error == nil { dismiss() }
    }
}
struct JourneyNotesView: View {
    var pokemonID: String
    @EnvironmentObject private var store: AppStore
    @State private var tab: String
    init(pokemonID: String, initialTab: String = "Memories") {
        self.pokemonID = pokemonID
        _tab = State(initialValue: initialTab == "Move Dex" ? "Move Dex" : "Memories")
    }
    @State private var journal: PassportJournalEntry?
    @State private var move: PassportMoveNote?
    private var p: RibbonPokemon? { store.snapshot.pokemon.first { $0.id == pokemonID } }
    var body: some View {
        CommunityPage(title: "Memories & Move Dex") {
            if let p {
                Text(p.displayName).font(PixelFont.font(26))
                TerminalSelector(title: "Notes", selection: $tab, values: ["Memories", "Move Dex"], name: { $0 }, inline: true)
                if tab == "Memories" {
                    Button("Add memory") { journal = PassportJournalEntry(title: "", game: p.currentgame) }.buttonStyle(RetroAction(prominent: true)).accessibilityIdentifier("journal.add")
                    ForEach((p.journal ?? []).reversed()) { entry in
                        Button { journal = entry } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                CommunityRow(title: entry.title, subtitle: [entry.date, RibbonCatalog.shared.gameName(entry.game)].filter { !$0.isEmpty }.joined(separator: " · "))
                                if !entry.text.isEmpty { Text(entry.text).font(PixelFont.font(15)).lineLimit(3) }
                                if let data = entry.photo, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 160) }
                            }
                        }.buttonStyle(.plain).accessibilityIdentifier("journal.entry." + entry.id)
                    }
                    if (p.journal ?? []).isEmpty { Text("No memories recorded yet.").foregroundStyle(.secondary) }
                } else {
                    Text("Record moves and games you have checked in HOME. These notes are manual and do not affect Ribbon Master completion.").font(PixelFont.font(14)).retroPanel()
                    Button("Add move note") { move = PassportMoveNote(move: "", game: p.currentgame) }.buttonStyle(RetroAction(prominent: true)).accessibilityIdentifier("moves.add")
                    ForEach(p.moveNotes ?? []) { note in
                        Button { move = note } label: { CommunityRow(title: note.move, subtitle: RibbonCatalog.shared.gameName(note.game) + " · " + (note.homeChecked ? "HOME checked" : "Not checked"), symbol: note.homeChecked ? "✓" : "›") }.buttonStyle(.plain)
                    }
                    CommunitySources(ids: ["home-moves", "home-travel"])
                }
            }
        }.sheet(item: $journal) { entry in NavigationStack { JourneyRecordEditor(pokemonID: pokemonID, entry: entry) } }
            .sheet(item: $move) { entry in NavigationStack { MoveNoteEditor(pokemonID: pokemonID, entry: entry) } }
    }
}
struct JourneyRecordEditor: View {
    var pokemonID: String
    @State var entry: PassportJournalEntry
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var failure = ""
    private var p: RibbonPokemon? { store.snapshot.pokemon.first { $0.id == pokemonID } }
    var body: some View {
        CommunityPage(title: "Memory", editing: true) {
            TextField("Title", text: $entry.title).accessibilityIdentifier("journal.title")
            TerminalSelector(title: "Game", selection: $entry.game, values: [""] + (p.map { PassportNotes.games(for: $0) } ?? []), name: { $0.isEmpty ? "Not set" : RibbonCatalog.shared.gameName($0) })
            OptionalNotebookDate(value: $entry.date, identifier: "journal.date")
            Text("Your memory").font(PixelFont.font(14)).foregroundStyle(.secondary)
            TextEditor(text: $entry.text).scrollContentBackground(.hidden).font(PixelFont.font(16)).frame(minHeight: 180).retroPanel(padding: 8).accessibilityIdentifier("journal.text")
            NotebookPhotoField(data: $entry.photo)
            Button("Save memory") { save() }.buttonStyle(RetroAction(prominent: true)).disabled(entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("journal.save")
            if p?.journal?.contains(where: { $0.id == entry.id }) == true {
                Button("Remove memory", role: .destructive) {
                    guard var p else { return }; p.journal?.removeAll { $0.id == entry.id }; store.update(p); if store.error == nil { dismiss() }
                }.buttonStyle(RetroAction()).accessibilityIdentifier("journal.remove")
            }
            if !failure.isEmpty { Text(failure).foregroundStyle(.red) }
        }.toolbar { TerminalToolbarItem(placement: .confirmationAction) {
            TerminalCornerButton("Save") { save() }.disabled(entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } }
    }
    private func save() {
        guard PassportNotes.validDate(entry.date) else { failure = "Use YYYY-MM-DD, or leave the date empty."; return }
        guard var p else { return }
        var entries = p.journal ?? []; entries.removeAll { $0.id == entry.id }; entries.append(entry); p.journal = entries
        store.update(p); if store.error == nil { dismiss() }
    }
}
struct MoveNoteEditor: View {
    var pokemonID: String
    @State var entry: PassportMoveNote
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    private var p: RibbonPokemon? { store.snapshot.pokemon.first { $0.id == pokemonID } }
    var body: some View {
        CommunityPage(title: "Move note", editing: true) {
            TextField("Move", text: $entry.move).accessibilityIdentifier("move.name")
            TerminalSelector(title: "Game", selection: $entry.game, values: p.map { PassportNotes.games(for: $0) } ?? [], name: { RibbonCatalog.shared.gameName($0) })
            Toggle("Checked in HOME", isOn: $entry.homeChecked).toggleStyle(TerminalToggleStyle())
            Text("Move notes").font(PixelFont.font(14)).foregroundStyle(.secondary)
            TextEditor(text: $entry.note).scrollContentBackground(.hidden).font(PixelFont.font(16)).frame(minHeight: 150).retroPanel(padding: 8)
            Text("A move noted here does not confirm that it can be used in another game.").font(PixelFont.font(13)).foregroundStyle(.secondary)
            Button("Save move note") { save() }.buttonStyle(RetroAction(prominent: true)).disabled(entry.move.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || entry.game.isEmpty).accessibilityIdentifier("move.save")
            if p?.moveNotes?.contains(where: { $0.id == entry.id }) == true {
                Button("Remove move note", role: .destructive) {
                    guard var p else { return }; p.moveNotes?.removeAll { $0.id == entry.id }; store.update(p); if store.error == nil { dismiss() }
                }.buttonStyle(RetroAction())
            }
        }.toolbar { TerminalToolbarItem(placement: .confirmationAction) {
            TerminalCornerButton("Save") { save() }.disabled(entry.move.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || entry.game.isEmpty)
        } }
    }
    private func save() {
        guard var p, !entry.move.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !entry.game.isEmpty else { return }
        var notes = p.moveNotes ?? []; notes.removeAll { $0.id == entry.id }; notes.append(entry); p.moveNotes = notes
        store.update(p); if store.error == nil { dismiss() }
    }
}

struct BuildNotebookView: View {
    private enum Field: Hashable { case name, notes }
    var pokemonID: String? = nil
    var teamID: String? = nil
    @EnvironmentObject private var store: AppStore
    @State private var name = ""
    @State private var notes = ""
    @State private var message = ""
    @State private var editing: PersonalBuild?
    @State private var export: PokemonExportSelection?
    @State private var restore: PersonalTeamBuild?
    @State private var editingTeam: PersonalTeamBuild?
    @FocusState private var focusedField: Field?
    private var p: RibbonPokemon? { store.snapshot.pokemon.first { $0.id == pokemonID } }
    private var team: RibbonTeam? { store.snapshot.teams.first { $0.id == teamID } }
    var body: some View {
        CommunityPage(title: "Build notebook") {
            Text(p?.displayName ?? team?.name ?? "Builds").font(PixelFont.font(26))
            TextField("Version name", text: $name).focused($focusedField, equals: .name).accessibilityIdentifier("notebook.name")
            TextField("Version notes (optional)", text: $notes, axis: .vertical).lineLimit(3...6).focused($focusedField, equals: .notes)
            Button("Save current build") { save() }.buttonStyle(RetroAction(prominent: true)).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("notebook.save")
            if !message.isEmpty { Text(message).foregroundStyle(Color(hex: "718F4E")).accessibilityIdentifier("notebook.feedback") }
            if let p {
                ForEach((p.savedBuilds ?? []).reversed()) { build in
                    Button { editing = build } label: { CommunityRow(title: build.name, subtitle: build.note) }.buttonStyle(.plain).accessibilityIdentifier("notebook.version." + build.id)
                }
                CommunitySources(ids: p.communitySourceIDs ?? [])
            }
            if let team {
                ForEach((team.savedBuilds ?? []).reversed()) { version in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(version.name).font(PixelFont.font(22)); Text(version.note).font(PixelFont.font(14))
                        let current = store.snapshot.members(teamID: team.id)
                        Text("\(version.members.filter { saved in current.first(where: { $0.id == saved.id })?.showdownSet != saved.build }.count) builds differ from current team").font(PixelFont.font(12)).foregroundStyle(.secondary)
                        ForEach(version.members) { member in Text("\(member.nickname.isEmpty ? member.species : member.nickname) · \(member.build.item)").font(PixelFont.font(13)) }
                        ViewThatFits {
                            HStack { teamActions(version) }
                            VStack(alignment: .leading) { teamActions(version) }
                        }
                        CommunitySources(ids: version.sourceIDs)
                    }.retroPanel()
                }
                CommunitySources(ids: team.communitySourceIDs ?? [])
            }
        }.sheet(item: $editing) { build in if let pokemonID { NavigationStack { PersonalBuildEditor(pokemonID: pokemonID, version: build) } } }
            .sheet(item: $editingTeam) { version in if let teamID { NavigationStack { TeamVersionNotesEditor(teamID: teamID, version: version) } } }
            .sheet(item: $export) { PokemonExportView(selection: $0) }
            .terminalConfirmationDialog("Apply this team version?", isPresented: Binding(get: { restore != nil }, set: { if !$0 { restore = nil } }), titleVisibility: .visible) {
                Button("Apply saved builds") {
                    guard let restore, let teamID else { return }; var next = store.snapshot; next.restoreTeamBuild(restore, teamID: teamID)
                    store.commit(next); if store.error == nil { message = "Team version applied" }; self.restore = nil
                }
            }
    }
    @ViewBuilder private func teamActions(_ version: PersonalTeamBuild) -> some View {
        Button("Apply") { restore = version }.buttonStyle(RetroAction())
        Button("Notes") { editingTeam = version }.buttonStyle(RetroAction())
        Button("Export") {
            let members = version.members.map { $0.pokemon() }
            export = PokemonExportSelection(pokemon: members, target: .showdown)
        }.buttonStyle(RetroAction())
        Button("Remove", role: .destructive) {
            guard var team else { return }; team.savedBuilds?.removeAll { $0.id == version.id }; store.saveTeam(team)
        }.buttonStyle(RetroAction())
    }
    private func save() {
        if var p, let build = p.showdownSet {
            var versions = p.savedBuilds ?? []; versions.append(PersonalBuild(name: name, build: build, note: notes, sourceIDs: p.communitySourceIDs ?? [])); p.savedBuilds = versions; store.update(p)
        } else if var team {
            let members = store.snapshot.members(teamID: team.id).compactMap { p -> TeamBuildMember? in
                guard let build = p.showdownSet else { return nil }
                return TeamBuildMember(id: p.id, species: p.species, nickname: p.nickname, build: build,
                                       level: p.currentlevel, game: p.currentgame, gender: p.gender, shiny: p.shiny, gmax: p.gmax)
            }
            var versions = team.savedBuilds ?? []; versions.append(PersonalTeamBuild(name: name, members: members, note: notes, sourceIDs: team.communitySourceIDs ?? []))
            team.savedBuilds = versions; store.saveTeam(team)
        }
        if store.error == nil { focusedField = nil; name = ""; notes = ""; message = "Version saved" }
    }
}
struct PersonalBuildEditor: View {
    var pokemonID: String
    @State var version: PersonalBuild
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var exporting: PokemonExportSelection?
    @State private var failure = ""
    private var p: RibbonPokemon? { store.snapshot.pokemon.first { $0.id == pokemonID } }
    var body: some View {
        CommunityPage(title: "Saved build", editing: true) {
            TextField("Version name", text: $version.name)
            if let current = p?.showdownSet {
                Text(current == version.build ? "Matches current build" : "Differs from current build").font(PixelFont.font(13)).foregroundStyle(.secondary)
            }
            TextField("Item", text: $version.build.item); TextField("Ability", text: $version.build.ability)
            TextField("Nature", text: $version.build.nature); TextField("Tera type", text: $version.build.teraType)
            TextField("EVs", text: $version.build.evs); TextField("IVs", text: $version.build.ivs)
            ForEach(0..<4, id: \.self) { index in
                TextField("Move \(index + 1)", text: Binding(get: { version.build.moves.indices.contains(index) ? version.build.moves[index] : "" }, set: { value in
                    while version.build.moves.count < 4 { version.build.moves.append("") }; version.build.moves[index] = value
                }))
            }
            Text("Version notes").font(PixelFont.font(14)).foregroundStyle(.secondary)
            TextEditor(text: $version.note).scrollContentBackground(.hidden).frame(minHeight: 120).retroPanel(padding: 8)
            Button("Save version") { save(apply: false) }.buttonStyle(RetroAction(prominent: true)).disabled(version.name.isEmpty)
            Button("Apply to Pokémon") { save(apply: true) }.buttonStyle(RetroAction()).accessibilityIdentifier("build.apply")
            Button("Export this version") { if var p { p.showdownSet = version.build; exporting = PokemonExportSelection(pokemon: [p], target: .showdown) } }.buttonStyle(RetroAction())
            Button("Remove version", role: .destructive) {
                guard var p else { return }; p.savedBuilds?.removeAll { $0.id == version.id }; store.update(p); if store.error == nil { dismiss() }
            }.buttonStyle(RetroAction())
            if !failure.isEmpty { Text(failure).foregroundStyle(.red) }
            CommunitySources(ids: version.sourceIDs)
        }.toolbar { TerminalToolbarItem(placement: .confirmationAction) {
            TerminalCornerButton("Save") { save(apply: false) }.disabled(version.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } }.sheet(item: $exporting) { PokemonExportView(selection: $0) }
    }
    private func save(apply: Bool) {
        guard var p, !version.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        do { var check = p; check.showdownSet = version.build; _ = try ShowdownExporter.validatedExport([check]) }
        catch { failure = error.localizedDescription; return }
        version.build.moves.removeAll { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if let index = p.savedBuilds?.firstIndex(where: { $0.id == version.id }) { p.savedBuilds?[index] = version }
        if apply { p.showdownSet = version.build }
        store.update(p); if store.error == nil { dismiss() }
    }
}
struct TeamVersionNotesEditor: View {
    var teamID: String
    @State var version: PersonalTeamBuild
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        CommunityPage(title: "Version notes", editing: true) {
            TextField("Version name", text: $version.name)
            Text("Version notes").font(PixelFont.font(14)).foregroundStyle(.secondary)
            TextEditor(text: $version.note).scrollContentBackground(.hidden).frame(minHeight: 180).retroPanel(padding: 8)
            Button("Save notes") { save() }.buttonStyle(RetroAction(prominent: true)).disabled(version.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }.toolbar { TerminalToolbarItem(placement: .confirmationAction) {
            TerminalCornerButton("Save") { save() }.disabled(version.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } }
    }
    private func save() {
        guard !version.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              var team = store.snapshot.teams.first(where: { $0.id == teamID }),
              let index = team.savedBuilds?.firstIndex(where: { $0.id == version.id }) else { return }
        team.savedBuilds?[index] = version; store.saveTeam(team); if store.error == nil { dismiss() }
    }
}
struct LocalAppBackupView: View {
    @EnvironmentObject private var store: AppStore
    @State private var exporting = false
    @State private var importing = false
    @State private var data = Data()
    @State private var pending: CollectionSnapshot?
    @State private var confirming = false
    @State private var feedback = ""
    var body: some View {
        CommunityPage(title: "App backup") {
            Text("Your complete collection").font(PixelFont.font(24))
            Text("Includes honors, memories, screenshots, move notes, saved builds, sources, boxes and recovery history.").retroPanel()
            Button("Save app backup") {
                do { data = try PassportAppBackup(collection: store.snapshot).encoded(); exporting = true }
                catch { feedback = error.localizedDescription }
            }.buttonStyle(RetroAction(prominent: true))
            Button("Restore app backup") { importing = true }.buttonStyle(RetroAction())
            if !feedback.isEmpty { Text(feedback).font(PixelFont.font(14)) }
            Text("Use the regular Pokémon export for ribbons.guide or Showdown. This backup is for Ribbon Passport.").font(PixelFont.font(13)).foregroundStyle(.secondary)
        }.fileExporter(isPresented: $exporting, document: PokemonExportDocument(data: data), contentType: .json, defaultFilename: "RibbonPassport-backup.json") { result in
            switch result { case .success: feedback = "App backup saved"; case .failure(let error): feedback = error.localizedDescription }
        }.fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get(); let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
                pending = try PassportAppBackup.decode(Data(contentsOf: url)); confirming = true
            } catch { feedback = error.localizedDescription }
        }.terminalConfirmationDialog("Restore \(pending?.pokemon.count ?? 0) Pokémon from this app backup?", isPresented: $confirming, titleVisibility: .visible) {
            Button("Replace with backup") {
                if let pending { store.restoreAppBackup(pending); feedback = store.error ?? "App backup restored" }; pending = nil
            }
        }
    }
}
