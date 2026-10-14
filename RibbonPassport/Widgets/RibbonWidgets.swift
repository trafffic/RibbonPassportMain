import SwiftUI
import WidgetKit
import AppIntents

struct PokemonEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Pokémon"
    static var defaultQuery = PokemonQuery()
    var id: String
    var name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}
struct PokemonQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [PokemonEntity] {
        let pokemon = (try? SharedStore.load())?.pokemon ?? []
        return identifiers.compactMap { id in pokemon.first(where: { $0.id == id }).map { PokemonEntity(id: $0.id, name: $0.displayName) } }
    }
    func suggestedEntities() async throws -> [PokemonEntity] {
        let pokemon = (try? SharedStore.load())?.pokemon ?? []
        return pokemon.enumerated().map { PokemonEntity(id: $0.element.id, name: "\($0.offset + 1). \($0.element.displayName)") }
    }
}
struct TeamEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Team"
    static var defaultQuery = TeamQuery()
    var id: String
    var name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}
struct TeamQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [TeamEntity] {
        let teams = (try? SharedStore.load())?.teams(for: .ribbon) ?? []
        return identifiers.compactMap { id in teams.first(where: { $0.id == id }).map { TeamEntity(id: $0.id, name: $0.name) } }
    }
    func suggestedEntities() async throws -> [TeamEntity] {
        ((try? SharedStore.load())?.teams(for: .ribbon) ?? []).map { TeamEntity(id: $0.id, name: $0.name) }
    }
}
struct ShowdownTeamEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Showdown Team"
    static var defaultQuery = ShowdownTeamQuery()
    var id: String
    var name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}
struct ShowdownTeamQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ShowdownTeamEntity] {
        let teams = (try? SharedStore.load())?.teams(for: .showdown) ?? []
        return identifiers.compactMap { id in teams.first(where: { $0.id == id }).map { ShowdownTeamEntity(id: $0.id, name: $0.name) } }
    }
    func suggestedEntities() async throws -> [ShowdownTeamEntity] {
        ((try? SharedStore.load())?.teams(for: .showdown) ?? []).map { ShowdownTeamEntity(id: $0.id, name: $0.name) }
    }
}
enum WidgetLook: String, AppEnum, CaseIterable {
    case followApp, light, dark
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Appearance"
    static var caseDisplayRepresentations: [WidgetLook: DisplayRepresentation] = [
        .followApp: "Follow app", .light: "Light", .dark: "Dark"
    ]
    func resolved(_ snapshot: CollectionSnapshot) -> Appearance {
        self == .followApp ? snapshot.appearance : self == .dark ? .dark : .light
    }
}
struct SelectPokemonIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Pokémon Passport"
    static var description = IntentDescription("Choose a Pokémon and appearance. Leave Pokémon unset to follow your app selection.")
    @Parameter(title: "Pokémon") var pokemon: PokemonEntity?
    @Parameter(title: "Appearance", default: .followApp) var appearance: WidgetLook
}
struct SelectTeamIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Ribbon Team"
    static var description = IntentDescription("Choose a team and appearance. Leave Team unset to follow your app selection.")
    @Parameter(title: "Team") var team: TeamEntity?
    @Parameter(title: "Appearance", default: .followApp) var appearance: WidgetLook
}
struct SelectShowdownTeamIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Showdown Team"
    static var description = IntentDescription("Choose a Showdown team to display battle builds instead of ribbons.")
    @Parameter(title: "Showdown team") var team: ShowdownTeamEntity?
    @Parameter(title: "Appearance", default: .followApp) var appearance: WidgetLook
}
struct PassportEntry: TimelineEntry {
    var date: Date
    var snapshot: CollectionSnapshot
    var selection: String?
    var appearance: Appearance
}
struct PokemonProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PassportEntry {
        PassportEntry(date: Date(), snapshot: SharedStore.demo(), selection: nil, appearance: .automatic)
    }
    func snapshot(for configuration: SelectPokemonIntent, in context: Context) async -> PassportEntry {
        make(configuration, preview: context.isPreview)
    }
    func timeline(for configuration: SelectPokemonIntent, in context: Context) async -> Timeline<PassportEntry> {
        Timeline(entries: [make(configuration, preview: false)], policy: .after(Date().addingTimeInterval(6 * 60 * 60)))
    }
    private func make(_ config: SelectPokemonIntent, preview: Bool) -> PassportEntry {
        var snapshot = (try? SharedStore.load()) ?? CollectionSnapshot()
        if preview && snapshot.pokemon.isEmpty { snapshot = SharedStore.demo() }
        return PassportEntry(date: Date(), snapshot: snapshot, selection: config.pokemon?.id, appearance: config.appearance.resolved(snapshot))
    }
}
struct TeamProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PassportEntry {
        PassportEntry(date: Date(), snapshot: SharedStore.demo(), selection: nil, appearance: .automatic)
    }
    func snapshot(for configuration: SelectTeamIntent, in context: Context) async -> PassportEntry {
        make(configuration, preview: context.isPreview)
    }
    func timeline(for configuration: SelectTeamIntent, in context: Context) async -> Timeline<PassportEntry> {
        Timeline(entries: [make(configuration, preview: false)], policy: .after(Date().addingTimeInterval(6 * 60 * 60)))
    }
    private func make(_ config: SelectTeamIntent, preview: Bool) -> PassportEntry {
        var snapshot = (try? SharedStore.load()) ?? CollectionSnapshot()
        if preview && snapshot.pokemon.isEmpty { snapshot = SharedStore.demo() }
        return PassportEntry(date: Date(), snapshot: snapshot, selection: config.team?.id, appearance: config.appearance.resolved(snapshot))
    }
}
struct ShowdownTeamProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PassportEntry {
        PassportEntry(date: Date(), snapshot: SharedStore.showdownPreview(), selection: nil, appearance: .automatic)
    }
    func snapshot(for configuration: SelectShowdownTeamIntent, in context: Context) async -> PassportEntry {
        make(configuration, preview: context.isPreview)
    }
    func timeline(for configuration: SelectShowdownTeamIntent, in context: Context) async -> Timeline<PassportEntry> {
        Timeline(entries: [make(configuration, preview: false)], policy: .after(Date().addingTimeInterval(6 * 60 * 60)))
    }
    private func make(_ config: SelectShowdownTeamIntent, preview: Bool) -> PassportEntry {
        var snapshot = (try? SharedStore.load()) ?? CollectionSnapshot()
        if preview && snapshot.teams(for: .showdown).isEmpty { snapshot = SharedStore.showdownPreview() }
        return PassportEntry(date: Date(), snapshot: snapshot, selection: config.team?.id, appearance: config.appearance.resolved(snapshot))
    }
}
struct PokemonWidgetView: View {
    var entry: PassportEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let pokemon = entry.snapshot.pokemon.first(where: { $0.id == (entry.selection ?? entry.snapshot.selectedID) }) ?? entry.snapshot.pokemon.first
        let theme = PassportTheme(dark: entry.appearance == .dark || (entry.appearance == .automatic && scheme == .dark), game: pokemon?.currentgame ?? "")
        Group {
            if let pokemon {
                SinglePassport(pokemon: pokemon, size: family == .systemSmall ? .small : family == .systemMedium ? .medium : .large, theme: theme)
                    .widgetURL(URL(string: "ribbonpassport://pokemon/\(pokemon.id)"))
            } else { EmptyWidget(theme: theme) }
        }.containerBackground(for: .widget) { theme.paper }
    }
}
struct TeamWidgetView: View {
    var entry: PassportEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let team = entry.snapshot.widgetTeam(for: .ribbon, id: entry.selection)
        let members = team.map { entry.snapshot.members(teamID: $0.id) } ?? []
        let id = team?.id ?? ""
        let name = team?.name ?? "Your Ribbon Team"
        let theme = PassportTheme(dark: entry.appearance == .dark || (entry.appearance == .automatic && scheme == .dark), game: members.first?.currentgame ?? "")
        Group {
            if members.isEmpty { EmptyWidget(theme: theme) }
            else {
                TeamPassport(pokemon: Array(members.prefix(family == .systemMedium ? 3 : 6)), name: name, large: family == .systemLarge, theme: theme)
                    .widgetURL(URL(string: "ribbonpassport://team/\(id)"))
            }
        }.containerBackground(for: .widget) { theme.paper }
    }
}
struct ShowdownTeamWidgetView: View {
    var entry: PassportEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let team = entry.snapshot.widgetTeam(for: .showdown, id: entry.selection)
        let members = team.map { entry.snapshot.members(teamID: $0.id) } ?? []
        let theme = PassportTheme(dark: entry.appearance == .dark || (entry.appearance == .automatic && scheme == .dark), game: members.first?.currentgame ?? "")
        Group {
            if let team, !members.isEmpty {
                ShowdownTeamPassport(pokemon: Array(members.prefix(family == .systemMedium ? 3 : 6)), name: team.name, large: family == .systemLarge, theme: theme)
                    .widgetURL(URL(string: "ribbonpassport://team/\(team.id)"))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Showdown Team", systemImage: "bolt.fill").font(.headline).foregroundStyle(theme.accent)
                    Text("Open the app and paste a team from Showdown’s Teambuilder → Import/Export.").font(.caption).foregroundStyle(theme.muted)
                }.padding(14).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .widgetURL(URL(string: "ribbonpassport://open"))
            }
        }.containerBackground(for: .widget) { theme.paper }
    }
}
struct EmptyWidget: View {
    var theme: PassportTheme
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Ribbon Passport", systemImage: "rosette").font(.headline).foregroundStyle(theme.accent)
            Text("Open the app to import a backup or Showdown team.").font(.caption).foregroundStyle(theme.muted)
        }.padding(14).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .widgetURL(URL(string: "ribbonpassport://open"))
    }
}
struct PokemonPassportWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "PokemonPassport", intent: SelectPokemonIntent.self, provider: PokemonProvider()) { entry in PokemonWidgetView(entry: entry) }
            .configurationDisplayName("Pokémon Passport")
            .description("Your Pokémon, equipped title and ribbon collection.")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
            .contentMarginsDisabled()
    }
}
struct RibbonTeamWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "RibbonTeam", intent: SelectTeamIntent.self, provider: TeamProvider()) { entry in TeamWidgetView(entry: entry) }
            .configurationDisplayName("Ribbon Team")
            .description("Three or six Pokémon with their top three ribbons.")
            .supportedFamilies([.systemMedium, .systemLarge])
            .contentMarginsDisabled()
    }
}
struct ShowdownTeamWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "ShowdownTeam", intent: SelectShowdownTeamIntent.self, provider: ShowdownTeamProvider()) { entry in ShowdownTeamWidgetView(entry: entry) }
            .configurationDisplayName("Showdown Team")
            .description("Held items, abilities and Tera types for three Pokémon. Large adds natures and moves for up to six.")
            .supportedFamilies([.systemMedium, .systemLarge])
            .contentMarginsDisabled()
    }
}
@main
struct RibbonWidgetBundle: WidgetBundle {
    var body: some Widget { PokemonPassportWidget(); RibbonTeamWidget(); ShowdownTeamWidget() }
}
