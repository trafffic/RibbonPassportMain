# Feature ideas

Living discussion list. An idea appearing here is not approval to implement it.
Status: F07, F08, F15 and F18 are the user's favourites. F18 local recovery history is implemented. F06 online backup has been declined. Community storyboard screens 2–8 are implemented; see the decisions below. Other features remain unscheduled.

## Gaps identified from ribbons.guide

| ID | Idea | Scope |
| --- | --- | --- |
| F01 | Bulk editing | Select several Pokémon to update their game, box or ribbons together; retain specific earning-game records. |
| F02 | Advanced collection filters | Filter by owned/earnable ribbons, reachable games, shiny status, level and other saved details. |
| F03 | Extra achievements | Passport entries for Leaf Crown, Pokéstar Shine, Time Travel Award and GO Best Buddy Ribbon. |
| F04 | More Pokémon details | Met date/location, trainer ID, origin mark, Pokérus, Totem status, size and star/square shiny types. |
| F05 | Ribbon display preferences | Automatic Memory Ribbon options, Strange Ball display, completed-Pokémon highlighting and World Ability visibility. |
| F06 | Online backup — declined | Removed from the plan at the user's request. |

Comparison reference: https://ribbons.guide/ (reviewed 15 October 2026).

## Broader app ideas

| ID | Idea | Scope |
| --- | --- | --- |
| F07 | Collection goals | User-defined living dex, shiny dex or themed collection checklists, with progress based on saved Pokémon and manual check-offs. |
| F08 | Pokémon journal | Personal notes, photos, milestones and stories attached to a Pokémon's passport. |
| F09 | Hunt tracker | Encounter counter, hunt sessions, elapsed time, method and target; optional Home Screen counter widget. |
| F10 | Team analysis | Shared weaknesses/resistances and move-type coverage, with format-aware rules where needed. |
| F11 | Build library | Multiple named competitive builds per Pokémon, plus saved team versions for comparison and restoration. |
| F12 | Match journal | Record opponent/team, result, notes and optional replay links; show trends from recorded matches. |
| F13 | Trade planner | Wanted/offered lists, favourite targets and a shareable trade card. No automatic messages or trades. |
| F14 | Training planner | EV target/current checklist, move and item acquisition tasks, and game-specific training plans. |
| F15 | Showcase cards | Export a styled image of a Pokémon, passport, team or completed collection using the app's pixel themes. |
| F16 | Game-session checklist | A user-authored list of tasks for the next play session, optionally grouped by game. |
| F17 | Smart boxes | Saved filtered views such as In training, Missing Footprint or Ready to transfer; keep physical PC placements intact. |
| F18 | Collection recovery history — implemented | Settings → Recovery history: restore deleted Pokémon/teams and earlier saved details locally. Up to 20 versions per item, 500 total. No online backup. |
| F19 | Save-file viewer and Pokémon import | Preview a supplied save's boxes/party and import selected Pokémon or boxes. Initial support target: main-series GBA, DS and 3DS games (Generations III–VII). |
| F20 | Wireless save import over FTP | Connect to a homebrew FTP server on the 3DS, browse exported saves and download a copy into the save viewer. Proposed saved connection and backup-folder shortcuts; initial client would only browse/download. |

## Save-file viewer: initial scope

The user requested GBA through 3DS games, inclusive, as the first support target:

- GBA: Ruby, Sapphire, Emerald, FireRed and LeafGreen.
- DS: Diamond, Pearl, Platinum, HeartGold, SoulSilver, Black, White, Black 2 and White 2.
- 3DS: X, Y, Omega Ruby, Alpha Sapphire, Sun, Moon, Ultra Sun and Ultra Moon.

This is a requested support range, not a claim of implemented compatibility. Suggested first version: read-only viewing of user-supplied decrypted/raw saves, with a preview before importing Pokémon into app boxes. Exact file formats, technical approach and release order remain to be evaluated.

Import only details actually recorded in the save. Do not infer individual ribbon earning games or a complete journey history. Reimport should offer duplicate/update review and preserve app-authored journal entries, goals and other metadata. Console save extraction, save editing, GameCube titles and 3DS Virtual Console Gen I/II saves are outside this initial list unless separately requested.

Wireless import proposal: an in-app FTP client/file browser connects to ftpd (or a compatible server) on the same reachable local network. The user first exports a usable save with an appropriate console backup tool; FTP transports that exported file and does not itself extract or decrypt game saves. Preview and select Pokémon before importing. GBA/DS save extraction depends on cartridge/emulator setup and needs separate verification. References: https://github.com/mtheall/ftpd and https://github.com/bernardogiordano/checkpoint. This is a feasibility discussion, not implementation approval.

## Discussion notes

### Proposed work groups

The user asked to proceed slowly and group related features. These are discussion groups, not single releases or approval to implement. Start with a small step and review it before expanding. Group order is suggested, not agreed.

| Suggested order | Group | Features | Small starting step |
| --- | --- | --- | --- |
| 1 | Local recovery | F18 Recovery history | Recover deleted Pokémon/teams and earlier saved details on this device. Online backup is excluded. |
| 2 | Save files and Pokémon details | F04 More Pokémon details; F19 Save viewer/import; F20 FTP import | Agree which details to preserve, then preview one supported save format before enabling import. Expand across GBA–3DS in stages; add FTP after file import works. |
| 3 | Passport and sharing | F08 Pokémon journal; F03 Extra achievements; F15 Showcase cards; F05 Ribbon display preferences | Add a dated text journal entry to one passport, then review the UI before adding photos, achievements and share cards. |
| 4 | Collection organisation | F02 Advanced filters; F17 Smart boxes; F01 Bulk editing; F13 Trade planner | Add a few useful collection filters. Use these as the basis for saved views, multi-selection and wanted/offered lists later. |
| 5 | Goals and play sessions | F07 Collection goals; F09 Hunt tracker; F16 Session checklist | Create one custom checklist goal and mark progress manually. Add collection-driven progress, hunts and session tasks later. |
| 6 | Competitive tools | F11 Build library; F10 Team analysis; F14 Training planner; F12 Match journal | Save two named builds for one Pokémon, then expand to team versions, analysis, training and match notes. |

Dependencies: establish recovery before destructive bulk changes or updating existing records from saves. Define Pokémon data before import mapping. Filters support smart boxes. Journals and goals can both feed showcase cards. Keep goals separate from passport work so this user favourite can move earlier without waiting for every passport feature.

- Keep Ribbons and Competitive separate.
- Preserve the pixel artwork/font direction and avoid unnecessary explanatory text.
- Prefer optional tools reached from the relevant screen over extra permanent controls on the main PC screen.
- The user confirmed F07 (Collection goals), F08 (Pokémon journal), F15 (Showcase cards) and F18 (Collection recovery history) as favourites. No order of priority has been chosen.

## Decisions

Shortlist confirmed: Collection goals, Pokémon journal, Showcase cards and Collection recovery history. The user chose local recovery history as the first implementation. Online backup is declined. Continue workshopping the remaining features before building them.

F18 completed: automatic saved-change history, deleted-item recovery, version preview and comparison, reversible restores, and safe placement/team restoration. History starts with future saved changes; earlier deletions are not recoverable retroactively. Validation: 13 recovery unit/render tests, eight existing regressions, three simulator interaction tests, and an unsigned Release iPhone app/widget build.

Save-file viewer support preference confirmed: GBA → DS → 3DS main-series titles, inclusive. Implementation has not been requested yet.

## Community feedback storyboard — 16 October 2026

Source: https://www.reddit.com/r/pokemonribbons/comments/1x6w2n1/been_working_on_an_app_for_tracking_ribbons_like/

Status: storyboard screens 2–8 are implemented. Guides and source cards open from award details; the curated team library opens from Competitive; build notebooks open from Pokémon/team details; honors and Journey/Move Dex notes open from the passport Journey tab and Options; Settings contains Sources & credits and complete local app backups. The working research remains in `Research/`; edited offline content is bundled in `RibbonAssets/community-content.json`. Keep Ribbons and Competitive separate and avoid adding permanent controls to the PC home screen.

Confirmed content decisions: cover all ribbon games including Switch; start with a few well-documented teams; provide offline summaries with original source links. Allow manual Pokémon milestones even when the game records the feat for the trainer/save, with an explicit scope label. These optional milestones never count as actual ribbons/marks or affect Ribbon Master completion. Dates are optional for historic records. Screen 1 is outside the requested 2–8 scope; use the existing contextual entry points.

| Feature | Proposed location | Scope |
| --- | --- | --- |
| F03 Extra achievements — expanded | Passport → Honorary achievements | Optional records separate from actual ribbon/mark totals, earnable filters, last-chance checks and Ribbon Master completion. Candidate honors from the comments: Trainer Hill, Pokéathlon, Shiny Crown (clarify exact achievement), Unova Champion, Pokéstar Studios, Pokémon World Tournament, Black Tower/White Treehollow, Battle Subway and Academy Ace Tournament. Define game/species eligibility before publishing them. |
| F08 Pokémon journal — expanded | Journey → Journey notes; honor record → attachment | Dated notes, milestones and optional local screenshots. An attachment is supporting evidence, not automatic verification. Store references safely and include journal/achievement metadata in local recovery and app backup formats. |
| F21 Ribbon field guides | Ribbon detail → Guide; compact passport overview shortcut | Short, game-specific guides, contest advice, preparation checklists and links to appropriate teams. Keep official descriptions separate from guide prose. Paginate long guides or use short sections rather than one endless screen. |
| F22 Curated community team library | Competitive → Team library; contextual guide link | Battle Tower teams, contest strategies, online rental codes, battle records and instructions. Filter by game/facility/format, explain the Ribbon Master slot, credit original authors, track source/review dates and show stale or unknown code/eligibility status. No unreviewed sample team described as proven. |
| F11 Build library — expanded | Team detail → Save personal copy → Build notebook | Multiple named builds for a Pokémon, personal notes and existing Showdown text export. Preserve original source and keep personal edits separate. Do not silently change a Ribbon Master’s actual recorded game or details when viewing a proposed build. |
| F23 HOME Move Dex notes | Journey notes → Move Dex notes | Start with manual move/game notes and a manually checked HOME record status. Later add verified version-specific learnability and transfer warnings. Never infer HOME registration from possession of a move or treat a movedex task as a Ribbon Master requirement. |
| F24 Sources and review | Guide/team → source card; Settings → References & credits | Original link, author, exact game/format, relevant battle record and last review. Link to community work first; obtain permission where needed before redistributing it. Save correction drafts locally; sharing needs a separate explicit action. AI-related comments are development feedback, not a request for an AI feature in the app. |

### Storyboard flow

1. Passport entry: compact rows for Ribbon field guide, Honorary achievements and Journey notes, alongside current owned ribbon and transfer status UI. No new bottom navigation destination.
2. Ribbon field guide: select a ribbon, switch from Description to Guide, follow short steps and open a relevant team or source card. Sample guide text needs editorial verification before release.
3. Community teams: game/facility-specific team list, strategy, documented results and Ribbon Master slot. Online mode adds regulation/rental validity; contests opens advice rather than pretending contest advice is a battle team.
4. Build notebook: save a personal team copy, switch named builds, add notes and export through the existing Showdown pathway.
5. Honors album: browse optional achievements by compatible game/generation, distinct from actual awards. Grid and list layouts are alternatives to review.
6. Honor record: select game, optional date, note, optional screenshot and earned state. Do not assume historic completion dates or auto-detect unsupported save flags.
7. Journey notes: memories/photos and Move Dex notes as local subsections, without a fourth passport tab. Metadata survives changes to the tracked Pokémon and save reimports.
8. Source card: see attribution and review status, follow the original guide and prepare a local correction note. No automatic posting or private Discord ingestion.

### Proposed delivery order

1. **Shared groundwork:** persistent IDs for honors/guides/team references and journal records; backward-compatible decoding, versioned app backups and recovery integration. Keep existing ribbons.guide and Showdown exports restricted to compatible fields. Do not change existing ribbon completion logic to include honors.
2. **Small guide pilot:** one complete, sourced guide for a selected game plus one reviewed Battle Tower team and one contest guide. Review the UI and factual content before expanding the catalogue. Tie a guide to the existing ribbon detail so it can be shipped before the full library.
3. **Honor records and journal:** starter catalog, game eligibility, manual earned state, notes and local photos, with correction/removal/recovery. Expand every proposed honor only after checking what that accomplishment actually records and whether it belongs to the Pokémon or to the save/trainer.
4. **Teams and personal builds:** curated catalogue and saved copies, source provenance, multiple builds and Showdown export. Rental codes and competitive eligibility must be versioned by game/regulation and reviewed when rules change; offline content must show its review date.
5. **Move notes:** manual checklist first; add verified move availability/transfer/HOME warnings separately. Defer automatic save detection to F19, importing only recorded facts.

Validation for implementation: old collections decode without loss; optional honors never affect ribbon counts or transfer readiness; correct game-specific guides; saved team copies preserve attribution; photos and notes recover correctly; unsupported external export fields stay excluded; compact-phone labels and pagination stay readable; VoiceOver and reduced-motion behavior remain usable. Do not assert current ranked eligibility or a code’s validity from an old guide.

Feedback references: Sredleg honors https://www.reddit.com/r/pokemonribbons/comments/1x6w2n1/comment/pgz83wo/ ; screenshots https://www.reddit.com/r/pokemonribbons/comments/1x6w2n1/comment/pgzbx5v/ ; Dahks guides/teams/builds/moves https://www.reddit.com/r/pokemonribbons/comments/1x6w2n1/comment/pgzpj07/ .
