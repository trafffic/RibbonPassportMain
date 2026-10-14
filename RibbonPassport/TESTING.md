# Validation and on-device checks

## Checks completed while preparing this archive

The resource-folder repair was also checked on a copy of a configured project, including preservation of Team, bundle identifiers and App Group settings. The build now packages artwork/catalogue under `RibbonAssets`, not a reserved `Resources` directory. A clean build is needed to remove the previous copied directory. This correction has not yet been tested with Apple codesign in this environment.

- Parsed every Swift source file with a Swift grammar parser and checked for syntax errors.
- Validated the Xcode project object graph, target memberships, embedded widget dependency and shared scheme XML.
- Validated Info.plist/entitlement files and consistent default bundle/App Group identifiers.
- Decoded every bundled PNG and checked the catalogue/asset mappings.
- Checked the identifier-configuration script on a separate copy of the project.

These are static/package checks. **An Apple SDK build, simulator run and XCTest execution have not been performed here.** Xcode is not available in the preparation environment.

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

Added native tests cover separate ribbon/Showdown team selection, decoding an existing-format snapshot, deletion including the last member, demo refresh preservation/idempotence, and demo feature coverage. These XCTest cases still need to be run in Xcode (Command + U).

On iPhone, add both medium and large Showdown Team widgets using an imported six-member export. Verify held items, abilities, Tera types, levels, natures and moves; check long names/items in both themes. Swipe-delete from a search result and check that the correct Pokémon disappears from every team. Reopen the app to check persistence. Refresh the old demo team twice and confirm there are six demo Pokémon and one demo ribbon team each time.

## Version 0.3 checks

Held-item icons and primary-colour text now share one label in Showdown widgets and app details. Single and team ribbon titles use an equipped-award label that resolves Memory Ribbon variants before choosing the icon and colour. The colour catalogue was checked for valid hex values, icon coverage and readable contrast in both themes. Missing or custom items retain a neutral fallback. Verify on iPhone with Leftovers, Light Ball, Choice Scarf, a gold Memory title and a Rare Mark title. This update passed Swift grammar, resource, ZIP and signing-preservation checks; an Apple SDK build remains necessary.
