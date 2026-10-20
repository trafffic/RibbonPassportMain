# Widget layouts and Alpha Sapphire mascot — 20 October 2026

Alpha Sapphire's light/dark Primal Kyogre mascots now use their visible pixel bounds when loaded. The bundled 64 × 64 images contain 36 × 21 pixels of visible artwork; trimming that padding lets the existing aspect-fit views use their allocated space. Source images and other game mascots are unchanged.

Widget Studio now offers Pocket companion, Ribbon cabinet, Journey ticket, and Next ribbon under **Pokémon Passport → Layout**, with their recommended size selected on layout changes. These layouts are also built-in choices in the Home Screen Pokémon Passport widget's **Saved design** picker. Existing saved designs retain the classic layout, selection, palette, and defaults. Theme changes preserve the chosen layout. The shared SwiftUI renderer handles all three supported widget sizes.

Next ribbon uses the existing availability/transfer rules, prioritizes unowned last-chance ribbons, names the actual earning game, and keeps unresolved Footprint warnings visible. Journey and ribbon widgets link to the corresponding passport tab. The cabinet shows a bounded selection and a remaining-ribbon count when needed; journeys use recorded visits and known endpoints.

Validation in this Windows session: inspected both mascot assets, reviewed the shared source and integration, and ran `git diff --check`. **Xcode and the iPhone SDK are unavailable here: no native build, XCTest execution, simulator run, or native screenshot validation has been performed for this change.** Added `FeatureWidgetTests` cover both mascot appearances, legacy style decoding and layout round trips, default independence, rule-based goals, another game in the same generation, unresolved Footprint checks, and native render attachments for every layout/size/appearance. These tests still need to run in Xcode.

Before release, run Command + U in Xcode, inspect the new render attachments (including 300-point widths and 115% text), and check a saved design on an actual Home Screen. Confirm mascot size in the game picker and Journey, tap Journey ticket/Next ribbon, and test repeated widget links while the passport is already open.

---

# Usability passes 1–3 — 17 October 2026

The implementation covers empty collection entry points, explicit import/demo/edit actions, separate ribbon details and recording controls, Journey shortcuts and pagination labels, unresolved transfer status and a direct met-level editor, comparison-first recovery previews, simplified widget setup, direct numeric levels, optional date pickers, labelled editor controls and community-card game names. Optional/Last chance markers and the existing ribbon rules remain available.

Before the request to stop simulator work, the run completed **93 unit/render tests and 16 interaction tests with zero failures** (`TEST SUCCEEDED`). Interaction coverage included empty collections, direct Pokémon editing, Move Dex access, optional memory dates and reopening, recovery restore placement, optional widget customisation/setup, ribbon details versus recording, and existing gallery/community/recovery/transfer flows. Tests use isolated in-memory collections and a separate Debug preferences suite.

Subsequent refinements include toolbar touch targets, consistent Milestones/Cancel wording, ribbon status/accessibility markers and the met-level interaction fixture. The additional met-level Save/Undo interaction test has **not been executed**. Its fixture uses a level-85 Pokémon with an unknown met level so that the unresolved Footprint warning is present. The earlier 16-test result does not cover that added test or every final refinement.

After simulator work was stopped, review continued through source inspection and iPhone SDK compilation only. No simulator was launched and no screenshots or simulator streams were captured during that continuation. Final visual review, physical-device interaction, VoiceOver and larger text sizes remain unverified for this update.

The final unsigned **Release iPhone app and widget build passed** (`BUILD SUCCEEDED`). A separate Debug **build-for-testing for a generic iPhone passed** (`TEST BUILD SUCCEEDED`), compiling the unit/UI test targets and the added met-level test without executing them. `git diff --check` also passed. Device signing, App Groups and persisted collection formats were not changed.

On an iPhone, confirm these remaining interactions:

1. In a Gen VI-or-later Footprint warning for a Pokémon above level 70, open **Set met level**, enter a valid value, save and Undo; check both the passport and standalone ribbon editor paths.
2. Try numeric entry, optional dates, keyboard dismissal and Save/Cancel with a small screen and larger text.
3. Save a widget design, follow the Home Screen setup steps and check an existing widget's saved design remains independent.
4. Check menu/dialog dismissal with touch and VoiceOver, and select/cancel Photos and Files operations.

See [UI-UPDATE.md](UI-UPDATE.md) for the implemented changes. Older validation records below describe their respective revisions.

---

# Community screens — 17 October 2026

The new feature checks and relevant existing regressions passed **28 unit/render tests** with zero failures. All **four simulator interaction flows** passed: honor add/reopen/remove; journal and manual Move Dex saving; guide/source navigation and author search in Settings; and attributed team copying followed by named team-version saving. The app and widget extension pass an unsigned Release iPhone build. Native screenshots were inspected at 320- and 390-point widths in light/dark, including the compact guide, credits, source card and notebooks.

Coverage includes all 423 existing award/game guide mappings, source references, exportable independent team copies, legacy collection decoding, full app-backup round trips with attachments, unsupported backup versions, optional honors excluded from award/transfer logic, recovery of removed notes/photos, matched website reimport preservation, external export field exclusion, team-version restoration without changing existing passport details, missing-member reconstruction, origin-aware honor game choices and optional historic-date validation. Existing recovery, Memory Ribbon, description-bubble and compact passport render regressions also passed.

Tests inject collections and save closures; interaction tests use the isolated Debug fixture and defaults suite. They do not use the user's collection. Screenshots/notes/builds are encoded in app backups and recoverable Pokémon/team records. Source correction notes are local app-backup fields. Source author links are tested for valid bundled references, not live code/rental availability or independent in-game success.

On a physical iPhone, check screenshot selection from Photos (including cancellation or a failed iCloud download), keyboard dismissal, VoiceOver, larger text sizes, and saving/restoring an app backup through Files. Live photo-library selection and physical-device behavior were not automated. Published team results remain attributed source claims; exact mechanics still marked pending in Research are omitted or qualified in the bundled summaries.

---

# Current UI update validation

## Memory Ribbon display regression

Five focused model regressions passed: pre-Gen VI originals, consolidation across Gen VI–IX and HOME, normal/gold thresholds, no duplicate Memory icons, explicit Memory-only imports, mark exclusion, original earning history and JSON round trips. The simulator checks passed the modern PC/passport count and icons, Memory description bubble, expanding the Owned groups, removing an original ribbon, Undo, and the existing pre-Gen VI passport edit/save/navigation flow. The iPhone app and widget extension pass an unsigned Release build. These displays use the existing merge logic without rewriting original ribbon records or changing transfer eligibility.

## Owned ribbon descriptions

The description bubble passed two placement tests for compact widths, edge columns, below-icon fallback and bounded accessibility content, plus a native render check in light/dark with normal/larger text. The simulator interaction test passed direct switching between two ribbons, exact names and descriptions, selected-icon toggling, outside-tap dismissal, unchanged ownership and Journey navigation. The final iPhone app/widget unsigned Release build passed. Source attribution and offline in-game wording are recorded in CREDITS.md.

## PC terminal and passport tabs

The redesign passed three focused native/resource checks and seven simulator interaction cases. These cover the 16 bundled Sun/Moon backgrounds (both full artwork and interior crops), the artwork tile boundaries, native renders of the terminal with/without its party rail and all three passport tabs at 320/390 points in light/dark, drag/swap/cancel/box-hover behavior, specific-game transfer checklist edits and Undo, automatic ribbon saving across tabs and reopening, and wallpaper persistence without changing another box. The final spacing pass reran native renders, checked the party’s bottom alignment during a box/party swap, and repeated the transfer flow. The iPhone app and widget extension also pass an unsigned Release build. All UI interactions use the isolated Debug collection and defaults suite.

On device, choose **Box options → Wallpaper** to select from all 16 backgrounds, toggle **Party** in the artwork header, and open **Passport → Overview / Ribbons / Journey**. The PC ribbon-count shortcut opens the same Ribbons tab. Changes in that tab save automatically; separate Add/Edit Pokémon sheets retain their Save action. Verify finger tracking and the system’s larger accessibility text sizes on a physical iPhone. Signing settings are preserved.

## Local recovery history

The recovery update passed **21 focused unit/render checks** (13 recovery cases and eight existing collection/storage/export regressions), **three simulator interaction tests**, and an unsigned **Release iPhone app/widget build**. The final runs completed with **TEST SUCCEEDED** and the device build with **BUILD SUCCEEDED**. Native screen renders were inspected at 320- and 390-point widths in light/dark. The simulator screenshot from Settings also confirms the recovery navigation and filter layout.

Coverage includes full record preservation, deleted Pokémon/teams, stable identities, no-op selections/storage moves, occupied-slot and full-party fallbacks, recreated boxes/teams, missing team members, competitive/ribbon separation, reversible version restores, history limits, import replacements, legacy collection decoding, JSON persistence and failure-before-save handling. The store tests inject snapshots and a save closure; UI tests use the isolated in-memory Debug fixture and separate defaults suite. They do not modify the user's collection. Simulator taps exercise Deleted/Versions/All filters, recovery back into the original PC slot, and restoring/reversing earlier details.

On device, use **Settings → Recovery history** after a saved edit or deletion. Confirm the saved preview and changes, restore, then close/reopen the app. Verify that the latest details replaced by a restore remain available as **Before restore**. History begins with saves after this update and is limited to 20 versions per Pokémon/team and 500 total, with the oldest removed at the limits. Online backup is excluded; signing details are unchanged.

## Transfer checklist

The transfer update passed **15 focused unit/render tests** and **1 simulator interaction test**. A final focused run rechecked the Footprint boundary and the complete drawer interaction with **TEST SUCCEEDED**. The tests use the isolated in-memory Debug fixture, without reading or writing the user's collection. Native renders cover the warning/safe drawer states at 320- and 390-point widths in light/dark, alongside the manager's 12/16/32 layouts.

Checks cover the whole departure generation (including X/Y ribbons while viewing Alpha Sapphire), compatible later destinations, species/challenge restrictions, the Footprint level-70/71 boundary, the Gen IV → V met-level reset, BDSP's voiceless friendship exception, unknown met levels, and species unable to transfer up. Simulator taps verify adding ribbons from the drawer, selecting HeartGold specifically for Legend, the green status, Undo, Save and reopening. The first interaction run exposed an empty-area tap issue in short checklist rows; the whole row now responds to taps. The app and widget extension also compile for iPhone with signing disabled.

On device, open **Manage ribbons → Review**. Check that the warning covers every game in the selected generation even with a filter active, and review the **Can wait** generations. At larger accessibility text sizes or short screen heights, the drawer uses scrolling only when its content cannot fit. Existing signing settings are preserved.

## Drag interaction and last-chance highlights

The final focused run completed **20 unit/render tests** and **4 simulator touch tests**, all passing. The app and widgets also completed an unsigned iPhone build. The project now includes 54 unit tests plus 4 UI tests; the earlier complete run below refers to the prior 51-test suite.

Simulator touch tests in `PCInteractionUITests` exercise moves into empty slots, occupied-slot swaps, box/party exchanges, invalid outside drops, and cancellation after hovering over a box arrow. They run with an isolated in-memory collection and a separate defaults suite in Debug; release builds ignore the test launch environment. The UI tests do not read or write the user's collection. New unit cases cover a full-party swap, compact party ordering, section boundaries, invalid slots, exact target frames and persistence. Existing cross-box swap regressions remain in place. Native renders verify the amber ribbon styling at 12, 16 and 32 per page in both appearances.

On an iPhone, check finger tracking, the 0.14-second landing and swap animation, hover across a box boundary and continue into a slot, and repeat with Reduce Motion on. Check that no green system drag badge or drag haptic appears. The **…** menu next to the selected Pokémon replaces its old long-press context menu. These feel and accessibility checks still benefit from a physical device.

## Ribbon manager validation

The ribbon-manager update added **9 tests** to the then-existing 42-test suite. The manager checks cover the 106-ribbon catalogue, the 12/16/32 cycle, specific earning games without duplicate ownership, removal/restoration, old generation-only records, unchanged Memory Ribbon totals, directed transfer paths, species/forms, Mythical/Legendary restrictions, BDSP Tower exclusions, Shadow and level requirements, compatible later-generation opportunities, and the supported export fields. Native renders were inspected at 320- and 390-point widths for all three page sizes in light/dark, plus the scrolling Owned drawer and generation picker. The final app and widget extension also compile for iPhone with signing disabled.

The full run reported all 51 cases passing with zero failures, then its Xcode driver stalled during finalisation and was stopped. The focused 9-test ribbon run completed with **TEST SUCCEEDED**, and the unsigned iPhone build completed with **BUILD SUCCEEDED**. This driver issue remains a test-environment limitation.

On iPhone, open **Manage ribbons** from the PC, passport and Pokémon editor. Add a ribbon in one game, verify it appears only under that game's stamp, tap it again to remove it, and Undo. Check **All** with Earnable only on/off, and cycle **12 → 16 → 32 → 12**. Review a generation-only record using **Owned ribbons → Set game**. Save, reopen the app, and check the widget; dismiss an unsaved manager to confirm its draft is discarded. Installation and hands-on device interaction remain device checks.

The app and widget extension build with Xcode 27.0 for the iOS 27.0 simulator. The earlier complete run passed all 51 native tests. The native suite covers existing imports and demo refresh, old-format collection decoding, PC box reconciliation/swaps, the six-member party limit, ribbon locations, named widget designs, font loading and Showdown export/import. Widget render attachments cover all seven layouts in light/dark, narrow layouts at 115% text size, all five theme packs across seven layouts, the six widget backgrounds, all 16 Sun/Moon PC wallpapers, and the PC, passport, add-Pokémon and Widget Studio screens. New regressions cover same-generation origin/current visits, complete chronological catalogue coverage, zero-number alternate forms, built-in themes with preserved custom defaults, older box/style decoding, independent wallpapers, manual entries and storage overflow. Additional regressions cover game abbreviations, chronological search results, splitting legacy mixed boxes without losing records, independent selections/default teams, and all 16 original wallpaper assets. Further checks cover the actual wallpaper tile boundaries, cross-box swaps and section boundaries, visited-game stamps, manual Pokémon exported to Showdown, EV/IV validation, version 5 ribbons.guide round trips, required capture fields, supported-form mapping, omitted app metadata and preservation of an appended website backup.

Run **Command + U** in the RibbonPassport scheme with an iPhone simulator selected. Signing settings in the project are preserved. The bundled pixel font is available in both targets without a network connection.

The generated widget images and in-app screen renders were visually checked, including all 30 occupied PC slots, the party sidebar, individual game stamps and both export screens. A generated JSON fixture was also accepted by the upstream ribbons.guide `loadBackupFile` and `applyLocalBackup` functions in an isolated JavaScript test; no website or account data was modified. Live Simulator interaction is not covered; macOS previously declined screen-capture access. Check these flows on an iPhone:

1. Check the Ribbons and Competitive tabs have separate Pokémon, boxes, parties, teams and widget designs. Open each from a widget link.
2. Search games with **xd**, **gale of darkness**, **oras** and **hgss**. Select one, reopen the selector and clear it with Not set.
3. Drag Pokémon between empty/occupied slots, hold over the box arrows to cross boxes, and reopen the app to check positions. Confirm outlines match the Sun/Moon checkerboard with Party shown and hidden.
4. Switch the Stamp Album to Games; confirm multiple visited games in one generation appear separately.
5. Export a manual competitive Pokémon and a six-member team to Showdown’s Import/Export. Export a Ribbon Master as JSON, optionally append an existing website backup, then restore into a separate test browser profile to inspect it without replacing real website data.
6. Add a Pokémon with **+ → Add Pokémon**, including a form and ribbons in Ribbons, or build details in Competitive. Confirm the selected box receives it, and test a full box. Reopen the app and reimport a backup to confirm the manual entry stays.
7. Set different Sun/Moon wallpapers and custom tints on two boxes; navigate between them and reopen the app.
8. Toggle Party in the box header; move between box slots and the party, then reopen the app.
9. Open a passport, add another game from the origin/current generation, confirm both endpoint labels and all games remain visible, assign an original ribbon to a specific game, and confirm that Memory Ribbon totals stay unchanged.
10. Import a Showdown team, edit a build, reorder members and share the export.
11. Save two widget designs with different selections/appearances. Choose each design on a separate Home Screen widget and edit one to confirm the other stays independent.
12. Check long nicknames/moves, both appearances and text-size settings. iOS controls when widget timelines refresh.

The physical iPhone build also compiles with signing disabled; installation and widget refresh remain device checks.

See UI-UPDATE.md for the implemented screens and Home Screen setup.

---

# Validation and on-device checks

## Checks completed while preparing this archive

The resource-folder repair was also checked on a copy of a configured project, including preservation of Team, bundle identifiers and App Group settings. The build now packages artwork/catalogue under `RibbonAssets`, not a reserved `Resources` directory. A clean build is needed to remove the previous copied directory. This correction has not yet been tested with Apple codesign in this environment.

- Parsed every Swift source file with a Swift grammar parser and checked for syntax errors.
- Validated the Xcode project object graph, target memberships, embedded widget dependency and shared scheme XML.
- Validated Info.plist/entitlement files and consistent default bundle/App Group identifiers.
- Decoded every bundled PNG and checked the catalogue/asset mappings.
- Checked the identifier-configuration script on a separate copy of the project.

These were the original archive’s static/package checks. Native simulator builds and XCTest validation have since been completed for the UI update, as described above.

## Run the native unit tests on your Mac

Open the project, choose the **RibbonPassport** scheme and an iPhone simulator, then press **⌘U**. The scheme includes the **RibbonPassportTests** target.

The test suite covers:

- Showdown nickname/species/gender/shiny/level parsing and multiple members.
- Form names such as Rotom-Wash and Zacian-Crowned, CRLF line endings and team header lines.
- Empty, unrecognised, over-six-member and invalid-level imports.
- Gen 3–5 legacy awards versus Gen 6+ Memory Ribbons, gold thresholds, combined mark counts and retained National/Earth ribbons.
- ribbons.guide backup version validation, award deduplication and XD-origin Shadow Lugia.

## Before relying on the app

1. Run the demo; verify all six sprites and the small/medium/large single layouts.
2. Add medium/large team widgets and confirm three/six members, in the chosen order, with unnumbered top-three ribbon icons.
3. Toggle light/dark modes and test a long nickname and a long title. Check console icons stay separate from text and widget corners are handled by iOS.
4. Import a real backup and confirm its origin games, equipped titles and award totals.
5. Paste a shiny Showdown team; confirm its build details are retained, its ribbons start empty and adding awards updates its widget.
6. Reimport the backup; confirm the Showdown team remains and the website Pokémon update without duplication.
7. Terminate/reopen the app and verify the saved data and selections persist. Turn off networking after sprites are loaded and check cached widgets.

iOS decides when timelines refresh. After editing, the app requests a refresh; it cannot force an immediate Home Screen update. Settings → Refresh widgets requests another refresh.

## Version 0.2 changes and focused checks

- Added a separate Showdown Team widget with its own App Intent/entity query. Existing team records are classified from their saved Showdown builds; no collection schema migration is required.
- Deletion uses Pokémon IDs, including with a filtered search, and prunes saved team memberships, empty teams and invalid defaults.
- Refreshing demos replaces old demo records while keeping imported Pokémon and stable IDs for retained demo species.
- Demo award generations, origin-dependent awards, memory thresholds, title membership and offline sprite coverage were checked against the bundled catalogue and the upstream ribbons.guide award data.
- Both DS variants have matching alpha masks and transparent backgrounds; inspected alongside the other console icons at widget sizes.
- The update script was checked on a configured copy: Team, bundle IDs, App Groups, original Info.plist files and entitlements are preserved. A second run makes no changes.

Added native tests cover separate ribbon/Showdown team selection, decoding an existing-format snapshot, deletion including the last member, demo refresh preservation/idempotence, and demo feature coverage. These cases are included in the native suite described above.

On iPhone, add both medium and large Showdown Team widgets using an imported six-member export. Verify held items, abilities, Tera types, levels, natures and moves; check long names/items in both themes. Swipe-delete from a search result and check that the correct Pokémon disappears from every team. Reopen the app to check persistence. Refresh the old demo team twice and confirm there are six demo Pokémon and one demo ribbon team each time.

## Version 0.3 checks

Held-item icons and primary-colour text now share one label in Showdown widgets and app details. Single and team ribbon titles use an equipped-award label that resolves Memory Ribbon variants before choosing the icon and colour. The colour catalogue was checked for valid hex values, icon coverage and readable contrast in both themes. Missing or custom items retain a neutral fallback. Verify on iPhone with Leftovers, Light Ball, Choice Scarf, a gold Memory title and a Rare Mark title. This update passed Swift grammar, resource, ZIP and signing-preservation checks; native SDK builds now pass for the UI update.
