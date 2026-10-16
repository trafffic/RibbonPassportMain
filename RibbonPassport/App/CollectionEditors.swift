import SwiftUI
import UniformTypeIdentifiers

struct AddPokemonView: View {
    var boxID: String
    var kind: TeamKind = .ribbon
    var onAdded: (String) -> Void = { _ in }
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var pokemon = RibbonPokemon(species: "", currentlevel: 5)
    @State private var speciesPicker = false
    @State private var awards = false
    @State private var marks = false
    @State private var build = ShowdownSet()
    @State private var moves = Array(repeating: "", count: 4)
    var body: some View {
        NavigationStack {
            Form {
                Section("Pokémon") {
                    Button { speciesPicker = true } label: {
                        HStack {
                            if !pokemon.species.isEmpty { PokemonSprite(pokemon: pokemon, download: true).frame(width: 54, height: 54) }
                            Text(pokemon.species.isEmpty ? "Choose species / form" : RibbonCatalog.shared.speciesPickerName(pokemon.species))
                                .foregroundStyle(.primary)
                            Spacer(); Image(systemName: "chevron.right")
                        }
                    }.accessibilityIdentifier("pokemon.chooseSpecies")
                    TextField("Nickname", text: $pokemon.nickname)
                    TerminalStepper("Level \(pokemon.currentlevel)", value: $pokemon.currentlevel, in: 1...100)
                    Toggle("Shiny", isOn: $pokemon.shiny)
                    TerminalSelector(title: "Gender", selection: $pokemon.gender, values: ["", "male", "female"], name: { $0.isEmpty ? "Not specified" : $0.capitalized })
                    if RibbonRules.shared.species[pokemon.species]?.flags.contains(where: { ["colShadow", "xdShadow"].contains($0) }) == true { Toggle("Shadow Pokémon", isOn: $pokemon.shadow) }
                    if RibbonCatalog.shared.gmaxSpecies.contains(pokemon.species) { Toggle("Gigantamax factor", isOn: $pokemon.gmax) }
                }
                Section("Journey") {
                    GamePicker(title: "Origin game", value: $pokemon.origingame)
                    GamePicker(title: "Current game", value: $pokemon.currentgame)
                    RibbonMetLevelEditor(pokemon: $pokemon)
                }
                Section {
                    TerminalDisclosureGroup("Capture details") {
                        SearchableChoicePicker(title: "Ball", value: Binding(get: { pokemon.ball ?? "" }, set: { pokemon.ball = $0.isEmpty ? nil : $0 }), choices: RibbonsGuideExporter.balls, emptyLabel: "Not specified")
                        SearchableChoicePicker(title: "Language", value: Binding(get: { pokemon.language ?? "" }, set: { pokemon.language = $0.isEmpty ? nil : $0 }), choices: RibbonsGuideExporter.languages, emptyLabel: "Not specified")
                        TextField("Original trainer", text: Binding(get: { pokemon.trainername ?? "" }, set: { pokemon.trainername = $0 }))
                    }
                }
                if kind == .ribbon {
                    Section("Ribbons & marks") {
                        ManageRibbonsButton(pokemon: pokemon) { awards = true }.disabled(pokemon.species.isEmpty)
                        Button("Edit marks (\(pokemon.ribbons.filter { $0.hasSuffix("-mark") }.count))") { marks = true }
                        SearchableChoicePicker(title: "Equipped title", value: $pokemon.title, choices: RibbonCatalog.shared.awardChoices(pokemon.ribbons), emptyLabel: "None", emptyID: "None")
                    }
                }
                if kind == .showdown {
                    Section("Build") {
                        TextField("Held item", text: $build.item)
                        TextField("Ability", text: $build.ability)
                        TextField("Nature", text: $build.nature)
                        TextField("Tera type", text: $build.teraType)
                        TextField("EVs · 252 SpA / 4 SpD / 252 Spe", text: $build.evs)
                        TextField("IVs · 0 Atk", text: $build.ivs)
                    }
                    Section("Moves") {
                        ForEach(0..<4, id: \.self) { i in TextField("Move \(i + 1)", text: $moves[i]) }
                    }
                }
            }.font(PixelFont.font(17)).navigationTitle("Add Pokémon").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    TerminalToolbarItem(placement: .cancellationAction) { TerminalCornerButton("Cancel") { dismiss() } }
                    TerminalToolbarItem(placement: .confirmationAction) {
                        TerminalCornerButton("Add") {
                            var entry = pokemon
                            if kind == .showdown {
                                var details = build
                                details.moves = moves.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                                entry.showdownSet = details
                            }
                            if store.addPokemon(entry, toBox: boxID) { onAdded(entry.id); dismiss() }
                        }.disabled(pokemon.species.isEmpty).accessibilityIdentifier("pokemon.saveNew")
                    }
                }
                .sheet(isPresented: $speciesPicker) { SpeciesPicker(selection: $pokemon.species) }
                .sheet(isPresented: $awards) { RibbonManager(pokemon: $pokemon, entryTitle: "Add Pokémon") { awards = false } }
                .sheet(isPresented: $marks) { AwardPicker(selection: $pokemon.ribbons) }
                .onChange(of: pokemon.species) { _, _ in pokemon.gmax = false; pokemon.shadow = false }
                .onChange(of: pokemon.ribbons) { _, owned in if !owned.contains(pokemon.title) { pokemon.title = "None" } }
        }
    }
}

struct SpeciesPicker: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    private static let ordered = RibbonCatalog.shared.nationalDexSpecies
    private var matches: [String] {
        let query = RibbonCatalog.normalise(search)
        guard !query.isEmpty else { return Self.ordered }
        return Self.ordered.filter { id in
            return RibbonCatalog.normalise(RibbonCatalog.shared.speciesPickerName(id)).contains(query) || RibbonCatalog.normalise(id).contains(query) || Int(search.trimmingCharacters(in: .whitespaces)) == RibbonCatalog.shared.dexNumber(for: id)
        }
    }
    var body: some View {
        NavigationStack {
            List(matches, id: \.self) { id in
                let dex = RibbonCatalog.shared.dexNumber(for: id)
                Button {
                    selection = id; dismiss()
                } label: {
                    HStack(spacing: 10) {
                        Text(dex == Int.max ? "#—" : String(format: "#%04d", dex)).font(PixelFont.font(14)).foregroundStyle(.secondary).frame(width: 53, alignment: .leading)
                        Text(RibbonCatalog.shared.speciesPickerName(id)).font(PixelFont.font(18)).foregroundStyle(.primary)
                        Spacer()
                        if selection == id { Image(systemName: "checkmark") }
                    }.padding(.vertical, 5)
                }
            }.terminalSearchable(text: $search, prompt: "Name, form or Pokédex number")
                .overlay { if matches.isEmpty { ContentUnavailableView.search(text: search) } }
                .navigationTitle("Species & forms").navigationBarTitleDisplayMode(.inline)
                .toolbar { TerminalToolbarItem(placement: .topBarTrailing) { TerminalCornerButton("Cancel") { dismiss() }  } }
        }
    }
}

struct WallpaperControls: View {
    @Binding var settings: WallpaperSettings
    var body: some View {
        TerminalSelector(title: "Background", selection: $settings.design, values: PixelWallpaper.allCases, name: { $0.name })
        TerminalColorPicker("Tint", selection: Binding(get: { Color(hex: settings.colorHex) }, set: { settings.tint = $0.rgbHex }), supportsOpacity: false)
        if settings.tint != nil { Button("Reset tint") { settings.tint = nil } }
        HStack { Text("Pattern strength"); Spacer(); Text("\(Int((settings.strength * 100).rounded()))%") }
        TerminalSlider(value: $settings.strength, in: 0...1, step: 0.05).accessibilityLabel("Pattern strength")
    }
}
extension Color {
    fileprivate var rgbHex: String {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 1
        guard UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return "719957" }
        return String(format: "%02X%02X%02X", Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded()))
    }
}

struct BoxWallpaperEditor: View {
    var box: PCBox
    @State var settings: WallpaperSettings
    var kind: TeamKind = .ribbon
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    private var theme: PassportTheme { PassportTheme(dark: scheme == .dark, game: "") }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    GeometryReader { geometry in
                        ZStack(alignment: .topLeading) {
                            BoxWallpaperView(settings: settings, fullArtwork: true)
                            Text(box.name.uppercased()).font(PixelFont.font(15)).foregroundStyle(.white)
                                .offset(x: geometry.size.width * 0.16, y: geometry.size.height * 0.07)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 6), spacing: 0) {
                                ForEach(Array(SharedStore.demo().pokemon.prefix(6))) { p in
                                    PokemonSprite(pokemon: p).frame(height: geometry.size.height * PCGridMetrics.gridHeight / PCGridMetrics.artworkHeight / 5).padding(3)
                                }
                            }.frame(width: geometry.size.width * PCGridMetrics.gridWidth / PCGridMetrics.artworkWidth)
                                .offset(x: geometry.size.width * PCGridMetrics.originX / PCGridMetrics.artworkWidth, y: geometry.size.height * PCGridMetrics.originY / PCGridMetrics.artworkHeight)
                        }
                    }.aspectRatio(208.0 / 192, contentMode: .fit).listRowInsets(EdgeInsets())
                }
                Section("Sun / Moon · 16 wallpapers") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        ForEach(SunMoonWallpaper.allCases) { design in
                            Button { settings.sunMoon = design; settings.tint = nil } label: {
                                VStack(spacing: 6) {
                                    BoxWallpaperView(settings: WallpaperSettings(sunMoon: design), fullArtwork: true).frame(height: 70)
                                        .overlay(Rectangle().stroke(settings.sunMoon == design ? theme.accent : theme.border, lineWidth: settings.sunMoon == design ? 3 : 1))
                                    Text(design.name).font(PixelFont.font(16)).foregroundStyle(theme.ink)
                                }
                            }.buttonStyle(.plain).accessibilityIdentifier("pc.wallpaper.\(design.rawValue)").accessibilityValue(settings.sunMoon == design ? "Selected" : "Not selected")
                        }
                    }.padding(.vertical, 5)
                }
                Section("Customise") {
                    Toggle("Custom tint", isOn: Binding(get: { settings.tint != nil }, set: { settings.tint = $0 ? "719957" : nil }))
                    if settings.tint != nil {
                        TerminalColorPicker("Tint", selection: Binding(get: { Color(hex: settings.colorHex) }, set: { settings.tint = $0.rgbHex }), supportsOpacity: false)
                        Text("Tint strength")
                        TerminalSlider(value: $settings.strength, in: 0...1, step: 0.05).accessibilityLabel("Tint strength")
                    }
                }
            }.font(PixelFont.font(17)).navigationTitle(box.name + " wallpaper").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    TerminalToolbarItem(placement: .cancellationAction) { TerminalCornerButton("Cancel") { dismiss() } }
                    TerminalToolbarItem(placement: .confirmationAction) {
                        TerminalCornerButton("Save") {
                            store.editStorage(kind: kind) { layout in
                                if let i = layout.boxes.firstIndex(where: { $0.id == box.id }) { layout.boxes[i].wallpaper = settings }
                            }
                            if store.error == nil { dismiss() }
                        }
                    }
                }
        }
    }
}

struct SearchableChoicePicker: View {
    var title: String
    @Binding var value: String
    var choices: [SearchChoice]
    var emptyLabel: String? = nil
    var emptyID = ""
    @State private var presented = false
    private var selectedName: String { choices.first { $0.id == value }?.name ?? (value == emptyID ? emptyLabel ?? "Choose" : value) }
    var body: some View {
        Button { presented = true } label: {
            HStack(spacing: 12) {
                Text(title).foregroundStyle(.primary)
                Spacer(minLength: 8)
                Text(selectedName).foregroundStyle(.secondary).multilineTextAlignment(.trailing).lineLimit(2)
                Image(systemName: "chevron.down").font(.system(size: 11)).foregroundStyle(.secondary)
            }.frame(minHeight: 32).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(title + ": " + selectedName)
            .sheet(isPresented: $presented) {
                SearchableChoiceList(title: title, value: $value, choices: choices, emptyLabel: emptyLabel, emptyID: emptyID)
            }
    }
}
struct SearchableChoiceList: View {
    var title: String
    @Binding var value: String
    var choices: [SearchChoice]
    var emptyLabel: String? = nil
    var emptyID = ""
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    private var results: [SearchChoice] { choices.filter { $0.matches(search) } }
    var body: some View {
        NavigationStack {
            List {
                if let emptyLabel, search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    choice(emptyID, name: emptyLabel)
                }
                ForEach(results) { item in choice(item.id, name: item.name) }
            }.font(PixelFont.font(17))
                .overlay { if results.isEmpty && !search.isEmpty { ContentUnavailableView.search(text: search) } }
                .terminalSearchable(text: $search, prompt: "Search " + title.lowercased())
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
                .toolbar { TerminalToolbarItem(placement: .topBarTrailing) { TerminalCornerButton("Cancel") { dismiss() }  } }
        }
    }
    private func choice(_ id: String, name: String) -> some View {
        Button { value = id; dismiss() } label: {
            HStack {
                Text(name).foregroundStyle(.primary).fixedSize(horizontal: false, vertical: true)
                Spacer()
                if value == id { Image(systemName: "checkmark").accessibilityLabel("Selected") }
            }.frame(minHeight: 34).contentShape(Rectangle())
        }
    }
}

enum PokemonExportTarget: String, CaseIterable, Identifiable {
    case showdown, ribbonsGuide
    var id: String { rawValue }
    var name: String { self == .showdown ? "Showdown" : "ribbons.guide" }
    var contentType: UTType { self == .showdown ? .plainText : .json }
    var filename: String { self == .showdown ? "ShowdownTeam" : "RibbonBackup" }
}
struct PokemonExportSelection: Identifiable {
    var id = UUID()
    var pokemon: [RibbonPokemon]
    var target: PokemonExportTarget
}
struct PokemonExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .plainText] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
struct PokemonExportView: View {
    var selection: PokemonExportSelection
    @Environment(\.dismiss) private var dismiss
    @State private var target: PokemonExportTarget
    @State private var data = Data()
    @State private var failure = ""
    @State private var saving = false
    @State private var importingBackup = false
    @State private var baseBackup: Data?
    @State private var fallbackBall = ""
    @State private var fallbackLanguage = ""
    @State private var fallbackTrainer = ""
    @State private var message = ""
    init(selection: PokemonExportSelection) {
        self.selection = selection; _target = State(initialValue: selection.target)
    }
    private var text: String { String(data: data, encoding: .utf8) ?? "" }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("\(selection.pokemon.count) Pokémon").font(PixelFont.font(23))
                    TerminalSelector(title: "Export to", selection: $target, values: PokemonExportTarget.allCases, name: { $0.name }, inline: true)
                }
                if target == .ribbonsGuide {
                    Section("ribbons.guide backup") {
                        Text("Species, nickname, gender, shiny status, level, games, ribbons, title, Gigantamax and Shadow status.").font(PixelFont.font(15))
                        if selection.pokemon.contains(where: RibbonsGuideExporter.needsBall) {
                            SearchableChoicePicker(title: "Ball for missing entries", value: $fallbackBall, choices: RibbonsGuideExporter.balls)
                        }
                        if selection.pokemon.contains(where: RibbonsGuideExporter.needsLanguage) {
                            SearchableChoicePicker(title: "Language for missing entries", value: $fallbackLanguage, choices: RibbonsGuideExporter.languages)
                        }
                        if selection.pokemon.contains(where: { $0.title == "partner-ribbon" && ($0.trainername ?? "").isEmpty }) {
                            TextField("Original trainer name", text: $fallbackTrainer)
                        }
                        if selection.pokemon.contains(where: { RibbonsGuideExporter.speciesID(for: $0) != $0.species }) {
                            Text("Unsupported forms use ribbons.guide’s matching species.").font(PixelFont.font(14)).foregroundStyle(.secondary)
                        }
                        Button(baseBackup == nil ? "Append to an existing website backup…" : "Change existing backup…") { importingBackup = true }
                        if baseBackup != nil {
                            Text("Existing website records and settings are kept. Exported Pokémon are appended.").font(PixelFont.font(14)).foregroundStyle(.secondary)
                            Button("Export without existing backup") { baseBackup = nil; prepare() }
                        }
                        Text("On ribbons.guide, open Settings → Data → Restore Backup. Restoring replaces the website’s collection with this file.").font(PixelFont.font(14)).foregroundStyle(.secondary)
                    }
                } else {
                    Section("Showdown import text") {
                        Text("In Showdown’s Teambuilder, open Import/Export and paste this text.").font(PixelFont.font(15))
                        Button("Copy Showdown text") { UIPasteboard.general.string = text; message = "Copied" }.disabled(!failure.isEmpty || data.isEmpty)
                    }
                }
                if !failure.isEmpty { Section { Text(failure).foregroundStyle(.red) } }
                Section {
                    Button("Save \(target == .showdown ? "text" : "JSON") file") { saving = true }.disabled(!failure.isEmpty || data.isEmpty)
                    if target == .showdown && failure.isEmpty && !data.isEmpty { ShareLink("Share Showdown text", item: text) }
                    if !message.isEmpty { Text(message).font(PixelFont.font(14)).foregroundStyle(.secondary) }
                }
                if failure.isEmpty && !data.isEmpty {
                    Section {
                        TerminalDisclosureGroup("Preview") {
                            Text(text).font(.system(size: 12, design: .monospaced)).textSelection(.enabled)
                        }
                    }
                }
            }.font(PixelFont.font(17)).navigationTitle("Export Pokémon").navigationBarTitleDisplayMode(.inline)
                .toolbar { TerminalToolbarItem(placement: .topBarTrailing) { TerminalCornerButton("Done") { dismiss() }  } }
                .onAppear { prepare() }
                .onChange(of: target) { _, _ in prepare() }
                .onChange(of: fallbackBall) { _, _ in prepare() }
                .onChange(of: fallbackLanguage) { _, _ in prepare() }
                .onChange(of: fallbackTrainer) { _, _ in prepare() }
                .fileExporter(isPresented: $saving, document: PokemonExportDocument(data: data), contentType: target.contentType, defaultFilename: target.filename) { result in
                    switch result { case .success: message = "File saved"; case .failure(let error): failure = error.localizedDescription }
                }
                .fileImporter(isPresented: $importingBackup, allowedContentTypes: [.json]) { result in
                    do {
                        let url = try result.get(), granted = url.startAccessingSecurityScopedResource()
                        defer { if granted { url.stopAccessingSecurityScopedResource() } }
                        let candidate = try Data(contentsOf: url)
                        baseBackup = candidate; prepare()
                    } catch { failure = error.localizedDescription }
                }
        }
    }
    private func prepare() {
        do {
            data = target == .showdown ? Data(try ShowdownExporter.validatedExport(selection.pokemon).utf8) : try RibbonsGuideExporter.export(selection.pokemon, merging: baseBackup, fallbackBall: fallbackBall, fallbackLanguage: fallbackLanguage, fallbackTrainer: fallbackTrainer)
            failure = ""; message = ""
        } catch { data = Data(); failure = error.localizedDescription }
    }
}
