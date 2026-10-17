# First-time-user usability walkthrough

Date: 17 October 2026

Implementation follow-up: the first three agreed usability passes are now implemented. This report preserves the original walkthrough findings; current changes and validation limits are recorded in [UI-UPDATE.md](../../UI-UPDATE.md) and [TESTING.md](../../TESTING.md). Final simulator/visual review was stopped at the user's request; subsequent verification used text review and iPhone compilation only.

## Overall assessment

The app is easier to use once a feature has been found than it is to discover that feature. The PC artwork, Pokémon sprites, separate Ribbons/Competitive sections and compact passport give it a strong identity. The next useful development step is a focused navigation and editing pass before introducing more destinations.

This was an agent-led first-user walkthrough, not a study with independent human participants. Easy/moderate/difficult below are qualitative judgments based on the observed screens, labels and interactions; they are not measured usability scores.

## Test setup and limits

- Built the current source in a temporary copy and used an unused iPhone 17e simulator running iOS 27.0.
- Started with an empty collection, then used demo Pokémon, the built-in Showdown example and a personal copy of a community team. No existing user collection was used.
- The unsigned build initially could not access its App Group. Only the temporary copy's storage root was redirected to a simulator-local folder. The original app source was not changed. Production App Group storage and widget sharing were therefore outside this test.
- Operated the app through its visible interface and accessibility controls. Some simulator controls did not support coordinate input, some navigation toolbar buttons were absent from the automation tree, and Photos/Files sheets did not expose usable controls. These limitations are not proof of product defects.
- Inspected light and dark screens. Physical touch, VoiceOver, large text, the smallest supported phones, actual Home Screen widget placement and iOS widget refresh were not validated.
- Source inspection was used to clarify behaviour and identify remaining coverage, not presented as successful end-to-end interaction.

## Feature coverage

| Feature | Finding it | Using it | Evidence and coverage |
| --- | --- | --- | --- |
| First launch | Moderate | Moderate | Empty state shows No Pokémon and Add Pokémon. Import and demo are inside an icon-only Options menu. |
| Demo collection | Difficult initially | Easy after discovery | Loaded six Pokémon via Refresh demo; collection displayed correctly. The label assumes an existing demo. |
| Manual Pokémon creation | Easy | Partially assessed | Opened the form and species/form picker. Species search prompt is useful. Final creation was not completed; the toolbar confirmation was unavailable to the automation controls. |
| Pokémon editing/capture details/title | Difficult entry point | Not fully tested | Inspected add form and source. The collection's pencil opens Pokémon actions, which contains no Edit action. Passport editing, marks and equipped-title saving still need a complete interaction pass. |
| Select Pokémon/open passport | Easy | Easy | Selected sprites and opened passports. Selection details and explicit Passport link work well. |
| Box overview/rename | Moderate | Mostly easy | Opened All boxes; renamed Box 01 to My Ribbon Team and verified the name behind the dialog and in storage. Dialog dismissal needs an accessibility retest. |
| Party membership | Moderate | Easy after discovery | Added Sparky to the party; the party became visible and the box count decreased. |
| Moving between slots/boxes | Moderate | Not retested | Located Move in Pokémon actions. Drag/drop and its cross-box behaviour were not exercised because coordinate input was unavailable. |
| Box wallpaper/new boxes | Moderate | Not fully tested | Located the entry points; reviewed implementation. Wallpaper saving and multi-box creation were not completed in this walkthrough. |
| Ribbon ownership | Easy | Mostly easy | Added Tower Master Ribbon, observed Added and owned-count feedback, then used Undo successfully. Tile/details distinction and duplicated All labels need clarification. |
| Owned awards/Memory Ribbons | Easy | Partially assessed | Observed owned totals and existing display. Expanded Memory Ribbon/owned-gallery behaviour was not fully retested. |
| Transfer checklist | Easy | Easy, with one confusing state | Opened Rayquaza's Gen VI review; recorded Training, chose X for Kalos Champion, and saw last-chance status update while Footprint eligibility remained unresolved. |
| Journey album/visits | Moderate | Mostly easy | Browsed a multi-generation album; opened Edit visits, added Sapphire, and successfully undid the visit. Exact earning-game reassignment was not fully exercised. |
| Honorary achievements | Moderate | Easy after discovery | Opened Honors, created a custom milestone and verified it appeared. Screenshot attachment and the full preset-honor catalogue were not completed. |
| Journal/memories | Moderate | Easy for basic entries | Created First adventure and reopened it. Opened and cancelled Photos selection. Full photo attachment and longer keyboard-driven story editing remain unverified. |
| HOME Move Dex notes | Difficult initially | Easy | Found inside Notes → Move Dex; saved Thunderbolt with Checked in HOME and verified the list entry. |
| Field guides | Moderate | Easy | Opened award details → Field guide → Galar Battle Tower, read steps and opened sources. A separate guide-library screen adds an extra step even when one guide matches. |
| Source cards/correction notes | Moderate | Partially assessed | Viewed author/link/review information and entered a test correction note. Did not complete note saving; keyboard obscured the lower action and automated scrolling was unavailable there. |
| Sources & credits | Easy from Settings | Easy | Found after scrolling Settings; searched Peterko and verified filtering. External destinations/licence text were not exhaustively opened. |
| Showdown import | Difficult entry point | Easy once open | Used Example and imported a six-member team; app opened the resulting team. Arbitrary pasted team text was not separately tested. |
| Competitive build display | Easy after import | Easy to read | Opened an individual build and inspected held item, ability, nature, Tera type, moves and stats. Current-build editing was not completed. |
| Team creation/member arrangement | Moderate | Not fully tested | Imported teams and copied community teams successfully. Manual member selection/reordering/saving needs a further pass. |
| Community team library | Difficult entry point | Mostly easy | Searched Peterko, read strategy/source context and saved a personal copy; verified nine competitive Pokémon afterwards. |
| Build notebooks | Moderate | Easy for versions | Saved First team, observed Version saved and the difference count, exported that version, and observed Copied. Individual version editing/apply and team restoration were not fully retested. |
| Showdown export | Moderate | Easy | Opened a saved team's export and copied the text with confirmation. File saving and external sharing were not completed. |
| ribbons.guide import/export | Difficult to distinguish from app backup | Not fully tested | Located Import backup. Successful website backup import/export and compatibility prompts were not exercised in this walkthrough. |
| Complete app backup | Easy from Settings | Clear screen; partial flow | Opened Save app backup and observed the Files export dialog. Did not complete file save or restore. |
| Recovery history | Easy from Settings | Moderate | Opened Pokémon history, previewed an earlier version, scrolled to the comparison and restored it. Saw Restored and a Before restore version. Deleted-item recovery was not separately repeated. |
| Widget studio | Moderate entry point | Moderate/difficult first setup | Previewed Showdown Team, changed to Ocean Link, saved the design, observed Design saved and opened Add to Home Screen instructions. Shared widget storage and actual placement were outside the isolated setup. |
| Appearance | Easy | Easy | Changed the test app to Dark and visually inspected ribbons, transfer and rarity screens. |
| Rarity guide | Moderate | Easy to read, harder to scan at scale | Opened Estimated rarity. It is a long list with a different visual treatment and no search in the inspected interface. |

## Priorities for the next UI pass

### 1. Make the empty states useful

Both collection sections start with No Pokémon and Add Pokémon. A new user has no visible introduction to imports, sample data or community teams.

For Ribbons, offer Add Pokémon, Import ribbons.guide backup and Try demo. For Competitive, offer Import Showdown team and Browse community teams alongside manual addition. Keep this help in the empty state so the populated PC stays uncluttered. Rename Refresh demo to Try demo before demo records exist.

### 2. Match action labels and icons to their purpose

The pencil beside a selected Pokémon opens a menu containing Open passport, Move, Add to party, Export Pokémon and Delete, without Edit. Add Edit Pokémon or replace the pencil with a more-actions symbol.

Use Import ribbons.guide backup instead of Import backup to distinguish it from Settings → App backup. Make the Options affordance easier to recognise with a short label or a familiar overflow symbol.

### 3. Clarify ribbon controls

The small All control means all games; the All category means all categories of unearned ribbons. Label the first All games. Make recording ownership distinct from opening award details; the current tile records an award and its small i opens details.

Use wording such as 17 matches · page 1 of 2 rather than 17 shown while only 12 tiles are visible. Consider Browse game instead of Change, since the selector enters a planning view rather than changing the Pokémon's recorded current game.

In the transfer checklist, Generation complete appeared alongside Footprint eligibility needs checking. Prefer Recorded requirements complete or keep the unresolved requirement in the main status. Give Set met level a direct route to the relevant field.

### 4. Shorten the widget setup path

The first screen includes theme packs, section defaults, size, appearance, a large preview and many styling controls before Save design/Set default/Add to Home Screen. These are reasonable capabilities but too much sequencing for a first widget.

Lead with choose Pokémon/team → choose size/theme → save and see installation steps. Put palette/tint/font/visibility controls in an optional Customise section. Explain section default versus one widget's saved design near the relevant action. Keep the existing four installation steps: they are clear and specific to the chosen design.

### 5. Improve recovery previews

Version rows are all Before edit with timestamps. The preview presents many unchanged fields before the comparison and Restore. Put What will change first, with saved details expandable below it. Give history entries short change summaries where possible. Retain the current reassurance that replaced details remain recoverable.

### 6. Make the Journey terminology easier to learn

Journey → Notes contains both memories and Move Dex. Journey → Honors opens optional achievements. Keep these contextual locations, but use more descriptive labels or brief subtitles rather than adding another main tab.

The album has separate generation, game and award navigation. Make each pagination control's scope explicit. Where generation-level earning data exists but the exact game is unknown, avoid a plain 0 awards label that can be mistaken for lost ownership; use 0 assigned to this game or an unassigned indicator.

### 7. Improve library scanning and long forms

Show supported games on each community team card as well as facility/format. Keep the useful author search, compact strategy and attribution. Make Save personal copy easier to reach without scrolling through the entire roster.

Add direct numeric entry for levels; the inspected level control only offers one-level minus/plus changes. Use a date picker or structured optional date entry instead of requiring YYYY-MM-DD. Give unlabeled note areas a visible purpose and provide a reliable keyboard dismissal/save path.

### 8. Bring visual consistency to secondary screens

The PC/passport/community screens use full pixel panels; Settings and creation forms mix standard rounded iPhone forms with pixel controls, and rarity uses a largely system-font list. Standardise spacing, headings and action placement while retaining readable text. Destructive actions such as Remove should also look distinct from Apply/Notes/Export.

## Accessibility and simulator observations requiring confirmation

- Activating some Options actions through the accessibility controls performed the action while leaving Options open. Import Showdown team appeared after explicitly closing Options. Renaming updated the box behind the dialog, but Save left the dialog open. The implementation intends to close these surfaces through custom button styles. Retest using both physical taps and VoiceOver; do not assume this affects every touch interaction.
- Some visible navigation toolbar buttons were missing from the simulator's automation tree, although equivalent Back buttons on community screens were available. Verify accessibility navigation on a device before classifying this as an app defect.
- The Photos picker opened and could be cancelled, but image selection was not completed. Files export also opened; file save/restore was not completed. The tools could not operate those system surfaces reliably.
- Longer keyboard-driven editors, larger text sizes, contrast measurements and reduced motion remain checks to perform. No full accessibility pass is claimed.

## Suggested implementation scope

First make only the empty-state improvements, action/icon corrections and ribbon-label changes. Review those screens again, then streamline widget setup and recovery previews. Add collection search/filtering after these entry points are clearer. No full redesign or extra main navigation destination is needed for this first pass.

## Saved visual evidence

- [Collection](collection.png)
- [Pokémon actions](pokemon-actions.png)
- [Community team library](team-library.png)
- [Widget studio](widget-studio.png)
- [Widget installation instructions](widget-setup.png)
- [Rarity guide in dark mode](rarity-dark.png)
- [Ribbon controls in dark mode](ribbons-dark.png)
- [Transfer eligibility warning](transfer-check.png)

Screenshots are from the isolated simulator test collection. They are evidence for this review, not proposed redesigns.
