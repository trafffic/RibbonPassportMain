# Future feature ideas

Remaining ideas only, grouped into related pieces of work. An idea appearing here is not approval to implement it. Start each group with a small step and review it before expanding; the groups are not single releases and their order is not an agreed priority.

Implemented features and their completed storyboard have been removed from this backlog. Their implementation notes remain in UI-UPDATE.md, TESTING.md and Research/. Original feature IDs are retained for reference.

The remaining confirmed favourites are **F07 Collection goals** and **F15 Showcase cards**. Online backup remains excluded at the user's request.

## 1. Collection organisation

| ID | Feature | Scope |
| --- | --- | --- |
| F02 | Advanced collection filters | Filter by owned/earnable ribbons, reachable games, shiny status, level and other saved details. |
| F17 | Smart boxes | Save filtered views such as In training, Missing Footprint or Ready to transfer, while keeping physical PC placements intact. |
| F01 | Bulk editing | Select several Pokémon to update their game, box or ribbons together; retain specific earning-game records. |
| F13 | Trade planner | Wanted/offered lists, favourite targets and a shareable trade card. No automatic messages or trades. |

**Small starting step:** add a few useful filters, then save those filters as smart boxes. Add multi-selection and bulk editing afterward, using existing recovery history. Build wanted/offered lists on the same collection tools.

## 2. Goals, hunts and play sessions

| ID | Feature | Scope |
| --- | --- | --- |
| F07 | Collection goals ★ | User-defined living dex, shiny dex or themed collection checklists, with progress based on saved Pokémon and manual check-offs. |
| F16 | Game-session checklist | A user-authored list of tasks for the next play session, optionally grouped by game. |
| F09 | Hunt tracker | Encounter counter, hunt sessions, elapsed time, method and target; optional Home Screen counter widget. |

**Small starting step:** create one custom goal with manual check-offs. Add collection-driven progress next, then session checklists and hunt tracking. Completed hunts can link to the existing Pokémon journal.

## 3. Showcase and display

| ID | Feature | Scope |
| --- | --- | --- |
| F15 | Showcase cards ★ | Export a styled image of a Pokémon, passport, team or completed collection using the app's pixel themes. |
| F05 | Ribbon display preferences | Review remaining options for automatic Memory Ribbon display, Strange Ball display, completed-Pokémon highlighting and World Ability visibility. Retain existing Memory Ribbon behaviour; add only missing controls. |

**Small starting step:** export one Pokémon passport card using an existing pixel theme. Expand to teams and collection goals afterward. Review missing display preferences separately before implementing them.

## 4. Pokémon details and save importing

| ID | Feature | Scope |
| --- | --- | --- |
| F04 | More Pokémon details | Met date/location, trainer ID, origin mark, Pokérus, Totem status, size and star/square shiny types. Add only fields not already supported. |
| F19 | Save-file viewer and Pokémon import | Preview a supplied save's boxes/party and import selected Pokémon or boxes. Initial support target: main-series GBA, DS and 3DS games (Generations III–VII). |
| F20 | Wireless save import over FTP | Connect to a homebrew FTP server on the 3DS, browse exported saves and download a copy into the save viewer. Proposed saved connection and backup-folder shortcuts; initial client would only browse/download. |

**Small starting step:** agree which additional details to preserve, then preview one supported save format. Enable selective import after preview works, expand across GBA–3DS in stages, and add FTP last.

## 5. Competitive planning and results

| ID | Feature | Scope |
| --- | --- | --- |
| F10 | Team analysis | Shared weaknesses/resistances and move-type coverage, with format-aware rules where needed. |
| F14 | Training planner | EV target/current checklist, move and item acquisition tasks, and game-specific training plans. |
| F12 | Match journal | Record opponent/team, result, notes and optional replay links; show trends from recorded matches. |

**Small starting step:** show type weaknesses, resistances and move coverage for a saved team. Use the existing build notebooks as the basis for training tasks and match records, then add trends once enough matches have been recorded.

## 6. Move Dex follow-up

| ID | Feature | Scope |
| --- | --- | --- |
| F23 follow-up | Verified move availability and transfer warnings | Extend the existing manual Move Dex notes with sourced, version-specific learnability and transfer information. Manual notes are already implemented and are outside this remaining scope. |

**Small starting step:** verify move availability for one game pair before expanding. Never infer HOME registration from possession of a move or treat Move Dex tasks as Ribbon Master requirements. Automatic detection from saves depends on F19 and must use only recorded facts.

## Save-file viewer: initial scope

The user requested GBA through 3DS games, inclusive, as the first support target:

- GBA: Ruby, Sapphire, Emerald, FireRed and LeafGreen.
- DS: Diamond, Pearl, Platinum, HeartGold, SoulSilver, Black, White, Black 2 and White 2.
- 3DS: X, Y, Omega Ruby, Alpha Sapphire, Sun, Moon, Ultra Sun and Ultra Moon.

This is a requested support range, not a claim of implemented compatibility. Suggested first version: read-only viewing of user-supplied decrypted/raw saves, with a preview before importing Pokémon into app boxes. Exact file formats, technical approach and release order remain to be evaluated.

Import only details actually recorded in the save. Do not infer individual ribbon earning games or a complete journey history. Reimport should offer duplicate/update review and preserve app-authored journal entries, goals and other metadata. Console save extraction, save editing, GameCube titles and 3DS Virtual Console Gen I/II saves are outside this initial list unless separately requested.

Wireless import proposal: an in-app FTP client/file browser connects to ftpd (or a compatible server) on the same reachable local network. The user first exports a usable save with an appropriate console backup tool; FTP transports that exported file and does not itself extract or decrypt game saves. Preview and select Pokémon before importing. GBA/DS save extraction depends on cartridge/emulator setup and needs separate verification. References: https://github.com/mtheall/ftpd and https://github.com/bernardogiordano/checkpoint. This is a feasibility discussion, not implementation approval.

## Shared design and implementation decisions

- Keep Ribbons and Competitive separate.
- Preserve the pixel artwork/font direction and avoid unnecessary explanatory text.
- Prefer optional tools reached from the relevant screen over extra permanent controls on the main PC screen.
- Use existing recovery and complete local app backups for new personal data. Preserve compatibility with older collections and keep external exports limited to supported fields.
- Define additional Pokémon data before save-import mapping. Filters support smart boxes; goals and existing journal entries can feed showcase cards. FTP depends on working file import.
- Keep optional honors separate from actual ribbon/mark totals, transfer checks and Ribbon Master completion.
- Verify game-specific facts and source attribution before publishing new reference content.

Reference for the original collection-gap discussion: https://ribbons.guide/ (reviewed 15 October 2026). Community research and source links remain in Research/ and the bundled content catalogue.
