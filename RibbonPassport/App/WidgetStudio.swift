import SwiftUI
import WidgetKit

enum WidgetPreviewSize: String, CaseIterable, Identifiable {
    case small, medium, large
    var id: String { rawValue }
    var name: String { rawValue.capitalized }
    var passport: PassportSize { switch self { case .small: .small; case .medium: .medium; case .large: .large } }
    var height: CGFloat { switch self { case .small: 176; case .medium: 184; case .large: 384 } }
}

struct WidgetStudioView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @State private var draft: WidgetPreset
    @State private var size: WidgetPreviewSize = .large
    @State private var showInstall = false
    @State private var savedMessage = ""
    @State private var loadedDefault = false
    @State private var selectedPack: WidgetThemePack?
    @State private var deleting: WidgetPreset?
    var section: TeamKind
    init(initialContent: WidgetContent = .pokemon, initialSelection: String = "", section: TeamKind? = nil) {
        self.section = section ?? (initialContent == .showdownTeam ? .showdown : .ribbon)
        _draft = State(initialValue: WidgetPreset(name: initialContent.name, content: initialContent, selectionID: initialSelection, style: WidgetThemePack.defaultPack(for: initialContent).style))
    }
    private var theme: PassportTheme { PassportTheme(dark: scheme == .dark, game: "") }
    private var previewTheme: PassportTheme {
        let appearance = draft.style.appearance == .automatic ? store.snapshot.appearance : draft.style.appearance
        return PassportTheme(dark: appearance == .dark || (appearance == .automatic && scheme == .dark), game: previewPokemon.first?.currentgame ?? "", style: draft.style)
    }
    private var eligibleTeams: [RibbonTeam] { store.snapshot.teams(for: draft.content == .showdownTeam ? .showdown : .ribbon) }
    private var previewPokemon: [RibbonPokemon] {
        if draft.content == .pokemon {
            if !draft.selectionID.isEmpty { return store.snapshot.pokemon(for: .ribbon).filter { $0.id == draft.selectionID } }
            if store.snapshot.pokemon(for: .ribbon).isEmpty { return Array(SharedStore.demo().pokemon.prefix(1)) }
            return [store.snapshot.pokemon(for: .ribbon).first { $0.id == store.snapshot.selectedPokemonID(for: .ribbon) } ?? store.snapshot.pokemon(for: .ribbon)[0]]
        }
        if let team = store.snapshot.widgetTeam(for: draft.content == .showdownTeam ? .showdown : .ribbon, id: draft.selectionID.isEmpty ? nil : draft.selectionID) {
            return store.snapshot.members(teamID: team.id)
        }
        if !draft.selectionID.isEmpty { return [] }
        return draft.content == .showdownTeam ? SharedStore.showdownPreview().pokemon : SharedStore.demo().pokemon
    }
    private var previewName: String {
        if let t = eligibleTeams.first(where: { $0.id == draft.selectionID }) { return t.name }
        return store.snapshot.widgetTeam(for: draft.content == .showdownTeam ? .showdown : .ribbon)?.name ?? draft.content.name
    }
    private var isDemo: Bool { draft.selectionID.isEmpty && (draft.content == .pokemon ? store.snapshot.pokemon(for: .ribbon).isEmpty : eligibleTeams.isEmpty) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Widget studio").font(PixelFont.font(30))
                TerminalSelector(title: "Widget", selection: Binding(get: { draft.content }, set: { content in
                    draft = WidgetPreset(name: content.name, content: content, style: draft.style); savedMessage = ""
                    if content != .pokemon && size == .small { size = .medium }
                }), values: section.widgetContents, name: { $0.name })
                themePacks
                TerminalSelector(title: "Size", selection: $size, values: WidgetPreviewSize.allCases.filter { draft.content == .pokemon || $0 != .small }, name: { $0.name }, inline: true)
                HStack(spacing: 6) {
                    ForEach(Appearance.allCases, id: \.self) { appearance in
                        Button(appearance == .automatic ? "Auto" : appearance.rawValue.capitalized) { draft.style.appearance = appearance }
                            .font(PixelFont.font(15)).padding(9).frame(maxWidth: .infinity)
                            .background(draft.style.appearance == appearance ? theme.ink : theme.panel)
                            .foregroundStyle(draft.style.appearance == appearance ? theme.paper : theme.ink)
                            .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
                    }
                }.buttonStyle(.plain)
                if isDemo { Text("Demo preview").font(PixelFont.font(13)).foregroundStyle(theme.muted) }
                preview.frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 13) {
                    TextField("Design name", text: $draft.name).font(PixelFont.font(20)).textFieldStyle(TerminalFieldStyle())
                    selectionPicker
                    TerminalSelector(title: "Palette", selection: $draft.style.palette, values: WidgetPalette.allCases, name: { $0.name })
                    Toggle("Wallpaper", isOn: Binding(get: { draft.style.wallpaper != nil }, set: { draft.style.wallpaper = $0 ? WallpaperSettings() : nil }))
                    if draft.style.wallpaper != nil {
                        WallpaperControls(settings: Binding(get: { draft.style.wallpaper ?? WallpaperSettings() }, set: { draft.style.wallpaper = $0 }))
                    }
                    TerminalSelector(title: "Font", selection: $draft.style.typeface, values: WidgetTypeface.allCases, name: { $0.name })
                    HStack { Text("Text size"); Spacer(); Text("\(Int((draft.style.textScale * 100).rounded()))%") }
                    TerminalSlider(value: $draft.style.textScale, in: 0.85...1.15, step: 0.05).accessibilityLabel("Widget text size")
                    TerminalDisclosureGroup("Visible details") { detailToggles.padding(.top, 10) }
                    if draft.content != .showdownTeam {
                        TerminalSelector(title: "Ribbon order", selection: $draft.style.awardOrdering, values: AwardOrdering.allCases, name: { $0.name })
                    }
                }.font(PixelFont.font(16)).retroPanel()
                HStack(spacing: 8) {
                    Button("Save design") { save(false) }.frame(maxWidth: .infinity)
                    Button("Set default") { save(true) }.frame(maxWidth: .infinity)
                }.buttonStyle(RetroAction())
                Button("Add to Home Screen") { if save(false) { showInstall = true } }
                    .buttonStyle(RetroAction(prominent: true)).accessibilityIdentifier("widgets.addToHomeScreen")
                if !savedMessage.isEmpty { Text(savedMessage).font(PixelFont.font(14)).foregroundStyle(theme.accent).accessibilityAddTraits(.updatesFrequently) }
                if !sectionPresets.isEmpty { savedDesigns }
                Button("New design") {
                    draft = WidgetPreset(name: draft.content.name, content: draft.content, style: WidgetThemePack.defaultPack(for: draft.content).style); selectedPack = nil; savedMessage = ""
                }.buttonStyle(RetroAction())
            }.padding(16)
        }.background(theme.paper).navigationTitle("Widgets").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar).terminalBackControl()
            .onAppear {
                guard !loadedDefault else { return }; loadedDefault = true
                let selection = draft.selectionID
                if var preset = store.snapshot.preset(for: draft.content) {
                    preset.id = UUID().uuidString
                    if !selection.isEmpty { preset.selectionID = selection }
                    draft = preset
                    selectedPack = WidgetThemePack.allCases.first { $0.style == preset.style }
                }
            }
            .sheet(isPresented: $showInstall) { WidgetInstallHelp(preset: draft, size: size) }
            .terminalConfirmationDialog("Delete this design?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
                Button("Delete design", role: .destructive) {
                    if let deleting { store.deletePreset(deleting.id) }; deleting = nil
                }
            }
    }
    private var themePacks: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Theme packs").font(PixelFont.font(20))
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(WidgetThemePack.allCases) { pack in
                        Button {
                            selectedPack = pack
                            draft = WidgetPreset(name: pack.name, content: draft.content, selectionID: draft.selectionID, style: pack.style)
                            savedMessage = ""
                        } label: {
                            let packTheme = PassportTheme(dark: pack.style.appearance == .dark || (pack.style.appearance == .automatic && scheme == .dark), game: "", style: pack.style)
                            VStack(spacing: 6) {
                                HStack(spacing: 5) {
                                    Image(systemName: "square.grid.3x3.fill").font(.system(size: 22))
                                    Text("PC").font(PixelFont.font(29))
                                }.frame(height: 59).frame(maxWidth: .infinity)
                                Text(pack.name).font(PixelFont.font(15)).lineLimit(1).minimumScaleFactor(0.8)
                            }.padding(9).frame(width: 132).foregroundStyle(packTheme.ink)
                                .background { PixelWallpaperView(settings: pack.style.wallpaper ?? WallpaperSettings(), dark: packTheme.dark, base: packTheme.paper) }
                                .overlay(Rectangle().stroke(selectedPack == pack ? theme.accent : packTheme.border, lineWidth: selectedPack == pack ? 3 : 1))
                        }.buttonStyle(.plain).accessibilityLabel("\(pack.name) theme pack")
                    }
                }.padding(3)
            }
            if let selectedPack {
                Button("Set \(selectedPack.name) as section default") {
                    store.useThemePack(selectedPack, section: section)
                    if store.error == nil { savedMessage = "\(selectedPack.name) set for \(section.title.lowercased())" }
                }.buttonStyle(RetroAction()).font(PixelFont.font(15))
            }
        }
    }
    @ViewBuilder private var preview: some View {
        if previewPokemon.isEmpty {
            Text("Selection removed").font(PixelFont.font(18)).frame(height: size.height).frame(maxWidth: .infinity).retroPanel()
        } else {
            ConfiguredWidgetView(pokemon: previewPokemon, name: previewName, content: draft.content, size: size.passport, theme: previewTheme, download: true)
                .frame(maxWidth: size == .small ? 176 : 364).frame(height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: 24)).overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.border.opacity(0.4), lineWidth: 0.5))
                .environment(\.colorScheme, previewTheme.dark ? .dark : .light)
        }
    }
    @ViewBuilder private var selectionPicker: some View {
        if draft.content == .pokemon {
            SearchableChoicePicker(title: "Pokémon", value: $draft.selectionID,
                choices: RibbonCatalog.shared.dexOrdered(store.snapshot.pokemon(for: .ribbon)).map { SearchChoice(id: $0.id, name: $0.displayName, aliases: [$0.species]) }, emptyLabel: "App selection")
        } else {
            SearchableChoicePicker(title: "Team", value: $draft.selectionID,
                choices: eligibleTeams.map { SearchChoice(id: $0.id, name: $0.name) }, emptyLabel: "App selection")
        }
    }

    private var detailToggles: some View {
        VStack(spacing: 10) {
            Toggle("Shiny icon", isOn: $draft.style.showShiny)
            Toggle("Level", isOn: $draft.style.showLevel)
            if draft.content == .showdownTeam {
                Toggle("Held item", isOn: $draft.style.showItem)
                Toggle("Ability", isOn: $draft.style.showAbility)
                Toggle("Tera type", isOn: $draft.style.showTera)
                Toggle("Nature · large", isOn: $draft.style.showNature)
                Toggle("Moves · large", isOn: $draft.style.showMoves)
            } else {
                Toggle("Equipped title", isOn: $draft.style.showTitle)
                Toggle("Game", isOn: $draft.style.showGame)
                Toggle("Origin console", isOn: $draft.style.showConsole)
                Toggle("Ribbons & marks", isOn: $draft.style.showAwards)
                if draft.content == .pokemon { Toggle("Generation stamps · large", isOn: $draft.style.showJourney) }
            }
        }
    }
    private var sectionPresets: [WidgetPreset] { (store.snapshot.widgetPresets ?? []).filter { section.widgetContents.contains($0.content) } }
    private var savedDesigns: some View {
        VStack(spacing: 10) {
            RetroHeading(title: "Saved designs", value: "\(sectionPresets.count)")
            ForEach(sectionPresets) { preset in
                HStack {
                    Button {
                        // Changing the content picker normally starts a new design; restore the whole preset after that update.
                        draft = preset; selectedPack = WidgetThemePack.allCases.first { $0.style == preset.style }; savedMessage = ""
                        if preset.content != .pokemon && size == .small { size = .medium }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.name).font(PixelFont.font(19))
                            Text(preset.content.name).font(PixelFont.font(12)).foregroundStyle(theme.muted)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.buttonStyle(.plain)
                    if store.snapshot.widgetDefaults?[preset.content.rawValue] == preset.id { Image(systemName: "checkmark.circle.fill").foregroundStyle(theme.accent) }
                    Button { deleting = preset } label: { Image(systemName: "trash").frame(width: 36, height: 44) }.accessibilityLabel("Delete \(preset.name)")
                }.retroPanel(padding: 10)
            }
        }
    }
    @discardableResult private func save(_ makeDefault: Bool) -> Bool {
        let trimmed = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { savedMessage = "Enter a design name"; return false }
        draft.name = trimmed; store.savePreset(draft, makeDefault: makeDefault)
        guard store.error == nil else { return false }
        savedMessage = makeDefault ? "Default design saved" : "Design saved"; return true
    }
}

struct WidgetInstallHelp: View {
    var preset: WidgetPreset
    var size: WidgetPreviewSize
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("\(preset.content.name) · \(size.name)").font(PixelFont.font(25))
                    step(1, "Hold an empty area on the Home Screen.")
                    step(2, "Edit → Add Widget → Ribbon Passport.")
                    step(3, "Choose \(preset.content.name), select \(size.name), then Add Widget.")
                    step(4, "Hold the widget → Edit Widget → Saved design → \(preset.name).")
                    Text("iOS requires you to complete these steps on the Home Screen.").font(PixelFont.font(15)).foregroundStyle(.secondary)
                    Link("Apple’s widget instructions", destination: URL(string: "https://support.apple.com/en-gb/118610")!)
                }.padding(20)
            }.font(PixelFont.font(18)).navigationTitle("Add widget").navigationBarTitleDisplayMode(.inline)
                .toolbar { TerminalToolbarItem(placement: .topBarTrailing) { TerminalCornerButton("Done") { dismiss() }  } }
        }
    }
    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) { Text("\(number)").font(PixelFont.font(24)).frame(width: 22); Text(text).fixedSize(horizontal: false, vertical: true) }
    }
}
