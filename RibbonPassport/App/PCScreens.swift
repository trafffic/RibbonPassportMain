import SwiftUI

extension AppStore {
    func editStorage(kind: TeamKind = .ribbon, _ change: (inout StorageLayout) -> Void) {
        var next = snapshot
        var layout = next.storage(for: kind)
        change(&layout)
        layout.reconcile(pokemonIDs: next.pokemon(for: kind).map(\.id))
        if kind == .ribbon { next.storage = layout } else { next.competitiveStorage = layout }; commit(next)
    }
    @discardableResult func movePokemon(_ id: String, kind: TeamKind, boxID: String, slot: Int) -> Bool {
        var next = snapshot
        guard next.movePokemon(id, in: kind, toBox: boxID, slot: slot) else { return false }
        commit(next); return error == nil
    }
    @discardableResult func movePokemonToParty(_ id: String, kind: TeamKind, slot: Int) -> Bool {
        var next = snapshot
        guard next.movePokemonToParty(id, in: kind, slot: slot) else { return false }
        commit(next); return error == nil
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    var kind: TeamKind = .ribbon
    @AppStorage private var partyVisible: Bool
    init(kind: TeamKind = .ribbon) {
        self.kind = kind
        _partyVisible = AppStorage(wrappedValue: false, "pc.\(kind.key).partyVisible")
    }
    @State private var boxIndex = 0
    @State private var choosingBox = false
    @State private var adding = false
    @State private var editingWallpaper = false
    @State private var importing = false
    @State private var showdown = false
    @State private var moving = false
    @State private var renaming = false
    @State private var boxName = ""
    @State private var drag: PCSpriteDrag?
    @State private var slotFrames: [PCSlotTarget: CGRect] = [:]
    @State private var settlingTask: Task<Void, Never>?
    @GestureState private var dragTouchActive = false
    @State private var hoveredPage: Int?
    @State private var exporting: PokemonExportSelection?
    @State private var passportSection: PassportSection = .overview
    private var theme: PassportTheme { PassportTheme(dark: scheme == .dark, game: "", style: WidgetStyle(palette: .sage)) }
    private var dragSpace: String { "pc-storage-" + kind.key }
    private var layout: StorageLayout { store.snapshot.storage(for: kind) }
    private var box: PCBox { layout.boxes[min(boxIndex, layout.boxes.count - 1)] }
    private var selection: RibbonPokemon? { store.snapshot.pokemon.first { $0.id == store.snapshot.selectedPokemonID(for: kind) } }
    private func pokemon(_ id: String?) -> RibbonPokemon? { store.snapshot.pokemon(for: kind).first { $0.id == id } }
    private var pokemonRoute: Binding<String?> {
        Binding(get: { store.snapshot.section(forPokemon: store.openPokemonID ?? "") == kind ? store.openPokemonID : nil }, set: { id in
            if id != nil || store.snapshot.section(forPokemon: store.openPokemonID ?? "") == kind { store.openPokemonID = id }
            if id == nil { passportSection = .overview }
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
            GeometryReader { viewport in
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text(kind.title.uppercased()).font(PixelFont.font(25))
                        Spacer(minLength: 4)
                        TerminalMenu(compact: true) {
                            TerminalMenuLink("Teams") { RetroTeamsView(kind: kind) }
                            TerminalMenuLink("Widgets") { WidgetStudioView(initialContent: kind == .showdown ? .showdownTeam : .pokemon, section: kind) }
                            Button("Add Pokémon", systemImage: "plus.circle") { adding = true }
                            if kind == .ribbon {
                                Button("Import backup", systemImage: "square.and.arrow.down") { importing = true }
                                Button("Export Ribbon Masters", systemImage: "square.and.arrow.up") {
                                    exporting = PokemonExportSelection(pokemon: store.snapshot.pokemon(for: .ribbon), target: .ribbonsGuide)
                                }.disabled(store.snapshot.pokemon(for: .ribbon).isEmpty)
                                Button("Refresh demo", systemImage: "sparkles") { store.demo() }
                            } else { Button("Import Showdown team", systemImage: "doc.on.clipboard") { showdown = true } }
                            Button("New box", systemImage: "plus.square") {
                                store.editStorage(kind: kind) { $0.boxes.append(PCBox(name: String(format: "Box %02d", $0.boxes.count + 1))) }
                                boxIndex = layout.boxes.count - 1
                            }
                        } label: { TerminalCornerLabel(title: "Options") }.buttonStyle(.plain).accessibilityLabel("Collection options")
                    }
                    if store.snapshot.pokemon(for: kind).isEmpty { emptyCollection }
                    HStack {
                        Text("POKÉMON STORAGE")
                        Spacer()
                        Text("\(box.slots.compactMap { $0 }.count) / 30")
                    }.font(PixelFont.font(13)).foregroundStyle(theme.muted)
                    VStack(spacing: 10) {
                        PCWorkspaceLayout(showsParty: partyVisible) {
                            if partyVisible { partyBar.frame(width: 43) }
                            boxGrid
                        }
                        if let p = selection {
                            selectionStrip(p)
                            if kind == .ribbon { ribbonStrip(p) }
                        }
                        boxSwitcher
                    }.padding(8).background(theme.board, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.border, lineWidth: 1))
                    Spacer(minLength: 0)
                    HStack {
                        Button { choosingBox = true } label: { Label("All boxes", systemImage: "square.grid.2x2") }
                        Spacer()
                        TerminalMenu {
                            Button("Wallpaper") { editingWallpaper = true }
                            Button("Rename box") { boxName = box.name; renaming = true }
                            Button("New box") {
                                store.editStorage(kind: kind) { $0.boxes.append(PCBox(name: String(format: "Box %02d", $0.boxes.count + 1))) }
                                boxIndex = layout.boxes.count - 1
                            }
                        } label: { Label("Box options", systemImage: "photo") }
                        .accessibilityIdentifier("pc.boxOptions")
                    }.font(PixelFont.font(14)).foregroundStyle(theme.muted).buttonStyle(.plain)
                    if moving { Text("Select a destination slot").font(PixelFont.font(14)).foregroundStyle(theme.accent) }
                }.padding(16).frame(minHeight: viewport.size.height, alignment: .top)
            }.scrollDisabled(drag != nil)
                .overlay(alignment: .topLeading) { dragSprites.allowsHitTesting(false).accessibilityHidden(true) }
                .coordinateSpace(name: dragSpace)
                .onPreferenceChange(PCSlotFrames.self) { slotFrames = $0 }
                .onChange(of: dragTouchActive) { _, active in
                    if !active {
                        Task { @MainActor in
                            await Task.yield()
                            if !dragTouchActive, drag?.settling == false { finishDrag(cancelled: true) }
                        }
                    }
                }
                .onChange(of: scenePhase) { _, phase in if phase != .active { clearDrag() } }
                .onDisappear { clearDrag() }
                .background(theme.paper).toolbar(.hidden, for: .navigationBar)
                .navigationDestination(item: pokemonRoute) { id in
                    if let p = pokemon(id), p.showdownSet != nil { CompetitiveBuildView(pokemonID: id) }
                    else { StampAlbumView(pokemonID: id, section: passportSection) }
                }
                .navigationDestination(item: teamRoute) { id in RetroTeamDetailView(teamID: id) }
                .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                    switch result { case .success(let url): store.importBackup(url); case .failure(let e): store.error = e.localizedDescription }
                }
                .sheet(isPresented: $adding) { AddPokemonView(boxID: box.id, kind: kind) { id in
                    if let index = layout.boxes.firstIndex(where: { $0.slots.contains(id) }) { boxIndex = index }
                } }
                .sheet(isPresented: $choosingBox) { boxPicker }
                .sheet(isPresented: $editingWallpaper) { BoxWallpaperEditor(box: box, settings: layout.wallpaper(for: box), kind: kind) }
                .sheet(item: $exporting) { PokemonExportView(selection: $0) }
                .task(id: hoveredPage) {
                    guard let direction = hoveredPage, drag?.settling == false, layout.boxes.count > 1 else { return }
                    do { try await Task.sleep(for: .milliseconds(650)) } catch { return }
                    guard !Task.isCancelled, hoveredPage == direction, drag?.settling == false else { return }
                    boxIndex = (boxIndex + layout.boxes.count + direction) % layout.boxes.count
                    drag?.target = nil
                }
                .sheet(isPresented: $showdown) { RetroShowdownImportView() }
                .terminalAlert("Box name", isPresented: $renaming) {
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
    }
    private var emptyCollection: some View {
        VStack(spacing: 10) {
            Text("No Pokémon").font(PixelFont.font(22))
            Button("Add Pokémon") { adding = true }
        }.buttonStyle(RetroAction()).frame(maxWidth: .infinity).retroPanel()
    }
    private var boxHeader: some View {
        HStack(spacing: 2) {
            Button { boxIndex = (boxIndex + layout.boxes.count - 1) % layout.boxes.count } label: {
                Image(systemName: "chevron.left").frame(width: 28, height: 36)
            }.accessibilityLabel("Previous box").trackPCSlot(.page(-1), space: dragSpace)
            Button { boxName = box.name; renaming = true } label: {
                Text(box.name.uppercased()).font(PixelFont.font(15)).lineLimit(1).minimumScaleFactor(0.7).frame(maxWidth: .infinity, alignment: .leading)
            }.accessibilityLabel("Rename \(box.name)")
            Button { withAnimation(.easeInOut(duration: 0.2)) { partyVisible.toggle() } } label: {
                Text("Party").font(PixelFont.font(13)).frame(minWidth: 44, minHeight: 36)
            }.accessibilityIdentifier("pc.partyToggle").accessibilityValue(partyVisible ? "Shown" : "Hidden")
            Button { boxIndex = (boxIndex + 1) % layout.boxes.count } label: {
                Image(systemName: "chevron.right").frame(width: 28, height: 36)
            }.accessibilityLabel("Next box").trackPCSlot(.page(1), space: dragSpace)
        }.buttonStyle(.plain).foregroundStyle(Color.white)
    }
    private var boxGrid: some View {
        GeometryReader { geometry in
            let gridWidth = geometry.size.width * PCGridMetrics.gridWidth / PCGridMetrics.artworkWidth
            let gridHeight = geometry.size.height * PCGridMetrics.gridHeight / PCGridMetrics.artworkHeight
            ZStack(alignment: .topLeading) {
                BoxWallpaperView(settings: layout.wallpaper(for: box), fullArtwork: true)
                boxHeader.frame(width: geometry.size.width * 0.83, height: geometry.size.height * 0.15)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.093)
                VStack(spacing: 0) {
                    ForEach(0..<PCGridMetrics.rows, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<PCGridMetrics.columns, id: \.self) { column in
                                boxSlot(row * PCGridMetrics.columns + column, width: gridWidth / 6, height: gridHeight / 5)
                            }
                        }
                    }
                }.frame(width: gridWidth, height: gridHeight)
                    .offset(x: geometry.size.width * PCGridMetrics.originX / PCGridMetrics.artworkWidth,
                            y: geometry.size.height * PCGridMetrics.originY / PCGridMetrics.artworkHeight)
            }
        }.aspectRatio(PCGridMetrics.artworkWidth / PCGridMetrics.artworkHeight, contentMode: .fit)
            .frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 6))
    }
    private var boxSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(layout.boxes.enumerated()), id: \.element.id) { index, entry in
                    Button { boxIndex = index } label: {
                        Text(entry.name.uppercased()).font(PixelFont.font(12)).lineLimit(1)
                            .padding(.horizontal, 7).frame(minHeight: 36)
                            .overlay(alignment: .bottom) { if index == boxIndex { Rectangle().fill(theme.accent).frame(height: 2) } }
                    }.accessibilityIdentifier("pc.box.select.\(index)").accessibilityAddTraits(index == boxIndex ? .isSelected : [])
                }
            }
        }.buttonStyle(.plain)
    }
    private var boxPicker: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                    ForEach(Array(layout.boxes.enumerated()), id: \.element.id) { index, entry in
                        Button { boxIndex = index; choosingBox = false } label: {
                            VStack(alignment: .leading, spacing: 7) {
                                BoxWallpaperView(settings: layout.wallpaper(for: entry), fullArtwork: true).aspectRatio(208.0 / 192, contentMode: .fit)
                                HStack { Text(entry.name); Spacer(); Text("\(entry.slots.compactMap { $0 }.count)/30") }
                                    .font(PixelFont.font(14))
                            }.padding(6).background(theme.panel).overlay(Rectangle().stroke(index == boxIndex ? theme.accent : theme.border, lineWidth: index == boxIndex ? 2 : 1))
                        }.buttonStyle(.plain).accessibilityIdentifier("pc.boxPicker.\(index)")
                    }
                }.padding(16)
            }.background(theme.paper).navigationTitle("All boxes").navigationBarTitleDisplayMode(.inline)
                .toolbar { TerminalToolbarItem(placement: .topBarTrailing) { TerminalCornerButton("Done") { choosingBox = false }  } }
        }
    }
    private func ribbonStrip(_ p: RibbonPokemon) -> some View {
        Button { passportSection = .ribbons; store.openPokemonID = p.id } label: {
            HStack(spacing: 12) {
                ForEach(Array(p.displayedRibbonIDs.prefix(4)), id: \.self) { id in AssetImage(key: "award-" + id).frame(width: 23, height: 27) }
                Spacer(minLength: 0)
                Text("\(p.displayedRibbonIDs.count) awards ›").font(PixelFont.font(14))
            }.padding(.vertical, 9).contentShape(Rectangle())
        }.buttonStyle(.plain).foregroundStyle(theme.muted).accessibilityIdentifier("ribbons.manage")
            .overlay(alignment: .top) { Rectangle().fill(theme.border).frame(height: 1) }
    }
    private func boxSlot(_ slot: Int, width: CGFloat, height: CGFloat) -> some View {
        let p = pokemon(box.slots[slot])
        let target = PCSlotTarget.box(box.id, slot)
        return Button {
            if moving, let id = selection?.id { animateMove(id, to: target) }
            else if let p { store.choose(p.id) }
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Color.clear
                if let p {
                    PokemonSprite(pokemon: p, download: true).padding(4).opacity(spriteOpacity(p.id))
                    if p.shiny { AssetImage(key: "shiny-" + theme.appearance).frame(width: 10, height: 10).padding(3).opacity(spriteOpacity(p.id)) }
                }
            }.frame(width: width, height: height).contentShape(Rectangle())
                .background(drag?.target == target ? theme.panel.opacity(0.35) : drag == nil && p?.id == selection?.id && p != nil ? theme.panel.opacity(0.28) : .clear)
                .overlay {
                    if drag?.target == target || (drag == nil && p != nil && p?.id == selection?.id) {
                        Rectangle().strokeBorder(theme.accent, lineWidth: 2)
                    }
                }
        }.buttonStyle(.plain).accessibilityLabel(p?.displayName ?? "Empty slot \(slot + 1)")
            .accessibilityIdentifier("pc.box.slot.\(slot)").accessibilityValue(p?.id ?? "Empty")
            .trackPCSlot(target, space: dragSpace)
            .highPriorityGesture(spriteDrag(pokemon: p, source: target), including: p != nil || drag != nil ? .all : .none)
            .accessibilityHint("Drag to move, or choose Move in Pokémon actions")
    }
    private var partyBar: some View {
        GeometryReader { geometry in
            VStack(spacing: 3) {
                Text("PARTY").font(PixelFont.font(10)).foregroundStyle(theme.muted)
                    .frame(height: geometry.size.height * 0.15)
                ForEach(0..<6, id: \.self) { i in
                    let p = i < layout.partyIDs.count ? pokemon(layout.partyIDs[i]) : nil
                    let target = PCSlotTarget.party(i)
                    Button {
                        if moving, let id = selection?.id { animateMove(id, to: target) }
                        else if let p { store.choose(p.id) }
                        else if let id = selection?.id { store.editStorage(kind: kind) { _ = $0.moveToParty(id) } }
                    } label: {
                        Group {
                            if let p { PokemonSprite(pokemon: p, download: true).padding(3).opacity(spriteOpacity(p.id)) }
                            else { Color.clear }
                        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(theme.panel, in: RoundedRectangle(cornerRadius: 3))
                            .overlay { if drag?.target == target { Rectangle().stroke(theme.accent, lineWidth: 2) } }
                    }.buttonStyle(.plain).accessibilityLabel(p?.displayName ?? "Empty party slot")
                        .accessibilityIdentifier("pc.party.slot.\(i)").accessibilityValue(p?.id ?? "Empty")
                        .trackPCSlot(target, space: dragSpace)
                        .highPriorityGesture(spriteDrag(pokemon: p, source: target), including: p != nil || drag != nil ? .all : .none)
                }
            }.padding(3)
        }.background(theme.board)
    }
    @ViewBuilder private func pokemonMenu(_ p: RibbonPokemon) -> some View {
        Button(kind == .ribbon ? "Open passport" : "Open build") { passportSection = .overview; store.openPokemonID = p.id }
        Button(moving ? "Cancel move" : "Move") { moving.toggle() }
        if layout.partyIDs.contains(p.id) { Button("Return to box") { store.editStorage(kind: kind) { $0.returnToBox(p.id) } } }
        Button("Add to party") { store.editStorage(kind: kind) { _ = $0.moveToParty(p.id) }; partyVisible = true }
            .disabled(layout.partyIDs.count >= 6 || layout.partyIDs.contains(p.id))
        Button("Export Pokémon", systemImage: "square.and.arrow.up") {
            exporting = PokemonExportSelection(pokemon: [p], target: kind == .ribbon ? .ribbonsGuide : .showdown)
        }
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
            Button(kind == .ribbon ? "Passport ▸" : "Build ▸") { passportSection = .overview; store.openPokemonID = p.id }.font(PixelFont.font(13)).buttonStyle(.plain)
            TerminalMenu(compact: true) { pokemonMenu(p) } label: { TerminalCornerLabel(title: "Edit") }.accessibilityLabel("Pokémon actions")
        }.padding(9).background(theme.panel, in: RoundedRectangle(cornerRadius: 4))
    }
    @ViewBuilder private var dragSprites: some View {
        if let drag {
            if let displaced = drag.displaced {
                PCSlidingSprite(pokemon: displaced, diameter: drag.diameter, start: drag.displacedPosition, end: drag.sourceFrame.center, reduceMotion: reduceMotion)
            }
            PokemonSprite(pokemon: drag.pokemon).frame(width: drag.diameter, height: drag.diameter)
                .shadow(color: theme.ink.opacity(0.16), radius: 1, y: 2)
                .position(x: drag.position.x, y: drag.position.y - (drag.settling ? 0 : 2))
                .accessibilityHidden(true)
        }
    }
    private func spriteOpacity(_ id: String) -> Double {
        if drag?.pokemon.id == id { return 0.08 }
        if drag?.displaced?.id == id { return 0 }
        return 1
    }
    private func spriteDrag(pokemon p: RibbonPokemon?, source: PCSlotTarget) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(dragSpace))
            .updating($dragTouchActive) { _, active, _ in active = true }
            .onChanged { value in
                guard drag?.settling != true else { return }
                if drag == nil {
                    guard let p, let frame = slotFrames[source] else { return }
                    drag = PCSpriteDrag(pokemon: p, source: source, sourceFrame: frame, position: value.location)
                }
                drag?.position = value.location
                updateDragTarget(at: value.location)
            }
            .onEnded { value in updateDragTarget(at: value.location); finishDrag() }
    }
    private func updateDragTarget(at point: CGPoint) {
        guard let drag, !drag.settling else { return }
        let target = PCSlotTarget.hit(at: point, frames: slotFrames)
        if case .page(let direction) = target, layout.boxes.count > 1 {
            hoveredPage = direction; self.drag?.target = nil
        } else {
            hoveredPage = nil
            self.drag?.target = target.flatMap { canMove(drag.pokemon.id, to: $0) ? $0 : nil }
        }
    }
    private func canMove(_ id: String, to target: PCSlotTarget) -> Bool {
        guard store.snapshot.section(forPokemon: id) == kind else { return false }
        var trial = layout
        switch target {
        case .box(let box, let slot): return trial.move(id, toBox: box, slot: slot)
        case .party(let slot): return trial.moveToParty(id, slot: slot)
        case .page: return false
        }
    }
    @discardableResult private func commitMove(_ id: String, to target: PCSlotTarget) -> Bool {
        switch target {
        case .box(let box, let slot): return store.movePokemon(id, kind: kind, boxID: box, slot: slot)
        case .party(let slot): return store.movePokemonToParty(id, kind: kind, slot: slot)
        case .page: return false
        }
    }
    private func animateMove(_ id: String, to target: PCSlotTarget) {
        guard drag == nil, let p = pokemon(id), canMove(id, to: target) else { return }
        let source: PCSlotTarget?
        if let party = layout.partyIDs.firstIndex(of: id) { source = .party(party) }
        else if let box = layout.boxes.first(where: { $0.slots.contains(id) }), let slot = box.slots.firstIndex(of: id) { source = .box(box.id, slot) }
        else { source = nil }
        guard let source, let frame = slotFrames[source] else {
            if commitMove(id, to: target) { moving = false }
            return
        }
        drag = PCSpriteDrag(pokemon: p, source: source, sourceFrame: frame, position: frame.center)
        drag?.target = target
        finishDrag()
    }
    private func finishDrag(cancelled: Bool = false) {
        guard let session = drag, !session.settling else { return }
        hoveredPage = nil
        let target = cancelled ? nil : session.target
        let destination = target.flatMap { slotFrames[$0] }
        let willMove = target != nil && target != session.source && destination != nil && canMove(session.pokemon.id, to: target!)
        if !willMove, case .box(let sourceBox, _) = session.source,
           let index = layout.boxes.firstIndex(where: { $0.id == sourceBox }) { boxIndex = index }
        drag?.settling = true
        if willMove, let target, let destination {
            let displaced: String?
            switch target {
            case .box(let boxID, let slot): displaced = layout.boxes.first(where: { $0.id == boxID })?.slots[slot]
            case .party(let slot): displaced = slot < layout.partyIDs.count ? layout.partyIDs[slot] : nil
            case .page: displaced = nil
            }
            if let displaced, displaced != session.pokemon.id {
                drag?.displaced = pokemon(displaced); drag?.displacedPosition = destination.center
            }
        }
        let animation: Animation? = reduceMotion ? nil : .timingCurve(0.2, 0.7, 0.25, 1, duration: 0.14)
        withAnimation(animation) {
            drag?.position = willMove ? destination!.center : session.sourceFrame.center
        }
        settlingTask = Task { @MainActor in
            if !reduceMotion { do { try await Task.sleep(for: .milliseconds(140)) } catch { return } }
            guard !Task.isCancelled, drag?.pokemon.id == session.pokemon.id else { return }
            if willMove, let target {
                if commitMove(session.pokemon.id, to: target) { moving = false }
                else {
                    if case .box(let sourceBox, _) = session.source,
                       let index = layout.boxes.firstIndex(where: { $0.id == sourceBox }) { boxIndex = index }
                    withAnimation(animation) { drag?.position = session.sourceFrame.center; drag?.displaced = nil }
                    if !reduceMotion { do { try await Task.sleep(for: .milliseconds(140)) } catch { return } }
                }
            }
            clearDrag()
        }
    }
    private func clearDrag() {
        settlingTask?.cancel(); settlingTask = nil; drag = nil; hoveredPage = nil
    }
}

/// Both the party rail and artwork receive the same height, derived from the box width.
private struct PCWorkspaceLayout: Layout {
    var showsParty: Bool
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        let boxWidth = max(1, width - (showsParty ? 50 : 0))
        return CGSize(width: width, height: boxWidth * PCGridMetrics.artworkHeight / PCGridMetrics.artworkWidth)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let board = subviews.last else { return }
        if showsParty, subviews.count > 1 {
            subviews[0].place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(width: 43, height: bounds.height))
        }
        let inset: CGFloat = showsParty ? 50 : 0
        board.place(at: CGPoint(x: bounds.minX + inset, y: bounds.minY), anchor: .topLeading,
                    proposal: ProposedViewSize(width: bounds.width - inset, height: bounds.height))
    }
}

enum PCSlotTarget: Hashable {
    case box(String, Int), party(Int), page(Int)
    static func hit(at point: CGPoint, frames: [Self: CGRect]) -> Self? {
        frames.first { !$0.value.isEmpty && $0.value.contains(point) }?.key
    }
}
private struct PCSlotFrames: PreferenceKey {
    static var defaultValue: [PCSlotTarget: CGRect] { [:] }
    static func reduce(value: inout [PCSlotTarget: CGRect], nextValue: () -> [PCSlotTarget: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}
private extension View {
    func trackPCSlot(_ target: PCSlotTarget, space: String) -> some View {
        background {
            GeometryReader { geometry in Color.clear.preference(key: PCSlotFrames.self, value: [target: geometry.frame(in: .named(space))]) }
        }
    }
}
private extension CGRect { var center: CGPoint { CGPoint(x: midX, y: midY) } }
private struct PCSpriteDrag {
    var pokemon: RibbonPokemon
    var source: PCSlotTarget
    var sourceFrame: CGRect
    var position: CGPoint
    var target: PCSlotTarget?
    var settling = false
    var displaced: RibbonPokemon?
    var displacedPosition = CGPoint.zero
    var diameter: CGFloat { min(40, min(sourceFrame.width, sourceFrame.height) - 4) }
}
private struct PCSlidingSprite: View {
    var pokemon: RibbonPokemon
    var diameter: CGFloat
    var start: CGPoint
    var end: CGPoint
    var reduceMotion: Bool
    @State private var landed = false
    var body: some View {
        PokemonSprite(pokemon: pokemon).frame(width: diameter, height: diameter)
            .position(landed ? end : start)
            .onAppear { withAnimation(reduceMotion ? nil : .timingCurve(0.2, 0.7, 0.25, 1, duration: 0.14)) { landed = true } }
    }
}

struct AwardLocationSelection: Identifiable { var id: String }
enum PassportSection: String, CaseIterable { case overview = "Overview", ribbons = "Ribbons", journey = "Journey" }

struct StampAlbumView: View {
    var pokemonID: String
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @State var section: PassportSection = .overview
    @State private var stampPage = 0
    @State private var earnedPage = 0
    @State private var visitPage = 0
    @State private var generation = 0
    @State private var game = ""
    @AppStorage("album.grouping") private var grouping: AlbumGrouping = .generations
    @State private var exporting: PokemonExportSelection?
    @State private var editing = false
    @State private var editingVisits = false
    @State private var selectedAward: AwardLocationSelection?
    @State private var describedAward: AwardLocationSelection?
    @State private var descriptionHeight: CGFloat = 120
    @State private var reviewingTransfer = false
    @State private var transferUndo: RibbonPokemon?
    private var p: RibbonPokemon? { store.snapshot.pokemon.first { $0.id == pokemonID } }
    private var theme: PassportTheme { PassportTheme(dark: scheme == .dark, game: p?.currentgame ?? "") }
    private var pokemonBinding: Binding<RibbonPokemon> {
        Binding(get: { p! }, set: { store.update($0) })
    }
    var body: some View {
        Group {
            if let p {
                VStack(spacing: 0) {
                    if section == .overview { hero(p).padding(.horizontal, 16).padding(.vertical, 12) }
                    HStack(spacing: 8) {
                        ForEach(PassportSection.allCases, id: \.self) { tab in
                            Button { describedAward = nil; section = tab } label: {
                                Text(tab.rawValue).font(PixelFont.font(16)).frame(maxWidth: .infinity, minHeight: 44)
                                    .foregroundStyle(section == tab ? theme.accent : theme.muted)
                                    .overlay(alignment: .bottom) { if section == tab { Rectangle().fill(theme.accent).frame(height: 2) } }
                            }.buttonStyle(.plain).accessibilityIdentifier("passport.tab.\(tab.rawValue.lowercased())")
                                .accessibilityAddTraits(section == tab ? .isSelected : [])
                        }
                    }.padding(.horizontal, 16).overlay(alignment: .bottom) { Rectangle().fill(theme.border).frame(height: 1) }
                    if section == .ribbons {
                        RibbonManager(pokemon: pokemonBinding, entryTitle: "Passport", embedded: true) { section = .overview }
                    } else if section == .journey {
                        journey(p).padding(16)
                    } else {
                        ScrollView { overview(p).padding(16) }
                    }
                }
            } else { ContentUnavailableView("Pokémon removed", systemImage: "tray") }
        }
        .overlayPreferenceValue(RibbonDescriptionAnchors.self) { anchors in
            GeometryReader { geometry in
                if section == .overview, let id = describedAward?.id, let anchor = anchors[id] {
                    let target = geometry[anchor]
                    let placement = RibbonBubblePlacement(container: geometry.size, anchor: target, contentHeight: descriptionHeight)
                    ZStack(alignment: .topLeading) {
                        Color.clear.contentShape(RibbonBubbleOutsideShape(holes: anchors.values.map { geometry[$0] }), eoFill: true)
                            .onTapGesture { describedAward = nil }.accessibilityHidden(true)
                        RibbonDescriptionBubble(awardID: id)
                            .frame(width: placement.frame.width, height: placement.frame.height)
                            .background(theme.panel, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.border, lineWidth: 1))
                            .overlay(alignment: .topLeading) {
                                RibbonBubblePointer(pointsDown: placement.above)
                                    .fill(placement.above ? theme.panel : theme.board)
                                    .overlay { RibbonBubblePointer(pointsDown: placement.above, borderOnly: true).stroke(theme.border, lineWidth: 1) }
                                    .frame(width: 14, height: 8)
                                    .offset(x: placement.tipX - 7, y: placement.above ? placement.frame.height - 1 : -7)
                            }
                            .shadow(color: theme.ink.opacity(0.12), radius: 4, y: 2)
                            .contentShape(Rectangle()).onTapGesture { }
                            .position(x: placement.frame.midX, y: placement.frame.midY)
                            .accessibilityAction(.escape) { describedAward = nil }
                    }
                    .onPreferenceChange(RibbonDescriptionHeight.self) { height in
                        if height > 0, abs(height - descriptionHeight) > 0.5 { descriptionHeight = height }
                    }
                }
            }
        }
        .background(theme.paper).foregroundStyle(theme.ink).navigationTitle("Passport").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar).terminalBackControl()
            .toolbar {
                TerminalToolbarItem(placement: .principal) { Text(section == .ribbons ? p?.displayName.uppercased() ?? "PASSPORT" : "PASSPORT").font(PixelFont.font(20)).lineLimit(1) }
                TerminalToolbarItem(placement: .topBarTrailing) {
                    TerminalMenu(compact: true) {
                        Button("Edit Pokémon") { editing = true }
                        Button("Edit visits") { editingVisits = true }
                        Button("Export", systemImage: "square.and.arrow.up") {
                            if let p { exporting = PokemonExportSelection(pokemon: [p], target: .ribbonsGuide) }
                        }
                        TerminalMenuLink("Saved versions") { RecoveryItemHistoryView(kind: .pokemon, objectID: pokemonID) }
                    } label: { TerminalCornerLabel(title: "Options") }.accessibilityLabel("Passport options")
                }
            }
            .sheet(item: $exporting) { PokemonExportView(selection: $0) }
            .sheet(isPresented: $editing) { if let p { NavigationStack { PokemonEditor(pokemon: p) }.font(PixelFont.font(16)) } }
            .sheet(isPresented: $editingVisits) { JourneyEditorView(pokemonID: pokemonID) }
            .sheet(item: $selectedAward) { choice in AwardLocationEditor(pokemonID: pokemonID, initialAward: choice.id) }
            .sheet(isPresented: $reviewingTransfer) {
                if let p {
                    RibbonTransferDrawer(pokemon: p, game: p.currentgame, check: RibbonRules.shared.transferCheck(from: p.currentgame, pokemon: p), canUndo: transferUndo != nil, onRecord: { id, game in
                        guard var updated = self.p else { return }
                        let previous = updated
                        if updated.recordRibbon(id, game: game) { store.update(updated); if store.error == nil { transferUndo = previous } }
                    }, onUndo: {
                        if let previous = transferUndo { store.update(previous); if store.error == nil { transferUndo = nil } }
                    }, onDone: { reviewingTransfer = false })
                }
            }
    }
    private func hero(_ p: RibbonPokemon) -> some View {
        HStack(spacing: 15) {
            PokemonSprite(pokemon: p, download: true).frame(width: 70, height: 70)
            VStack(alignment: .leading, spacing: 6) {
                PokemonName(pokemon: p, theme: theme, size: 25)
                EquippedTitleLabel(pokemon: p, theme: theme).font(PixelFont.font(14))
                Text("Lv. \(p.currentlevel) · \(p.displayedRibbonIDs.count) awards").font(PixelFont.font(13)).foregroundStyle(theme.muted)
            }
            Spacer(minLength: 0)
        }
    }
    private func overview(_ p: RibbonPokemon) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                endpoint("ORIGIN", game: p.origingame)
                endpoint("CURRENT", game: p.currentgame)
            }.padding(.vertical, 10)
            Divider()
            Button { section = .ribbons } label: {
                HStack { Text("Owned awards").font(PixelFont.font(19)); Spacer(); Text("\(p.displayedRibbonIDs.count) ›").font(PixelFont.font(14)) }
            }.buttonStyle(.plain).accessibilityIdentifier("passport.owned")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 18) {
                ForEach(Array(p.displayedRibbonIDs.suffix(12)), id: \.self) { id in
                    Button { describedAward = describedAward?.id == id ? nil : AwardLocationSelection(id: id) } label: {
                        AssetImage(key: "award-" + id).frame(width: 30, height: 34).frame(maxWidth: .infinity, minHeight: 44)
                    }.buttonStyle(.plain)
                        .background(describedAward?.id == id ? theme.panel : .clear, in: RoundedRectangle(cornerRadius: 4))
                        .overlay { if describedAward?.id == id { RoundedRectangle(cornerRadius: 4).strokeBorder(theme.accent, lineWidth: 2) } }
                        .anchorPreference(key: RibbonDescriptionAnchors.self, value: .bounds) { [id: $0] }
                        .accessibilityValue(describedAward?.id == id ? "Description shown" : "")
                        .accessibilityHint("Tap again to hide the description")
                        .accessibilityLabel(RibbonCatalog.shared.awardPickerName(id)).accessibilityIdentifier("passport.ribbon.\(id)")
                }
            }
            let check = RibbonRules.shared.transferCheck(from: p.currentgame, pokemon: p)
            Button { transferUndo = nil; reviewingTransfer = true } label: {
                HStack(spacing: 8) {
                    Text(check.isSafe ? "✓" : "!").font(PixelFont.font(28)).frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) { Text(check.title).font(PixelFont.font(16)); Text(check.summary).font(PixelFont.font(12)) }
                    Spacer(minLength: 0)
                    Text("Review ›").font(PixelFont.font(13))
                }.padding(.vertical, 12).contentShape(Rectangle())
            }.buttonStyle(.plain).foregroundStyle(check.isSafe ? theme.accent : theme.warningInk)
                .overlay(alignment: .top) { Rectangle().fill(theme.border).frame(height: 1) }
                .overlay(alignment: .bottom) { Rectangle().fill(theme.border).frame(height: 1) }
                .disabled(!check.canAssess).accessibilityIdentifier("passport.transfer.review")
        }
    }
    private func journey(_ p: RibbonPokemon) -> some View {
        GeometryReader { geometry in
            let perPage = geometry.size.height < 560 ? 3 : 6
            let total = grouping == .games ? p.recordedVisits.count : p.visitedGenerations.count
            let pages = max(1, (total + perPage - 1) / perPage)
            let visiblePage = min(stampPage, pages - 1)
            let activeGame = p.recordedVisits.contains { $0.game == game } ? game : p.recordedVisits.first?.game ?? ""
            let active = grouping == .games ? RibbonCatalog.shared.gameInfo[activeGame]?.gen ?? 0 : p.visitedGenerations.contains(generation) ? generation : p.visitedGenerations.first ?? 0
            let earned = grouping == .games ? p.awards(earnedInGame: activeGame) : p.awards(earnedIn: active)
            let ribbonsPerPage = geometry.size.height < 560 ? 6 : 12
            let ribbonPages = max(1, (earned.count + ribbonsPerPage - 1) / ribbonsPerPage)
            let games = grouping == .games ? [activeGame] : p.games(in: active)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    RetroHeading(title: "Stamp album", value: "\(total) \(grouping == .games ? "games" : "generations")")
                    Button("Edit visits") { editingVisits = true }.font(PixelFont.font(12)).foregroundStyle(theme.accent)
                }
                TerminalSelector(title: "Album view", selection: $grouping, values: AlbumGrouping.allCases, name: { $0.name }, inline: true, identifier: "album.grouping")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    if grouping == .games {
                        ForEach(Array(p.recordedVisits.dropFirst(visiblePage * perPage).prefix(perPage))) { visit in
                            Button { game = visit.game; earnedPage = 0; visitPage = 0 } label: {
                                albumStamp(game: visit.game, gen: visit.generation,
                                           title: RibbonCatalog.shared.compactGameName(visit.game),
                                           subtitle: visit.game == p.origingame && visit.game == p.currentgame ? "Origin · Current" : visit.game == p.origingame ? "Origin" : visit.game == p.currentgame ? "Current" : "Visited",
                                           selected: visit.game == activeGame, compact: geometry.size.height < 480)
                            }.buttonStyle(.plain).accessibilityIdentifier("album.game.\(visit.game)")
                        }
                    } else {
                        ForEach(Array(p.visitedGenerations.dropFirst(visiblePage * perPage).prefix(perPage)), id: \.self) { gen in
                            let visits = p.games(in: gen)
                            Button { generation = gen; earnedPage = 0; visitPage = 0 } label: {
                                albumStamp(game: visits.contains(p.currentgame) ? p.currentgame : visits.first ?? "", gen: gen,
                                           title: "\(visits.count) games", subtitle: "\(p.awards(earnedIn: gen).count) earned", selected: gen == active, compact: geometry.size.height < 480)
                            }.buttonStyle(.plain).accessibilityIdentifier("album.generation.\(gen)")
                        }
                    }
                }
                albumPager(page: visiblePage, count: pages, identifier: "album.stamps") { next in
                    stampPage = next; earnedPage = 0; visitPage = 0
                    let index = next * perPage
                    if grouping == .games { game = p.recordedVisits[index].game }
                    else { generation = p.visitedGenerations[index] }
                }
                if active > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        RetroHeading(title: grouping == .games ? RibbonCatalog.shared.compactGameName(activeGame) : "Generation \(active.roman)", value: "\(earned.count) earned")
                        if let shownGame = games.dropFirst(min(visitPage, max(0, games.count - 1))).first {
                            HStack(spacing: 6) {
                                GameMascot(game: shownGame, size: 22)
                                Text(RibbonCatalog.shared.compactGameName(shownGame)).font(PixelFont.font(13)).lineLimit(2)
                                Spacer(minLength: 0)
                                Text(shownGame == p.origingame && shownGame == p.currentgame ? "Origin · Current" : shownGame == p.origingame ? "Origin" : shownGame == p.currentgame ? "Current" : "Visited").font(PixelFont.font(10)).foregroundStyle(theme.muted)
                                if games.count > 1 {
                                    Button { visitPage = (visitPage + 1) % games.count } label: { Image(systemName: "chevron.right").frame(width: 32, height: 32) }
                                        .accessibilityLabel("Next visited game, \(visitPage + 1) of \(games.count)")
                                }
                            }.frame(minHeight: 32)
                        }
                        if earned.isEmpty { Text("No ribbons assigned").font(PixelFont.font(14)).foregroundStyle(theme.muted) }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 6), spacing: 5) {
                            ForEach(Array(earned.dropFirst(min(earnedPage, ribbonPages - 1) * ribbonsPerPage).prefix(ribbonsPerPage)), id: \.self) { id in
                                Button { selectedAward = AwardLocationSelection(id: id) } label: {
                                    AssetImage(key: "award-" + id).frame(height: 27).padding(3).frame(maxWidth: .infinity).background(theme.board)
                                }.buttonStyle(.plain).accessibilityLabel(RibbonCatalog.shared.ribbons[id] ?? id)
                            }
                        }
                        if ribbonPages > 1 {
                            albumPager(page: min(earnedPage, ribbonPages - 1), count: ribbonPages, identifier: "album.awards") { earnedPage = $0 }
                        }
                        Button("Ribbons ›") { section = .ribbons }.font(PixelFont.font(14)).foregroundStyle(theme.accent)
                    }.retroPanel()
                }
                Spacer(minLength: 0)
            }.onChange(of: grouping) { _, _ in stampPage = 0; earnedPage = 0; visitPage = 0 }
        }
    }
    private func albumStamp(game: String, gen: Int, title: String, subtitle: String, selected: Bool, compact: Bool) -> some View {
        VStack(spacing: 4) {
            Text("GEN \(gen.roman)").font(PixelFont.font(11))
            GameMascot(game: game, size: compact ? 24 : 34).frame(height: compact ? 24 : 36)
            Text(title).font(PixelFont.font(12)).lineLimit(2).minimumScaleFactor(0.8).frame(height: 30)
            Text(subtitle).font(PixelFont.font(10)).foregroundStyle(theme.muted).lineLimit(1)
        }.frame(maxWidth: .infinity).padding(.vertical, 7).padding(.horizontal, 3)
            .background(selected ? theme.board : theme.panel)
            .overlay(Rectangle().strokeBorder(theme.border, style: StrokeStyle(lineWidth: selected ? 2 : 1, dash: selected ? [] : [3])))
    }
    private func albumPager(page: Int, count: Int, identifier: String, select: @escaping (Int) -> Void) -> some View {
        HStack {
            Button("‹ Previous") { select(page - 1) }.disabled(page == 0).accessibilityIdentifier(identifier + ".previous")
            Spacer(); Text("\(page + 1) / \(count)").foregroundStyle(theme.muted); Spacer()
            Button("Next ›") { select(page + 1) }.disabled(page + 1 >= count).accessibilityIdentifier(identifier + ".next")
        }.font(PixelFont.font(12)).frame(minHeight: 28)
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

private struct RibbonDescriptionAnchors: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}
private struct RibbonDescriptionHeight: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// Keep the bubble inside the visible passport, preferring the space above its ribbon.
struct RibbonBubblePlacement {
    var frame: CGRect
    var above: Bool
    var tipX: CGFloat
    init(container: CGSize, anchor: CGRect, contentHeight: CGFloat) {
        let margin: CGFloat = 12, gap: CGFloat = 12
        let width = max(1, min(280, container.width - margin * 2))
        let height = max(1, contentHeight)
        let roomAbove = max(1, anchor.minY - gap - margin)
        let roomBelow = max(1, container.height - anchor.maxY - gap - margin)
        above = height <= roomAbove || (height > roomBelow && roomAbove >= roomBelow)
        let fittedHeight = min(height, above ? roomAbove : roomBelow)
        let x = max(margin, min(container.width - margin - width, anchor.midX - width / 2))
        let y = above ? anchor.minY - gap - fittedHeight : anchor.maxY + gap
        frame = CGRect(x: x, y: y, width: width, height: fittedHeight)
        tipX = max(14, min(width - 14, anchor.midX - x))
    }
}

/// The outside tap layer leaves holes over every ribbon, so a single tap can switch bubbles.
private struct RibbonBubbleOutsideShape: Shape {
    var holes: [CGRect]
    func path(in rect: CGRect) -> Path {
        var path = Path(); path.addRect(rect)
        for hole in holes {
            let visible = hole.intersection(rect)
            if !visible.isNull, !visible.isEmpty { path.addRect(visible) }
        }
        return path
    }
}
private struct RibbonBubblePointer: Shape {
    var pointsDown: Bool
    var borderOnly = false
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: pointsDown ? rect.minY : rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: pointsDown ? rect.maxY : rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: pointsDown ? rect.minY : rect.maxY))
        if !borderOnly { path.closeSubpath() }
        return path
    }
}
struct RibbonDescriptionBubble: View {
    var awardID: String
    @Environment(\.colorScheme) private var scheme
    private var theme: PassportTheme { PassportTheme(dark: scheme == .dark, game: "") }
    var body: some View {
        ViewThatFits(in: .vertical) {
            content.fixedSize(horizontal: false, vertical: true)
            ScrollView { content.fixedSize(horizontal: false, vertical: true) }
        }.clipShape(RoundedRectangle(cornerRadius: 8)).foregroundStyle(theme.ink)
    }
    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(RibbonCatalog.shared.ribbons[awardID] ?? awardID).font(PixelFont.font(17))
                .fixedSize(horizontal: false, vertical: true).padding(.horizontal, 12).padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading).background(theme.board)
                .overlay(alignment: .bottom) { Rectangle().fill(theme.border).frame(height: 1) }
                .accessibilityIdentifier("ribbon.description.name")
            Text(RibbonRules.shared.awards[awardID]?.description ?? "No in-game description available.")
                .font(PixelFont.font(16)).fixedSize(horizontal: false, vertical: true).padding(12)
                .frame(maxWidth: .infinity, alignment: .leading).background(theme.panel)
                .accessibilityIdentifier("ribbon.description.text")
        }.background {
            GeometryReader { geometry in Color.clear.preference(key: RibbonDescriptionHeight.self, value: geometry.size.height) }
        }
    }
}

struct AwardLocationEditor: View {
    var pokemonID: String
    var initialAward: String
    var body: some View {
        StoredRibbonManager(pokemonID: pokemonID, showOwned: true)
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
                            }.deleteDisabled(visit.game == p.origingame || visit.game == p.currentgame || p.earnedGames?.values.contains(visit.game) == true)
                        }.onDelete { indices in
                            var next = p
                            let games = indices.map { p.recordedVisits[$0].game }.filter { $0 != p.origingame && $0 != p.currentgame }
                            next.visits = next.recordedVisits.filter { !games.contains($0.game) }
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
            }.navigationTitle("Visits").font(PixelFont.font(17)).toolbar { TerminalToolbarItem(placement: .topBarTrailing) { TerminalCornerButton("Done") { dismiss() }  } }
        }
    }
}
