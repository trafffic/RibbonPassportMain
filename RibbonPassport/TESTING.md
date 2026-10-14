# Current UI update validation

The app and widget extension build with Xcode 27.0 for the iOS 27.0 simulator. All 22 native tests pass. The native suite covers existing imports and demo refresh, old-format collection decoding, PC box reconciliation/swaps, the six-member party limit, ribbon locations, named widget designs, font loading and Showdown export/import. Widget render attachments cover all seven layouts in light/dark plus narrow layouts at 115% text size.

Run **Command + U** in the RibbonPassport scheme with an iPhone simulator selected. Signing settings in the project are preserved. The bundled pixel font is available in both targets without a network connection.

Live Simulator interaction could not be inspected because macOS declined screen-capture access. The generated widget images were visually checked. Check these flows on an iPhone:

1. Toggle Party in the box header; move between box slots and the party, then reopen the app.
2. Open a passport, add a visited game, assign an original ribbon to a generation, and confirm that Memory Ribbon totals stay unchanged.
3. Import a Showdown team, edit a build, reorder members and share the export.
4. Save two widget designs with different selections/appearances. Choose each design on a separate Home Screen widget and edit one to confirm the other stays independent.
5. Check long nicknames/moves, both appearances and text-size settings. iOS controls when widget timelines refresh.

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
