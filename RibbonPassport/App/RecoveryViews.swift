import SwiftUI

private enum RecoveryFilter: String, CaseIterable { case all = "All", deleted = "Deleted", versions = "Versions" }

struct RecoveryHistoryView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @State private var filter = RecoveryFilter.all
    private var theme: PassportTheme { PassportTheme(dark: scheme == .dark, game: "") }
    private var items: [RecoveryEntry] {
        var seen = Set<String>()
        return (store.snapshot.recoveryHistory ?? []).filter { entry in
            guard seen.insert(entry.key).inserted else { return false }
            let exists = store.snapshot.containsRecoveryItem(entry)
            return filter == .all || (filter == .deleted ? !exists : exists)
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                ForEach(RecoveryFilter.allCases, id: \.self) { value in
                    Button { filter = value } label: {
                        Text(value.rawValue).font(PixelFont.font(15)).frame(maxWidth: .infinity, minHeight: 40)
                            .background(filter == value ? theme.board : theme.panel).overlay(Rectangle().stroke(theme.border))
                    }.buttonStyle(.plain).accessibilityAddTraits(filter == value ? .isSelected : [])
                }
            }.padding(12)
            if items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 34)).foregroundStyle(theme.muted)
                    Text(filter == .deleted ? "No deleted items" : "No saved versions yet").font(PixelFont.font(23))
                    Text("Saved edits and deletions appear here from now on.").font(PixelFont.font(15)).foregroundStyle(theme.muted).multilineTextAlignment(.center)
                }.padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(items) { entry in
                        NavigationLink {
                            RecoveryItemHistoryView(kind: entry.kind, objectID: entry.objectID)
                        } label: {
                            HStack(spacing: 10) {
                                RecoveryArtwork(entry: entry).frame(width: 38, height: 40)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(currentName(entry)).font(PixelFont.font(19))
                                    Text("\(store.snapshot.containsRecoveryItem(entry) ? "Saved versions" : "Deleted") · \(entry.section.name)")
                                        .font(PixelFont.font(12)).foregroundStyle(theme.muted)
                                    Text(entry.recordedAt, format: .dateTime.day().month().year().hour().minute()).font(PixelFont.font(12)).foregroundStyle(theme.muted)
                                }
                            }.padding(.vertical, 4)
                        }.listRowBackground(theme.panel).accessibilityIdentifier("recovery.item.\(entry.kind.rawValue).\(entry.objectID)")
                    }
                }.scrollContentBackground(.hidden).listStyle(.plain)
            }
            Text("On this device · Up to \(RecoveryEntry.versionsPerItem) versions per Pokémon or team, \(RecoveryEntry.totalLimit) total. Oldest versions are removed when full.")
                .font(PixelFont.font(12)).foregroundStyle(theme.muted).padding(12)
        }.background(theme.paper).foregroundStyle(theme.ink).navigationTitle("Recovery history").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { Text("RECOVERY HISTORY").font(PixelFont.font(21)) } }
            .tint(theme.accent)
    }
    private func currentName(_ entry: RecoveryEntry) -> String {
        if entry.kind == .pokemon { return store.snapshot.pokemon.first { $0.id == entry.objectID }?.displayName ?? entry.name }
        return store.snapshot.teams.first { $0.id == entry.objectID }?.name ?? entry.name
    }
}

struct RecoveryItemHistoryView: View {
    var kind: RecoveryKind
    var objectID: String
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    private var entries: [RecoveryEntry] { store.snapshot.recoveryEntries(kind: kind, id: objectID) }
    private var theme: PassportTheme { PassportTheme(dark: scheme == .dark, game: "") }
    var body: some View {
        List {
            if let first = entries.first {
                Section {
                    HStack(spacing: 12) {
                        RecoveryArtwork(entry: first).frame(width: 47, height: 48)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(first.name).font(PixelFont.font(23))
                            Text(store.snapshot.containsRecoveryItem(first) ? "Choose a saved version" : "Deleted · Choose a version to recover")
                                .font(PixelFont.font(14)).foregroundStyle(theme.muted)
                        }
                    }.padding(.vertical, 6)
                }.listRowBackground(theme.panel)
                Section("Saved versions") {
                    ForEach(entries) { entry in
                        NavigationLink {
                            RecoveryVersionView(entry: entry)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(entry.action.name).font(PixelFont.font(18))
                                    Spacer(minLength: 4)
                                    if store.snapshot.matchesRecoveryVersion(entry) { Text("Current").font(PixelFont.font(12)).foregroundStyle(theme.accent) }
                                }
                                Text(entry.recordedAt, format: .dateTime.day().month().year().hour().minute().second()).font(PixelFont.font(13)).foregroundStyle(theme.muted)
                            }.padding(.vertical, 5)
                        }.listRowBackground(theme.panel).accessibilityIdentifier("recovery.version.\(entry.id)")
                    }
                }
            } else {
                Text("No saved versions yet. History starts with the next saved edit or deletion.").font(PixelFont.font(17)).listRowBackground(theme.panel)
            }
        }.font(PixelFont.font(16)).scrollContentBackground(.hidden).background(theme.paper).foregroundStyle(theme.ink).navigationTitle("Saved versions").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { Text("Saved versions").font(PixelFont.font(20)) } }
    }
}

private struct RecoveryArtwork: View {
    var entry: RecoveryEntry
    var body: some View {
        if let p = entry.pokemon { PokemonSprite(pokemon: p).frame(maxWidth: .infinity, maxHeight: .infinity) }
        else { Image(systemName: "person.3").font(.system(size: 24)) }
    }
}

struct RecoveryVersionView: View {
    var entry: RecoveryEntry
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @State private var restored = false
    private var theme: PassportTheme { PassportTheme(dark: scheme == .dark, game: entry.pokemon?.currentgame ?? "") }
    private var changes: [String] { RecoveryComparison.changes(for: entry, in: store.snapshot) }
    private var alreadyCurrent: Bool { store.snapshot.matchesRecoveryVersion(entry) }
    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    RecoveryArtwork(entry: entry).frame(width: 50, height: 50)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(entry.name).font(PixelFont.font(23))
                        Text(entry.action.name).font(PixelFont.font(14)).foregroundStyle(theme.muted)
                        Text(entry.recordedAt, format: .dateTime.day().month().year().hour().minute().second()).font(PixelFont.font(12)).foregroundStyle(theme.muted)
                    }
                }.padding(.vertical, 6)
            }.listRowBackground(theme.panel)
            if let p = entry.pokemon {
                pokemonDetails(p)
            } else if let team = entry.team {
                Section("Saved team") {
                    ForEach(Array(team.memberIDs.enumerated()), id: \.offset) { _, id in
                        let member = entry.members.first { $0.id == id } ?? store.snapshot.pokemon.first { $0.id == id }
                        HStack(spacing: 9) {
                            if let member { PokemonSprite(pokemon: member).frame(width: 32, height: 34) }
                            Text(member?.displayName ?? "Unavailable Pokémon").font(PixelFont.font(17))
                            Spacer(minLength: 4)
                            if store.snapshot.section(forPokemon: id) != entry.section.teamKind { Text("Missing").font(PixelFont.font(12)).foregroundStyle(theme.warningInk) }
                        }.listRowBackground(theme.panel)
                    }
                    Text("Only members still in your collection and in this section will be included. Recover missing Pokémon first to restore the full team.")
                        .font(PixelFont.font(13)).foregroundStyle(theme.muted).listRowBackground(theme.panel)
                }
            }
            if !changes.isEmpty {
                Section("What will change") {
                    ForEach(changes, id: \.self) { Text($0).font(PixelFont.font(15)).listRowBackground(theme.panel) }
                }
            }
            Section {
                Button {
                    restored = store.restoreHistory(entry.id)
                } label: {
                    Text(alreadyCurrent ? "Current version" : store.snapshot.containsRecoveryItem(entry) ? "Restore this version" : entry.kind == .pokemon ? "Recover Pokémon" : "Recover team")
                        .font(PixelFont.font(19)).frame(maxWidth: .infinity, minHeight: 44)
                }.disabled(alreadyCurrent).accessibilityIdentifier("recovery.restore").listRowBackground(theme.board)
                if restored { Text("Restored").font(PixelFont.font(15)).foregroundStyle(theme.accent).accessibilityIdentifier("recovery.restored").listRowBackground(theme.panel) }
            } footer: {
                Text(entry.kind == .pokemon && !store.snapshot.containsRecoveryItem(entry)
                     ? "The original position and team memberships are used where space is available. Occupied slots stay in place."
                     : "The details being replaced will stay in Recovery history.").font(PixelFont.font(13))
            }
        }.font(PixelFont.font(16)).scrollContentBackground(.hidden).background(theme.paper).foregroundStyle(theme.ink).tint(theme.accent)
            .navigationTitle("Preview version").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { Text("Preview version").font(PixelFont.font(20)) } }
    }
    @ViewBuilder private func pokemonDetails(_ p: RibbonPokemon) -> some View {
        Section("Saved Pokémon") {
            detail("Species", RibbonCatalog.shared.pokemon[p.species]?.name ?? p.species)
            detail("Level", "\(p.currentlevel)")
            detail("Current game", RibbonCatalog.shared.gameName(p.currentgame))
            detail("Origin game", RibbonCatalog.shared.gameName(p.origingame))
            detail("Shiny", p.shiny ? "Yes" : "No")
            if !p.gender.isEmpty { detail("Gender", p.gender.capitalized) }
            if let met = p.metLevel { detail("Met level", "\(met)") }
            if let ball = p.ball { detail("Ball", RibbonsGuideExporter.balls.first { $0.id == ball }?.name ?? ball) }
            if let language = p.language { detail("Language", language.uppercased()) }
            if let trainer = p.trainername, !trainer.isEmpty { detail("Original trainer", trainer) }
            if p.shadow { detail("Shadow", "Yes") }
            if p.gmax { detail("Gigantamax", "Yes") }
            detail("Equipped title", RibbonCatalog.shared.titleText(for: p))
        }
        if !p.recordedVisits.isEmpty {
            Section("Journey") { Text(p.recordedVisits.map { RibbonCatalog.shared.compactGameName($0.game) }.joined(separator: " · ")).font(PixelFont.font(15)).listRowBackground(theme.panel) }
        }
        Section {
            DisclosureGroup("Ribbons and marks · \(p.ribbons.count)") {
                ForEach(RibbonCatalog.shared.chronologicalAwards(p.ribbons), id: \.self) { id in
                    HStack(spacing: 8) {
                        AssetImage(key: "award-" + id).frame(width: 24, height: 28)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(RibbonCatalog.shared.awardPickerName(id)).font(PixelFont.font(16))
                            Text(p.earningLocation(id)).font(PixelFont.font(12)).foregroundStyle(theme.muted)
                        }
                    }
                }
            }.font(PixelFont.font(17)).listRowBackground(theme.panel)
        }
        if let build = p.showdownSet {
            Section("Saved build") {
                detail("Item", build.item); detail("Ability", build.ability); detail("Nature", build.nature)
                detail("Tera type", build.teraType); detail("EVs", build.evs); detail("IVs", build.ivs)
                ForEach(Array(build.moves.enumerated()), id: \.offset) { _, move in Text(move).font(PixelFont.font(16)).listRowBackground(theme.panel) }
            }
        }
    }
    private func detail(_ label: String, _ value: String) -> some View {
        LabeledContent { Text(value.isEmpty ? "Not set" : value).multilineTextAlignment(.trailing) } label: { Text(label) }
            .font(PixelFont.font(15)).listRowBackground(theme.panel)
    }
}

enum RecoveryComparison {
    static func changes(for entry: RecoveryEntry, in snapshot: CollectionSnapshot) -> [String] {
        guard snapshot.containsRecoveryItem(entry) else { return [entry.kind == .pokemon ? "Return this Pokémon to your collection." : "Return this team to your collection."] }
        if let saved = entry.pokemon, let current = snapshot.pokemon.first(where: { $0.id == entry.objectID }) {
            var changes: [String] = []
            func field(_ name: String, _ now: String, _ old: String) { if now != old { changes.append("\(name): \(now.isEmpty ? "Not set" : now) → \(old.isEmpty ? "Not set" : old)") } }
            field("Species", current.species, saved.species); field("Nickname", current.nickname, saved.nickname)
            field("Level", "\(current.currentlevel)", "\(saved.currentlevel)")
            field("Current game", RibbonCatalog.shared.gameName(current.currentgame), RibbonCatalog.shared.gameName(saved.currentgame))
            field("Origin game", RibbonCatalog.shared.gameName(current.origingame), RibbonCatalog.shared.gameName(saved.origingame))
            field("Shiny", current.shiny ? "Yes" : "No", saved.shiny ? "Yes" : "No")
            let added = Set(saved.ribbons).subtracting(current.ribbons), removed = Set(current.ribbons).subtracting(saved.ribbons)
            if !added.isEmpty { changes.append("Restore awards: " + RibbonCatalog.shared.chronologicalAwards(Array(added)).map { RibbonCatalog.shared.awardPickerName($0) }.joined(separator: ", ")) }
            if !removed.isEmpty { changes.append("Remove awards: " + RibbonCatalog.shared.chronologicalAwards(Array(removed)).map { RibbonCatalog.shared.awardPickerName($0) }.joined(separator: ", ")) }
            if current.earnedGames != saved.earnedGames || current.earnedGenerations != saved.earnedGenerations { changes.append("Restore the saved earning locations.") }
            if current.visits != saved.visits { changes.append("Restore the saved journey.") }
            if current.showdownSet != saved.showdownSet { changes.append("Restore the saved competitive build.") }
            if current.title != saved.title || current.titleText != saved.titleText { changes.append("Restore the saved equipped title.") }
            if current.gender != saved.gender || current.shadow != saved.shadow || current.gmax != saved.gmax || current.metLevel != saved.metLevel || current.ball != saved.ball || current.language != saved.language || current.trainername != saved.trainername || current.source != saved.source {
                changes.append("Restore the other saved Pokémon details shown above.")
            }
            return changes
        }
        if let saved = entry.team, let current = snapshot.teams.first(where: { $0.id == entry.objectID }) {
            var changes: [String] = []
            if saved.name != current.name { changes.append("Name: \(current.name) → \(saved.name)") }
            if saved.memberIDs != current.memberIDs { changes.append("Restore the available saved members in their saved order.") }
            return changes
        }
        return []
    }
}
