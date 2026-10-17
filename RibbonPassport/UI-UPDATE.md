# Community guides, notebooks and credits — 17 October 2026

Implemented storyboard screens 2–8 using the app’s pixel controls and existing Ribbons/Competitive separation.

- **Field guides:** open an award’s details → Field guide, or Passport → Journey → Guides. The bundled catalogue has 25 short guide groups, game-specific locations/requirements, notes, relevant teams and source cards. Official ribbon descriptions remain separate. Event/catch-only awards do not get invented earning tasks.
- **Community teams:** Competitive → Options → Team library (also available from Teams). Ten sourced teams/lead methods include exact published builds, author names, original links, results and separate Ribbon Master slot notes. Save a personal copy before editing. Published streaks are not promises for arbitrary replacement Pokémon, and rental codes are not represented as live-checked.
- **Build notebook:** open a competitive Pokémon or team → Build notebook. Save named versions and notes, inspect differences, apply saved builds and export a version through Showdown. Personal changes retain original credits. Applying a build preserves passport/journal details; missing competitive team members can be recreated from the saved version.
- **Honors:** Passport → Journey → Honors, or Passport Options → Honorary achievements. Nine starter definitions and custom milestones support game, optional historic date, earned state, note and local screenshot. Trainer/save accomplishments carry an explicit manual-milestone label. Honors never affect ribbon/mark totals or transfer readiness.
- **Journey notes:** Passport → Journey → Notes. Add/edit/remove memories and screenshots; Move Dex records are manual move/game notes with a separately checked HOME status. They do not infer registration or move legality.
- **Credits:** Settings → Credits → Sources & credits. Search 57 references/credits by author or website, open original source links, read bundled licence notices and save a local correction note. Guides and teams also link directly to their own credits. Nothing is posted or sent to an author.
- **Local backup:** Settings → Collection → App backup saves/restores complete app records, including screenshots, notebooks and recovery history. The restore preview asks before replacing the collection and retains recovery versions. Matched ribbons.guide imports preserve the new local passport metadata; website and Showdown exports omit unsupported app fields.

Screenshots are resized locally before saving. Source links need an internet connection; bundled summaries, builds, notices and user records are available offline. Uncertain figures remain omitted or qualified rather than presented as verified instructions. Device signing settings are preserved.

---

# UI update

## Memory Ribbon consolidation

The PC ribbon strip, passport Overview, ribbon totals and Owned drawer now use the same current-game consolidation as widgets: from Gen VI onward, old contest and Battle Tower awards appear as Contest/Battle Memory Ribbons with the appropriate normal/gold icon. Original awards and earning-game/generation records remain intact. Expand a Memory Ribbon in Owned to edit its contributing original ribbons; removal and Undo recalculate the displayed result. The historical catalogue and Journey album continue to show individual original awards. Imported Memory-only records also remain supported.

## PC terminal and passport tabs

The home screen uses a single PC terminal panel: the complete Sun/Moon wallpaper and its original header, the optional party rail, a compact selected Pokémon strip, a small ribbon shortcut and box tabs. **Party** stays in the wallpaper header. **All boxes** opens a box chooser; **Box options → Wallpaper** opens all 16 original Sun/Moon backgrounds with a separate saved choice and optional tint for each box. Teams, Widgets, imports and Add Pokémon are in the collection’s **…** menu; Move, party placement, export and deletion are in the selected Pokémon’s **…** menu. Existing finger tracking, swaps and box-arrow hover remain available.

**Passport** now has **Overview / Ribbons / Journey** tabs. Overview shows the Pokémon, origin/current games, owned ribbon preview and transfer check. Tapping an individual ribbon opens a compact bubble pointing to that icon, with its name in a green header and the in-game English description below. Tap another ribbon to switch the bubble, tap the selected icon again or outside it to close, or use the accessibility escape action. The passport stays visible, and viewing descriptions does not change ownership. The Owned ribbons heading opens the Ribbons tab. Ribbons contains the full existing ribbon editor, including game-specific earning locations, Owned, Undo, last-chance warnings and the transfer checklist. Edits in this tab save as they are made, including changes in its drawers, so switching tabs or returning to the PC retains them. Done returns to Overview. The small PC ribbon shortcut opens this same Ribbons tab. Separate Add/Edit Pokémon editors still use Save and keep an unsaved draft. Journey retains the stamp album’s generation/game grouping and editing. Passport options include editing, export and saved versions.


## Local recovery history

Open **Settings → Recovery history** to browse **All**, **Deleted** or **Versions**. Choose a Pokémon or team, choose a saved version, and review its details and the changes before restoring. Edits, deletions and replaced imports are captured automatically when the collection saves. History starts with changes saved after this update; earlier deleted items cannot be recovered retroactively.

Recovery preserves the Pokémon's ID, ribbons/marks, earning locations, journey, equipped title and competitive build. Deleted Pokémon return to their original box/party position and teams where space is available; an occupied slot or full party is preserved and the Pokémon goes into available box storage. Missing original boxes can be recreated. Restoring earlier details of an existing Pokémon keeps its current position. Teams restore available compatible members in their saved order; missing Pokémon can be recovered separately first.

Restoring a version also saves the details it replaces, so another restore can reverse it. History and the changed collection are written together atomically; failed saves leave the live collection unchanged. Selection, PC moves, wallpaper and widget changes do not create Pokémon/team versions. History is kept on the device with up to 20 versions per Pokémon/team and 500 versions total; oldest entries are removed when those limits are reached. Online backup is excluded.

## Ribbon manager

The transfer bar above **Owned ribbons** uses a large **!** beside **Not safe to leave Gen …**, and changes to a green check when the last required ribbon is recorded. **Review** opens the Transfer check drawer. It checks all compatible games in the selected generation, independently of the grid's filters or page. **Earn before leaving** has four ribbons per page; **Can wait** lists compatible later generations. Add directly in the selected game or choose a specific earning game from that generation. Undo updates the warning immediately; Save commits the manager's draft. A different selected generation is labelled **Planning view**.

Footprint is last chance when transfer would make its later level requirement impossible, or when no compatible later game awards it. The drawer explains the Gen IV → V met-level reset for affected Pokémon. The BDSP friendship exception for voiceless Pokémon remains supported. Unknown met levels request an eligibility check, and Pokémon with no compatible later generation do not receive a green transfer status.

Last-chance ribbons use an amber background, a stronger amber outline and an **!** corner marker. The marker also appears in the compact 32-per-page grid; the larger layouts keep the **LAST CHANCE** label. The Last chance filter and detail message share that colour, while owned ribbons retain their green styling.

**Ribbons** opens from the selected Pokémon’s small PC shortcut, the passport’s Ribbons tab, and the Add/Edit Pokémon forms. The pixel interface includes all 106 ribbons, game choices grouped by generation, **Earnable only**, an **All** games switch, and **All / Last chance / Later gens** filters. The small per-page button cycles **12 → 16 → 32 → 12**. Its choice persists between sessions; older unsupported page sizes reset to 12.

Tap an owned ribbon to remove it; **Undo** restores the ribbon, earning game and equipped title. Owned ribbons use a scrolling drawer. Unowned ribbons add immediately in the selected game, or ask for a specific valid earning game when browsing All. An already-owned ribbon cannot be overwritten by adding it from another game. Separate editor sheets use Save; leaving those sheets without saving discards their draft. The embedded passport Ribbons tab saves each edit automatically.

Game eligibility uses the bundled species/form catalogue and directed transfer routes, including Mythical/Legendary challenge exclusions, BDSP Tower restrictions, level requirements, Shadow origins, and the individual games available to that Pokémon. Last chance means there is no compatible later-generation game for that ribbon. Automatic Memory Ribbons and distribution-only awards appear in the full catalogue with their explanation rather than as earnable challenges. Marks retain a separate editor.

New earning locations identify an individual game. The Stamp Album's Games view only shows awards assigned to that game. Older generation-only assignments stay intact as **Gen … · Game not set**; **Set game** in Owned ribbons assigns a compatible recorded game without inventing history. The original ribbon list and calculated Memory Ribbon totals are preserved. Capture details now include an optional met level for Footprint eligibility; that supported field also round-trips through ribbons.guide exports. App-specific earning-game records stay in the app backup.

Open the existing `RibbonPassport.xcodeproj` and build the **RibbonPassport** scheme. The app's Team, bundle identifiers, App Group and entitlements are unchanged. Keep the existing iPhone app installed to retain its collection.

## Sections

**Ribbons** and **Competitive** are separate tabs. Each has its own PC boxes, party, selected Pokémon, teams and widget editor. Existing Pokémon are sorted into the appropriate section by their saved competitive build; collection records are retained. Legacy box names, occupied positions and wallpapers are preserved in the relevant section. Ribbon imports stay in Ribbons, and Showdown imports stay in Competitive.

Use **Teams** or **Widgets** above that section’s PC to access its other screens. Competitive additions include build fields; ribbon additions include awards and titles. The old shared Teams/Widgets tabs and mixed team filter have been removed.

## Pokémon

- Add a Pokémon using **+ → Add Pokémon**. Search species/forms by name or Pokédex number, then enter nickname, level, gender, shiny status, origin/current games, ribbons and a title. In the Competitive section the form includes moves, item, ability, nature, EVs, IVs and Tera type. Entries save directly into the open box; full boxes overflow into available storage. Manual entries survive backup reimports.
- **Wallpaper** beneath the box opens the 16 standard Sun/Moon wallpapers: Forest, City, Desert, Savanna, Crag, Volcano, Snow, Cave, Beach, Seafloor, River, Sky, Pokémon Center, Machine, Checks and Simple. Each box saves its choice and optional custom tint; new boxes cycle through the 16 designs.
- Tap a game selector and type in its search field. Names and abbreviations such as **xd**, **oras** and **hgss** work. Equipped ribbons/titles and Pokémon/team widget selectors also have searchable lists; award and species lists already support search.
- Game menus follow generation/game chronology, ribbons and marks follow their introduction generation, and Pokémon selectors use National Pokédex order. Older contest ribbons identify their generation to distinguish matching names.
- Classic 30-slot PC boxes, renamed by tapping the box heading. Use **+ → New box** for more storage.
- The **Party** button in the box heading shows or hides the six-slot party. Add a selected Pokémon to the party, or drag it to the sidebar. Returning a party member to storage preserves its record.
- The PC uses the wallpaper’s exact six-column, five-row grid, with no gaps between cells. Selection and drop outlines follow the background tile edges, including with the party visible.
- Drag a Pokémon directly to a slot. A small sprite follows the finger with a slight lift, the original sprite fades, and the destination gets a simple outline. Release to settle into place in 0.14 seconds; occupied Pokémon slide back to the source. This uses a local gesture with no system drag badge or drag haptics. An invalid or cancelled drop returns to the source without saving a move. Reduce Motion removes the travel animation.
- To cross boxes, hold the drag over a previous/next arrow for about 0.65 seconds, then continue into a slot in the revealed box. Party slots support reordering and swaps, including with a full party. **Move** followed by a destination remains available. Moves are restricted to the current section. The selected Pokémon's **…** menu contains its other actions, including Return to box for a party member; these actions no longer compete with dragging on a long press.
- **Passport** opens the Stamp Album. **Edit visits** records games visited; **Manage ribbons** records the specific game where an original award was earned. Missing visit history is not guessed. Unchanged demo records receive the authored demo history automatically; imported and edited records do not. Origin and Current stay visible above the album. A generation stamp shows its game count, and selecting it lists every recorded game in that generation, including both endpoints. Adding another visit never replaces either endpoint.
- The Stamp Album has a **Generations / Games** switch and remembers the chosen view. Games displays a separate stamp for every recorded game, including multiple games within one generation, with Origin/Current labels and that game's ribbon assignments.
- Memory Ribbons remain a display of the underlying legacy awards. Their original awards can be assigned to earlier generations independently.

## Teams

The Showdown section includes the team library, team overview, individual build details, import, display-order editor and widget preview. Build edits preserve the Pokémon's identity and collection data. Teams can be shared as Showdown text. The ribbon-team tab remains available.

## Exports

Use **Export** on a passport, competitive build or team; the selected Pokémon’s **…** menu also offers **Export Pokémon**. In Ribbons, **+ → Export Ribbon Masters** exports the whole ribbon collection. The export sheet can switch between the two destinations.

- **Showdown:** copy/share standard Import/Export text or save a `.txt` file. Export one Pokémon or a team of up to six, including Pokémon created in the app without a build. Supported identity/build fields are included; ribbons, game history, capture details and app settings are excluded. EV/IV syntax, nature, Tera type and move count are checked before saving. Format-specific battle legality still belongs to Showdown’s team validator.
- **ribbons.guide:** save a version 5 `RibbonBackup.json` using the website’s supported species, game and ribbon IDs. Original ribbons are retained rather than replacing them with calculated Memory Ribbons. Battle-only forms use the corresponding species supported by ribbons.guide. Native IDs, Showdown builds, visited-game history, generation assignments, PC layout and widget settings are excluded.
- ribbons.guide requires a valid **ball** and **language**. These are retained on new backup imports and can be entered under **Capture details** when creating a Pokémon. If missing at export time, choose values for the missing entries. An equipped Partner Ribbon also needs the original trainer’s name. Missing capture details are never guessed.
- **Append to an existing website backup…** keeps that file’s existing records, box names and website settings, then appends the exported Pokémon. It does not change the original file. Restoring the resulting JSON on ribbons.guide replaces its website collection; use the combined file when retaining existing website records. Repeated appends can create duplicate entries.

## Widgets

The **Widgets** button within each section previews all seven supported Home Screen layouts:

- Pokémon Passport: small, medium, large.
- Ribbon Team: medium, large.
- Showdown Team: medium, large.

Five built-in theme packs work with every widget layout: **Pocket Green**, **Ocean Link**, **Contest Album**, **Midnight Circuit** and **Forest Trail**. They are available in Widget Studio and in the Home Screen widget’s Saved design picker, even before a custom design is saved. Widgets without a chosen/default saved design use Pocket Green for Pokémon, Contest Album for ribbon teams and Midnight Circuit for Showdown. Widget gallery previews use the same defaults.

Choose a pack in Studio to customise it, use **Set default** for that widget type, or **Set [pack] as section default** for the current section’s widget types. Existing explicitly selected saved designs stay independent. A default change applies to widgets whose Saved design is unset. Changing a section’s default does not affect the other section. Background design, tint and strength can be changed or turned off separately.

Save named designs with separate Pokémon/team selections, light/dark/automatic appearance, five palettes, pixel/system fonts, text scaling, ribbon ordering and visibility controls. Each Home Screen widget can select its own **Saved design**. Editing a saved design updates the widgets using it; **Set default** configures widgets without an explicit design.

**Add to Home Screen** saves the design and shows the remaining system steps. Apple does not expose an API that places a Home Screen widget directly from an app. Hold an empty Home Screen area → **Edit → Add Widget → Ribbon Passport**, select the widget and size, then choose the saved design in **Edit Widget**.

The pixel font and demo artwork are bundled for offline use. Existing collection files are decoded without requiring a migration or a reset. Backup reimports preserve matched Pokémon's visit/ribbon metadata, PC positions and Showdown teams.

## Validation

Xcode simulator builds and the native test suite cover old-format decoding, storage capacity and swaps, party membership, per-generation ribbon assignment, independent widget presets, Showdown export/import and font/resource loading. Tests also render all seven widgets in light and dark. Real-device signing, Home Screen placement and iOS timeline refresh still depend on the user's iPhone and provisioning.
