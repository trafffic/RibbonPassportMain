import Foundation

extension RibbonCatalog {
    func orderedGames(_ ids: [String]) -> [String] {
        Array(Set(ids)).sorted { (CatalogOrder.gameIndex($0), $0) < (CatalogOrder.gameIndex($1), $1) }
    }
}

struct PassportHonor: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var catalogID: String
    var title: String
    var game: String
    var earned = true
    var date: String = ""
    var note: String = ""
    var photo: Data? = nil
    var trainerMilestone = false
}
struct PassportJournalEntry: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var game: String = ""
    var date: String = ""
    var text: String = ""
    var photo: Data? = nil
}
struct PassportMoveNote: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var move: String
    var game: String
    var note: String = ""
    var homeChecked = false
}
struct PersonalBuild: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var build: ShowdownSet
    var note: String = ""
    var sourceIDs: [String] = []
}
struct TeamBuildMember: Codable, Equatable, Identifiable {
    var id: String
    var species: String
    var nickname: String
    var build: ShowdownSet
    var level: Int? = nil
    var game: String? = nil
    var gender: String? = nil
    var shiny: Bool? = nil
    var gmax: Bool? = nil
    func pokemon() -> RibbonPokemon {
        RibbonPokemon(species: species, nickname: nickname, gender: gender ?? "", shiny: shiny ?? false,
                      currentgame: game ?? "", gmax: gmax ?? false, currentlevel: level ?? 100, source: "showdown", showdownSet: build)
    }
}
struct PersonalTeamBuild: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var members: [TeamBuildMember]
    var note: String = ""
    var sourceIDs: [String] = []
}
struct CommunitySource: Codable, Identifiable {
    var id: String
    var title: String
    var url: String
    var author: String
    var kind: String
    var checkedOn: String
    var reviewStatus: String
    var link: URL? { guard let u = URL(string: url), u.scheme == "https" else { return nil }; return u }
}
struct FieldGuide: Codable, Identifiable {
    var id: String
    var title: String
    var gameIDs: [String]
    var awardIDs: [String]
    var steps: [String]
    var cautions: [String]
    var sourceIDs: [String]
    var teamIDs: [String]?
    var locations: [String: String]?
    var requirements: [String: String]?
    func location(in game: String) -> String? { locations?.first { $0.key.split(separator: " ").contains(Substring(game)) }?.value }
}
struct CommunityTeamMember: Codable {
    var species: String
    var item: String
    var ability: String
    var nature: String
    var evs: String
    var moves: [String]
    var level: Int?
    var ivs: String?
    var teraType: String?
    var build: ShowdownSet {
        ShowdownSet(item: item, ability: ability, nature: nature, evs: evs,
                    ivs: ivs?.contains("Hyper Trained") == true ? "" : ivs ?? "", teraType: teraType ?? "", moves: moves)
    }
    func pokemon(game: String) -> RibbonPokemon {
        let gigantamax = species.hasSuffix("-Gmax")
        let name = gigantamax ? String(species.dropLast(5)) : species
        return RibbonPokemon(species: RibbonCatalog.shared.speciesID(name) ?? RibbonCatalog.normalise(name),
                             currentgame: game, gmax: gigantamax, currentlevel: level ?? 50, source: "showdown", showdownSet: build)
    }
}
struct CommunityResult: Codable {
    var wins: Int?
    var event: String?
    var evidence: String
    var label: String { wins.map { "\($0.formatted()) published wins" } ?? event ?? "Community method" }
}
struct CommunityCarry: Codable { var status: String; var note: String }
struct CommunityTeam: Codable, Identifiable {
    var id: String
    var title: String
    var gameIDs: [String]
    var facility: String
    var format: String
    var author: String
    var sourceIDs: [String]
    var members: [CommunityTeamMember]
    var documentedResult: CommunityResult?
    var ribbonMasterSlot: CommunityCarry
    var strategySummary: String
    var checkedOn: String
    var sourceVariantNote: String?
    var regulation: String?
    var completeness: String?
}
struct HonorDefinition: Codable, Identifiable {
    var id: String
    var title: String
    var games: [String]
    var summary: String
    var trainerMilestone: Bool
    var sourceIDs: [String]
}
struct CommunityContent: Decodable {
    var sources: [CommunitySource]
    var guideModules: [FieldGuide]
    var teamCandidates: [CommunityTeam]
    var honorDefinitions: [HonorDefinition]
    static let shared: CommunityContent = {
        guard let u = Bundle.main.url(forResource: "community-content", withExtension: "json", subdirectory: "RibbonAssets"),
              let data = try? Data(contentsOf: u), let content = try? JSONDecoder().decode(CommunityContent.self, from: data) else {
            preconditionFailure("Bundled community guides are missing or invalid.")
        }
        return content
    }()
    func guides(award: String? = nil, game: String? = nil) -> [FieldGuide] {
        guideModules.filter { (award == nil || $0.awardIDs.contains(award!)) && (game == nil || $0.gameIDs.contains(game!)) }
    }
    func source(_ id: String) -> CommunitySource? { sources.first { $0.id == id } }
}
extension RibbonPokemon {
    /// Website imports replace game data while retaining the user's local passport work.
    mutating func preservePassportExtras(from prior: RibbonPokemon) {
        honors = prior.honors; journal = prior.journal; moveNotes = prior.moveNotes
        savedBuilds = prior.savedBuilds; communitySourceIDs = prior.communitySourceIDs
    }
}
extension CollectionSnapshot {
    @discardableResult mutating func copyCommunityTeam(_ source: CommunityTeam, game: String) -> String? {
        guard source.gameIDs.contains(game) else { return nil }
        let members = source.members.map { value -> RibbonPokemon in
            var p = value.pokemon(game: game); p.communitySourceIDs = source.sourceIDs; return p
        }
        let team = RibbonTeam(name: source.title, memberIDs: members.map(\.id), communitySourceIDs: source.sourceIDs)
        pokemon.append(contentsOf: members); teams.append(team)
        selectedTeamID = team.id; selectedCompetitiveTeamID = team.id; selectedCompetitiveID = members.first?.id
        organizeSections(); return team.id
    }
    mutating func restoreTeamBuild(_ version: PersonalTeamBuild, teamID: String) {
        guard let index = teams.firstIndex(where: { $0.id == teamID }) else { return }
        var ids: [String] = []
        for member in version.members.prefix(6) {
            if let pIndex = pokemon.firstIndex(where: { $0.id == member.id && $0.showdownSet != nil }) {
                pokemon[pIndex].showdownSet = member.build; ids.append(member.id)
            } else {
                var p = member.pokemon(); p.communitySourceIDs = version.sourceIDs
                pokemon.append(p); ids.append(p.id)
            }
        }
        teams[index].memberIDs = ids
        organizeSections()
    }
}
struct PassportAppBackup: Codable {
    var format = "ribbon-passport"
    var version = 1
    var collection: CollectionSnapshot
    func encoded() throws -> Data { try JSONEncoder().encode(self) }
    static func decode(_ data: Data) throws -> CollectionSnapshot {
        let backup = try JSONDecoder().decode(Self.self, from: data)
        guard backup.format == "ribbon-passport", backup.version == 1 else { throw ImportError.invalid("This app backup version is not supported.") }
        guard Set(backup.collection.pokemon.map(\.id)).count == backup.collection.pokemon.count,
              Set(backup.collection.teams.map(\.id)).count == backup.collection.teams.count else { throw ImportError.invalid("The backup contains repeated record IDs.") }
        return backup.collection
    }
}
