import SwiftUI

struct AddPokemonView: View {
    var boxID: String
    var kind: TeamKind = .ribbon
    var onAdded: (String) -> Void = { _ in }
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var pokemon = RibbonPokemon(species: "", currentlevel: 5)
    @State private var speciesPicker = false
    @State private var awards = false
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
                    Stepper("Level \(pokemon.currentlevel)", value: $pokemon.currentlevel, in: 1...100)
                    Toggle("Shiny", isOn: $pokemon.shiny)
                    Picker("Gender", selection: $pokemon.gender) {
                        Text("Not specified").tag(""); Text("Male").tag("male"); Text("Female").tag("female")
                    }
                    if pokemon.species == "lugia" || pokemon.species == "lugia-shadow" { Toggle("Shadow Lugia artwork", isOn: $pokemon.shadow) }
                    if RibbonCatalog.shared.gmaxSpecies.contains(pokemon.species) { Toggle("Gigantamax factor", isOn: $pokemon.gmax) }
                }
                Section("Journey") {
                    GamePicker(title: "Origin game", value: $pokemon.origingame)
                    GamePicker(title: "Current game", value: $pokemon.currentgame)
                }
                if kind == .ribbon {
                    Section("Ribbons & marks") {
                        Button("Choose awards (\(pokemon.ribbons.count))") { awards = true }
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
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
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
                .sheet(isPresented: $awards) { AwardPicker(selection: $pokemon.ribbons) }
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
            }.searchable(text: $search, prompt: "Name, form or Pokédex number")
                .overlay { if matches.isEmpty { ContentUnavailableView.search(text: search) } }
                .navigationTitle("Species & forms").navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Cancel") { dismiss() } }
        }
    }
}

struct WallpaperControls: View {
    @Binding var settings: WallpaperSettings
    var body: some View {
        Picker("Background", selection: $settings.design) {
            ForEach(PixelWallpaper.allCases) { Text($0.name).tag($0) }
        }
        ColorPicker("Tint", selection: Binding(get: { Color(hex: settings.colorHex) }, set: { settings.tint = $0.rgbHex }), supportsOpacity: false)
        if settings.tint != nil { Button("Reset tint") { settings.tint = nil } }
        HStack { Text("Pattern strength"); Spacer(); Text("\(Int((settings.strength * 100).rounded()))%") }
        Slider(value: $settings.strength, in: 0...1, step: 0.05).accessibilityLabel("Pattern strength")
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
                    ZStack {
                        BoxWallpaperView(settings: settings)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(Array(SharedStore.demo().pokemon.prefix(6))) { p in PokemonSprite(pokemon: p).frame(height: 58) }
                        }.padding(14)
                    }.frame(height: 180).listRowInsets(EdgeInsets()).overlay(Rectangle().stroke(theme.border, lineWidth: 2))
                }
                Section("Sun / Moon · 16 wallpapers") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        ForEach(SunMoonWallpaper.allCases) { design in
                            Button { settings.sunMoon = design; settings.tint = nil } label: {
                                VStack(spacing: 6) {
                                    BoxWallpaperView(settings: WallpaperSettings(sunMoon: design)).frame(height: 70)
                                        .overlay(Rectangle().stroke(settings.sunMoon == design ? theme.accent : theme.border, lineWidth: settings.sunMoon == design ? 3 : 1))
                                    Text(design.name).font(PixelFont.font(16)).foregroundStyle(theme.ink)
                                }
                            }.buttonStyle(.plain)
                        }
                    }.padding(.vertical, 5)
                }
                Section("Customise") {
                    Toggle("Custom tint", isOn: Binding(get: { settings.tint != nil }, set: { settings.tint = $0 ? "719957" : nil }))
                    if settings.tint != nil {
                        ColorPicker("Tint", selection: Binding(get: { Color(hex: settings.colorHex) }, set: { settings.tint = $0.rgbHex }), supportsOpacity: false)
                        Text("Tint strength")
                        Slider(value: $settings.strength, in: 0...1, step: 0.05).accessibilityLabel("Tint strength")
                    }
                }
            }.font(PixelFont.font(17)).navigationTitle(box.name + " wallpaper").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
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
                .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search " + title.lowercased())
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Cancel") { dismiss() } }
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
