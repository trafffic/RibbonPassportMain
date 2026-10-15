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
    @State private var managingRibbons: AwardLocationSelection?
    private var theme: PassportTheme { PassportTheme(dark: scheme == .dark, game: "") }
    private var dragSpace: String { "pc-storage-" + kind.key }
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
                                Button("Export Ribbon Masters", systemImage: "square.and.arrow.up") {
                                    exporting = PokemonExportSelection(pokemon: store.snapshot.pokemon(for: .ribbon), target: .ribbonsGuide)
                                }.disabled(store.snapshot.pokemon(for: .ribbon).isEmpty)
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
                        }.background(theme.panel).overlay(Rectangle().stroke(theme.border, lineWidth: 2))
                    }
                    HStack {
                        Text("\(box.slots.compactMap { $0 }.count) / 30")
                        Spacer()
                        Button("Wallpaper") { editingWallpaper = true }.foregroundStyle(theme.accent)
                        Spacer()
                        Text("Box \(min(boxIndex + 1, layout.boxes.count)) / \(layout.boxes.count)")
                    }.font(PixelFont.font(13)).foregroundStyle(theme.muted)
                    if let p = selection {
                        selectionStrip(p)
                        if kind == .ribbon { ManageRibbonsButton(pokemon: p) { managingRibbons = AwardLocationSelection(id: p.id) } }
                    }
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
                .sheet(item: $exporting) { PokemonExportView(selection: $0) }
                .sheet(item: $managingRibbons) { choice in StoredRibbonManager(pokemonID: choice.id, entryTitle: "PC box") }
                .task(id: hoveredPage) {
                    guard let direction = hoveredPage, drag?.settling == false, layout.boxes.count > 1 else { return }
                    do { try await Task.sleep(for: .milliseconds(650)) } catch { return }
                    guard !Task.isCancelled, hoveredPage == direction, drag?.settling == false else { return }
                    boxIndex = (boxIndex + layout.boxes.count + direction) % layout.boxes.count
                    drag?.target = nil
                }
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
                .background(hoveredPage == -1 ? theme.accent.opacity(0.35) : .clear)
                .trackPCSlot(.page(-1), space: dragSpace)
            Button { boxName = box.name; renaming = true } label: {
                Text(box.name.uppercased()).font(PixelFont.font(17)).lineLimit(1).minimumScaleFactor(0.65).frame(maxWidth: .infinity)
            }.accessibilityLabel("Rename \(box.name)")
            Button { withAnimation(.easeInOut(duration: 0.2)) { partyVisible.toggle() } } label: {
                Label("Party", systemImage: "person.2").font(PixelFont.font(13)).padding(.horizontal, 8).frame(minHeight: 38)
                    .background(partyVisible ? theme.board : theme.panel).foregroundStyle(theme.ink)
            }.accessibilityIdentifier("pc.partyToggle").accessibilityValue(partyVisible ? "Shown" : "Hidden")
            Button { boxIndex = (boxIndex + 1) % layout.boxes.count } label: { Image(systemName: "chevron.right").frame(width: 33, height: 44) }
                .accessibilityLabel("Next box")
                .background(hoveredPage == 1 ? theme.accent.opacity(0.35) : .clear)
                .trackPCSlot(.page(1), space: dragSpace)
        }.buttonStyle(.plain).padding(.horizontal, 3).padding(.vertical, 5).background(theme.ink).foregroundStyle(theme.paper)
    }
    private var boxGrid: some View {
        GeometryReader { geometry in
            let cellWidth = geometry.size.width / CGFloat(PCGridMetrics.columns)
            let cellHeight = geometry.size.height / CGFloat(PCGridMetrics.rows)
            VStack(spacing: 0) {
                ForEach(0..<PCGridMetrics.rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<PCGridMetrics.columns, id: \.self) { column in
                            boxSlot(row * PCGridMetrics.columns + column, width: cellWidth, height: cellHeight)
                        }
                    }
                }
            }.background { BoxWallpaperView(settings: layout.wallpaper(for: box)) }
        }.aspectRatio(PCGridMetrics.aspectRatio, contentMode: .fit).frame(maxWidth: .infinity)
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
            .accessibilityHint("Drag to move, or use Move below the box")
    }
    private var partyBar: some View {
        VStack(spacing: 4) {
            Text("PARTY").font(PixelFont.font(10))
            ForEach(0..<6, id: \.self) { i in
                let p = i < layout.partyIDs.count ? pokemon(layout.partyIDs[i]) : nil
                let target = PCSlotTarget.party(i)
                Button {
                    if moving, let id = selection?.id { animateMove(id, to: target) }
                    else if let p { store.choose(p.id) }
                    else if let id = selection?.id { store.editStorage(kind: kind) { _ = $0.moveToParty(id) } }
                } label: {
                    Group {
                        if let p { PokemonSprite(pokemon: p, download: true).opacity(spriteOpacity(p.id)) }
                        else { Text("·").foregroundStyle(theme.muted) }
                    }.frame(width: 35, height: 31).background(theme.board)
                        .overlay(Rectangle().stroke(drag?.target == target ? theme.accent : theme.border, style: StrokeStyle(lineWidth: drag?.target == target ? 2 : 1, dash: drag?.target == target ? [] : [2])))
                }.buttonStyle(.plain).accessibilityLabel(p?.displayName ?? "Empty party slot")
                    .accessibilityIdentifier("pc.party.slot.\(i)").accessibilityValue(p?.id ?? "Empty")
                    .trackPCSlot(target, space: dragSpace)
                    .highPriorityGesture(spriteDrag(pokemon: p, source: target), including: p != nil || drag != nil ? .all : .none)
            }
        }.padding(5).background(theme.panel).overlay(Rectangle().stroke(theme.border, lineWidth: 1))
    }
    @ViewBuilder private func pokemonMenu(_ p: RibbonPokemon) -> some View {
        Button(kind == .ribbon ? "Open passport" : "Open build") { store.openPokemonID = p.id }
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
            Button(kind == .ribbon ? "Passport ▸" : "Build ▸") { store.openPokemonID = p.id }.font(PixelFont.font(13)).buttonStyle(.plain)
            Menu { pokemonMenu(p) } label: { Image(systemName: "ellipsis").frame(width: 32, height: 44) }.accessibilityLabel("Pokémon actions")
        }.retroPanel(padding: 9)
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
struct StampAlbumView: View {
    var pokemonID: String
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @State private var generation = 0
    @State private var game = ""
    @AppStorage("album.grouping") private var grouping: AlbumGrouping = .generations
    @State private var exporting: PokemonExportSelection?
    @State private var editing = false
    @State private var editingVisits = false
    @State private var selectedAward: AwardLocationSelection?
    @State private var managingRibbons = false
    private var p: RibbonPokemon? { store.snapshot.pokemon.first { $0.id == pokemonID } }
    private var theme: PassportTheme { PassportTheme(dark: scheme == .dark, game: p?.currentgame ?? "") }
    var body: some View {
        ScrollView {
            if let p {
                let activeGame = p.recordedVisits.contains { $0.game == game } ? game : p.recordedVisits.first?.game ?? ""
                let active = grouping == .games ? RibbonCatalog.shared.gameInfo[activeGame]?.gen ?? 0 : p.visitedGenerations.contains(generation) ? generation : p.visitedGenerations.first ?? 0
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
                    ManageRibbonsButton(pokemon: p) { managingRibbons = true }
                    RetroHeading(title: "Stamp album", value: grouping == .generations ? "\(p.visitedGenerations.count) generations" : "\(p.recordedVisits.count) games")
                    Picker("Album view", selection: $grouping) {
                        ForEach(AlbumGrouping.allCases) { Text($0.name).tag($0) }
                    }.pickerStyle(.segmented).accessibilityIdentifier("album.grouping")
                    if grouping == .generations {
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
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 9) {
                            ForEach(p.recordedVisits) { visit in
                                Button { game = visit.game } label: {
                                    VStack(spacing: 6) {
                                        Text("GEN \(visit.generation.roman)").font(PixelFont.font(11))
                                        GameMascot(game: visit.game, size: visit.game == "scar" ? 42 : 52).frame(height: 54)
                                        Text(RibbonCatalog.shared.compactGameName(visit.game)).font(PixelFont.font(14)).lineLimit(2).minimumScaleFactor(0.8).frame(minHeight: 32)
                                        Text(visit.game == p.origingame && visit.game == p.currentgame ? "Origin · Current" : visit.game == p.origingame ? "Origin" : visit.game == p.currentgame ? "Current" : "Visited")
                                            .font(PixelFont.font(11)).foregroundStyle(theme.muted)
                                    }.frame(maxWidth: .infinity).padding(.vertical, 10).padding(.horizontal, 3)
                                        .background(visit.game == activeGame ? theme.board : theme.panel)
                                        .overlay(Rectangle().strokeBorder(theme.border, style: StrokeStyle(lineWidth: visit.game == activeGame ? 2 : 1, dash: visit.game == activeGame ? [] : [3])))
                                }.buttonStyle(.plain).accessibilityIdentifier("album.game.\(visit.game)")
                            }
                        }
                    }
                    if active > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            let earned = grouping == .games ? p.awards(earnedInGame: activeGame) : p.awards(earnedIn: active)
                            RetroHeading(title: grouping == .games ? RibbonCatalog.shared.compactGameName(activeGame) : "Generation \(active.roman)", value: "\(earned.count) earned")
                            ForEach(grouping == .games ? [activeGame] : p.games(in: active), id: \.self) { game in
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
                            if earned.isEmpty { Text("No ribbons assigned").font(PixelFont.font(15)).foregroundStyle(theme.muted) }
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 6), spacing: 8) {
                                ForEach(earned, id: \.self) { id in
                                    Button { selectedAward = AwardLocationSelection(id: id) } label: {
                                        AssetImage(key: "award-" + id).frame(height: 34).padding(4).frame(maxWidth: .infinity).background(theme.board)
                                    }.buttonStyle(.plain).accessibilityLabel(RibbonCatalog.shared.ribbons[id] ?? id)
                                }
                            }
                            Button("Manage ribbons") { managingRibbons = true }.buttonStyle(RetroAction(prominent: true))
                        }.retroPanel()
                    }
                    let unspecified = p.ownedRibbonIDs.filter { p.earnedGames?[$0] == nil }.count
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
            .toolbar {
                Button("Edit") { editing = true }.disabled(p == nil)
                Button("Export", systemImage: "square.and.arrow.up") {
                    if let p { exporting = PokemonExportSelection(pokemon: [p], target: .ribbonsGuide) }
                }.disabled(p == nil)
            }
            .sheet(item: $exporting) { PokemonExportView(selection: $0) }
            .sheet(isPresented: $editing) { if let p { NavigationStack { PokemonEditor(pokemon: p) }.font(PixelFont.font(16)) } }
            .sheet(isPresented: $editingVisits) { JourneyEditorView(pokemonID: pokemonID) }
            .sheet(isPresented: $managingRibbons) { StoredRibbonManager(pokemonID: pokemonID) }
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
            }.navigationTitle("Visits").font(PixelFont.font(17)).toolbar { Button("Done") { dismiss() } }
        }
    }
}
