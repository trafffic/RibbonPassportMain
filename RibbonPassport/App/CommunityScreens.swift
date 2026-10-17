import SwiftUI

struct CommunityPage<Content: View>: View {
    var title: String
    @ViewBuilder var content: () -> Content
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let theme = PassportTheme(dark: scheme == .dark, game: "")
        ScrollView {
            VStack(alignment: .leading, spacing: 16, content: content)
                .padding(16).frame(maxWidth: 700, alignment: .leading).frame(maxWidth: .infinity)
        }.scrollDismissesKeyboard(.interactively).background(theme.paper).foregroundStyle(theme.ink).font(PixelFont.font(16))
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar).terminalBackControl()
            .toolbar { TerminalToolbarItem(placement: .principal) { Text(title).font(PixelFont.font(19)).lineLimit(1).minimumScaleFactor(0.75) } }
    }
}
struct CommunityRow: View {
    var title: String
    var subtitle: String = ""
    var symbol: String = "›"
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(PixelFont.font(18)).fixedSize(horizontal: false, vertical: true)
                if !subtitle.isEmpty { Text(subtitle).font(PixelFont.font(13)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
            }.frame(maxWidth: .infinity, alignment: .leading)
            Text(symbol).font(PixelFont.font(21)).accessibilityHidden(true)
        }.frame(minHeight: 44).retroPanel(padding: 12).contentShape(Rectangle())
    }
}
struct CommunitySources: View {
    var ids: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(ids, id: \.self) { id in
                if let source = CommunityContent.shared.source(id) {
                    NavigationLink { SourceReviewView(source: source) } label: {
                        CommunityRow(title: source.author, subtitle: source.title)
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}
struct FieldGuideLibraryView: View {
    var pokemonID: String? = nil
    var awardID: String? = nil
    var initialGame: String = ""
    @State private var game = ""
    @State private var query = ""
    private var content: CommunityContent { .shared }
    private var guides: [FieldGuide] {
        content.guides(award: awardID, game: game.isEmpty ? nil : game).filter {
            query.isEmpty || ($0.title + " " + $0.awardIDs.map { RibbonCatalog.shared.awardPickerName($0) }.joined(separator: " ")).localizedStandardContains(query)
        }
    }
    private var games: [String] {
        RibbonCatalog.shared.orderedGames(Array(Set(content.guides(award: awardID).flatMap(\.gameIDs))))
    }
    var body: some View {
        CommunityPage(title: "Field guides") {
            if let awardID {
                HStack(spacing: 12) {
                    AssetImage(key: "award-" + awardID).frame(width: 40, height: 44)
                    Text(RibbonCatalog.shared.awardPickerName(awardID)).font(PixelFont.font(23))
                }
                Text(RibbonRules.shared.awards[awardID]?.description ?? "").font(PixelFont.font(16))
            }
            TerminalSelector(title: "Game", selection: $game, values: [""] + games, name: { $0.isEmpty ? "All games" : RibbonCatalog.shared.gameName($0) }, identifier: "guides.game")
            TextField("Find a ribbon or guide", text: $query).accessibilityIdentifier("guides.search")
            if guides.isEmpty {
                Text(awardID == nil ? "No guides match this search." : "There is no post-capture earning guide for this award. Event and capture-only awards keep their original descriptions.")
                    .foregroundStyle(.secondary).retroPanel()
            }
            ForEach(guides) { guide in
                NavigationLink { FieldGuideDetailView(guide: guide, initialGame: game.isEmpty ? initialGame : game, awardID: awardID) } label: {
                    CommunityRow(title: guide.title, subtitle: "\(guide.steps.count) steps · \(guide.sourceIDs.count) sources")
                }.buttonStyle(.plain).accessibilityIdentifier("guide." + guide.id)
            }
        }.onAppear { if games.contains(initialGame) { game = initialGame } }
    }
}
struct FieldGuideDetailView: View {
    var guide: FieldGuide
    var initialGame: String = ""
    var awardID: String? = nil
    @State private var game = ""
    @State private var chapter = "Steps"
    private var selectedGame: String { guide.gameIDs.contains(game) ? game : guide.gameIDs.contains(initialGame) ? initialGame : guide.gameIDs.first ?? "" }
    private var teams: [CommunityTeam] { CommunityContent.shared.teamCandidates.filter { (guide.teamIDs ?? []).contains($0.id) && $0.gameIDs.contains(selectedGame) } }
    var body: some View {
        CommunityPage(title: "Ribbon guide") {
            Text(guide.title).font(PixelFont.font(27)).accessibilityIdentifier("guide.title")
            TerminalSelector(title: "Game", selection: Binding(get: { selectedGame }, set: { game = $0 }),
                             values: RibbonCatalog.shared.orderedGames(guide.gameIDs), name: { RibbonCatalog.shared.gameName($0) })
            TerminalSelector(title: "Chapter", selection: $chapter, values: ["Steps", "Notes", "Teams", "Sources"], name: { $0 }, inline: true)
            if chapter == "Steps" {
                if let awardID, let requirement = guide.requirements?[awardID] { Text(requirement).retroPanel() }
                if awardID == nil {
                    ForEach(guide.awardIDs.filter { RibbonRules.shared.awards[$0]?.games.contains(selectedGame) == true }, id: \.self) { id in
                        if let requirement = guide.requirements?[id] {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(RibbonCatalog.shared.awardPickerName(id)).font(PixelFont.font(18))
                                Text(requirement).font(PixelFont.font(15))
                            }.frame(maxWidth: .infinity, alignment: .leading).retroPanel()
                        }
                    }
                }
                if let location = guide.location(in: selectedGame) { GameGuideLocation(game: selectedGame, location: location) }
                ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text(String(format: "%02d", index + 1)).font(PixelFont.font(23)).foregroundStyle(.secondary)
                        Text(step).fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
                    }.retroPanel()
                }
                Text("Community summary · sources checked 16 Oct 2026").font(PixelFont.font(12)).foregroundStyle(.secondary)
            } else if chapter == "Notes" {
                ForEach(guide.cautions, id: \.self) { caution in Text(caution).frame(maxWidth: .infinity, alignment: .leading).retroPanel() }
                if ["fr-switch", "lg-switch", "xd-nso"].contains(selectedGame) {
                    Text("This summary describes the original release. Check the linked source for differences in this release.").retroPanel()
                }
                if guide.cautions.isEmpty { Text("No additional notes for this guide.").foregroundStyle(.secondary) }
            } else if chapter == "Teams" {
                if teams.isEmpty { Text("This guide has no battle team attached. Contest preparation is in Steps and the original sources.").retroPanel() }
                ForEach(teams) { team in
                    NavigationLink { CommunityTeamDetailView(team: team, initialGame: selectedGame) } label: {
                        CommunityRow(title: team.title, subtitle: "\(team.format) · \(team.author)")
                    }.buttonStyle(.plain)
                }
            } else { CommunitySources(ids: guide.sourceIDs) }
        }
    }
}
private struct GameGuideLocation: View {
    var game: String
    var location: String
    var body: some View {
        HStack(spacing: 10) { GameMascot(game: game, size: 28); Text(location).fixedSize(horizontal: false, vertical: true) }.retroPanel()
    }
}
struct CommunityTeamLibraryView: View {
    var initialGame: String = ""
    @State private var game = ""
    @State private var facility = ""
    @State private var query = ""
    private var all: [CommunityTeam] { CommunityContent.shared.teamCandidates }
    private var games: [String] { RibbonCatalog.shared.orderedGames(Array(Set(all.flatMap(\.gameIDs)))) }
    private var filtered: [CommunityTeam] {
        all.filter { (game.isEmpty || $0.gameIDs.contains(game)) && (facility.isEmpty || $0.facility == facility) &&
            (query.isEmpty || ($0.title + " " + $0.author + " " + $0.format).localizedStandardContains(query)) }
    }
    var body: some View {
        CommunityPage(title: "Team library") {
            TextField("Find a team or author", text: $query).accessibilityIdentifier("library.search")
            TerminalSelector(title: "Game", selection: $game, values: [""] + games, name: { $0.isEmpty ? "All games" : RibbonCatalog.shared.gameName($0) })
            TerminalSelector(title: "Facility", selection: $facility, values: [""] + Set(all.map(\.facility)).sorted(), name: { $0.isEmpty ? "All facilities" : $0 })
            ForEach(filtered) { team in
                NavigationLink { CommunityTeamDetailView(team: team, initialGame: game) } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(team.title).font(PixelFont.font(20)).fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 4) {
                            ForEach(Array(team.members.enumerated()), id: \.offset) { _, member in
                                PokemonSprite(pokemon: member.pokemon(game: game), download: true).frame(maxWidth: .infinity).frame(height: 44)
                            }
                        }.accessibilityHidden(true)
                        Text("\(team.facility) · \(team.format)").font(PixelFont.font(13))
                        Text("By \(team.author)").font(PixelFont.font(13)).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading).retroPanel()
                }.buttonStyle(.plain).accessibilityIdentifier("library.team." + team.id)
            }
            if filtered.isEmpty { Text("No teams match these filters.").retroPanel() }
        }.onAppear { if games.contains(initialGame) { game = initialGame } }
    }
}
struct CommunityTeamDetailView: View {
    var team: CommunityTeam
    var initialGame: String = ""
    @EnvironmentObject private var store: AppStore
    @State private var game = ""
    @State private var savedID: String?
    @State private var chapter = "Team"
    private var selectedGame: String { team.gameIDs.contains(game) ? game : team.gameIDs.contains(initialGame) ? initialGame : team.gameIDs.first ?? "" }
    var body: some View {
        CommunityPage(title: "Community team") {
            Text(team.title).font(PixelFont.font(26))
            Text("By \(team.author)").font(PixelFont.font(17)).accessibilityIdentifier("team.author")
            Text("\(team.facility) · \(team.format)").font(PixelFont.font(14)).foregroundStyle(.secondary)
            TerminalSelector(title: "Game", selection: Binding(get: { selectedGame }, set: { game = $0 }), values: RibbonCatalog.shared.orderedGames(team.gameIDs), name: { RibbonCatalog.shared.gameName($0) })
            TerminalSelector(title: "View", selection: $chapter, values: ["Team", "Strategy", "Sources"], name: { $0 }, inline: true)
            if chapter == "Team" {
                ForEach(Array(team.members.enumerated()), id: \.offset) { _, member in CommunityMemberPanel(member: member, game: selectedGame) }
                if let note = team.sourceVariantNote { Text(note).font(PixelFont.font(14)).foregroundStyle(.secondary) }
                if let savedID {
                    Text("Personal copy saved").foregroundStyle(Color(hex: "718F4E")).accessibilityIdentifier("library.saved")
                    NavigationLink { RetroTeamDetailView(teamID: savedID) } label: { CommunityRow(title: "Open my copy", subtitle: "Edit builds and save versions") }.buttonStyle(.plain)
                } else {
                    Button("Save personal copy") {
                        var next = store.snapshot
                        let id = next.copyCommunityTeam(team, game: selectedGame)
                        store.commit(next); if store.error == nil { savedID = id }
                    }.buttonStyle(RetroAction(prominent: true)).accessibilityIdentifier("library.copy")
                }
            } else if chapter == "Strategy" {
                Text(team.strategySummary).retroPanel()
                RetroHeading(title: "Ribbon Master slot")
                Text(team.ribbonMasterSlot.note).retroPanel()
                if let result = team.documentedResult {
                    RetroHeading(title: "Published result")
                    Text(result.label).font(PixelFont.font(20))
                    Text(result.evidence).font(PixelFont.font(14)).foregroundStyle(.secondary)
                }
                Text("Source reviewed \(team.checkedOn). The published roster has not been playtested by this app. Rental codes are not supplied or checked live.").font(PixelFont.font(13)).foregroundStyle(.secondary)
                if team.regulation != nil {
                    Text("Regulation \(team.regulation!). Check current rules before entering Ranked Battles. A replacement Pokémon must fit the rules and team strategy.").retroPanel()
                }
            } else { CommunitySources(ids: team.sourceIDs) }
        }
    }
}
struct CommunityMemberPanel: View {
    var member: CommunityTeamMember
    var game: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                PokemonSprite(pokemon: member.pokemon(game: game), download: true).frame(width: 54, height: 54)
                VStack(alignment: .leading, spacing: 4) { Text(member.species).font(PixelFont.font(21)); Text(member.item).font(PixelFont.font(15)).foregroundStyle(.secondary) }
            }
            Text("\(member.ability) · \(member.nature)").font(PixelFont.font(14))
            Text("EVs · " + member.evs).font(PixelFont.font(13))
            Text("IVs · " + (member.ivs ?? "Not specified by source")).font(PixelFont.font(13)).foregroundStyle(.secondary)
            if let tera = member.teraType { Text("Tera · " + tera).font(PixelFont.font(14)) }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                ForEach(Array(member.moves.enumerated()), id: \.offset) { _, move in
                    Text(move).font(PixelFont.font(15)).fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading).retroPanel()
    }
}
struct SourceReviewView: View {
    var source: CommunitySource
    @EnvironmentObject private var store: AppStore
    @State private var note = ""
    @State private var saved = false
    var body: some View {
        CommunityPage(title: "Source") {
            Text(source.title).font(PixelFont.font(26))
            Text(source.author).font(PixelFont.font(20)).accessibilityIdentifier("source.author")
            Text("Checked \(source.checkedOn)").font(PixelFont.font(13)).foregroundStyle(.secondary)
            Text(source.kind == "official" ? "Official source" : source.kind == "app-assets" ? "Artwork, data or font credit" : "Community source · credit belongs to the original author").font(PixelFont.font(14))
            if let link = source.link { Link("Open original source ›", destination: link).buttonStyle(RetroAction()).accessibilityIdentifier("source.link") }
            RetroHeading(title: "My notes / correction")
            TextEditor(text: $note).scrollContentBackground(.hidden).font(PixelFont.font(16)).frame(minHeight: 140).retroPanel(padding: 8).accessibilityIdentifier("source.note")
            Text("Saved on this device. Nothing is sent to the author.").font(PixelFont.font(12)).foregroundStyle(.secondary)
            Button(saved ? "Saved" : "Save note") {
                var next = store.snapshot; var notes = next.sourceNotes ?? [:]; notes[source.id] = note
                next.sourceNotes = notes; store.commit(next); saved = store.error == nil
            }.buttonStyle(RetroAction(prominent: true)).accessibilityIdentifier("source.save")
        }.onAppear { note = store.snapshot.sourceNotes?[source.id] ?? "" }.onChange(of: note) { _, _ in saved = false }
    }
}
struct SourcesCreditsView: View {
    @State private var query = ""
    @State private var category = "All"
    private var sources: [CommunitySource] {
        CommunityContent.shared.sources.filter {
            let matches = category == "All" || (category == "Artwork" ? $0.kind == "app-assets" : category == "Official" ? $0.kind == "official" : $0.kind != "app-assets" && $0.kind != "official")
            return matches && (query.isEmpty || ($0.title + " " + $0.author + " " + $0.url).localizedStandardContains(query))
        }.sorted { $0.author.localizedStandardCompare($1.author) == .orderedAscending }
    }
    var body: some View {
        CommunityPage(title: "Sources & credits") {
            TextField("Find an author or website", text: $query).accessibilityIdentifier("credits.search")
            TerminalSelector(title: "Show", selection: $category, values: ["All", "Guides", "Official", "Artwork"], name: { $0 }, inline: true)
            NavigationLink { ProjectCreditsView() } label: { CommunityRow(title: "App credits & licences", subtitle: "Artwork, data, font and software notices") }.buttonStyle(.plain)
            ForEach(sources) { source in
                NavigationLink { SourceReviewView(source: source) } label: {
                    CommunityRow(title: source.author, subtitle: source.title + "\n" + (source.link?.host ?? ""))
                }.buttonStyle(.plain).accessibilityIdentifier("credits.source." + source.id)
            }
            if sources.isEmpty { Text("No sources match this search.").retroPanel() }
        }
    }
}
private struct ProjectCreditsView: View {
    private var notices: [URL] {
        (Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: "RibbonAssets/Notices") ?? []).sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
    private var text: String {
        guard let url = Bundle.main.url(forResource: "credits", withExtension: "md", subdirectory: "RibbonAssets") else { return "See the source credits in Settings." }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }
    var body: some View {
        CommunityPage(title: "App credits") {
            ForEach(notices, id: \.absoluteString) { url in
                NavigationLink { LicenceNoticeView(url: url) } label: {
                    CommunityRow(title: url.deletingPathExtension().lastPathComponent, subtitle: "Licence notice")
                }.buttonStyle(.plain)
            }
            ForEach(Array(text.components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, paragraph in
                Text(.init(paragraph)).font(PixelFont.font(15)).textSelection(.enabled)
            }
        }
    }
}
private struct LicenceNoticeView: View {
    var url: URL
    var body: some View {
        CommunityPage(title: "Licence") {
            Text((try? String(contentsOf: url, encoding: .utf8)) ?? "Notice unavailable.").font(PixelFont.font(14)).textSelection(.enabled)
        }
    }
}
