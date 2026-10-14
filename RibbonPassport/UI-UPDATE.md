# UI update

Open the existing `RibbonPassport.xcodeproj` and build the **RibbonPassport** scheme. The app's Team, bundle identifiers, App Group and entitlements are unchanged. Keep the existing iPhone app installed to retain its collection.

## Pokémon

- Add a Pokémon using **+ → Add Pokémon**. Search species/forms by name or Pokédex number, then enter nickname, level, gender, shiny status, origin/current games, ribbons and a title. An optional competitive build includes moves, item, ability, nature, EVs, IVs and Tera type. Entries save directly into the open box; full boxes overflow into available storage. Manual entries survive backup reimports.
- **Wallpaper** beneath the box opens six bundled starter backgrounds: PC Grid, Meadow, Woodland, Seaside, Desert and Starfield. Each box saves its own design, tint and pattern strength; boxes initially cycle through the starter set.
- Game menus follow generation/game chronology, ribbons and marks follow their introduction generation, and Pokémon selectors use National Pokédex order. Older contest ribbons identify their generation to distinguish matching names.
- Classic 30-slot PC boxes, renamed by tapping the box heading. Use **+ → New box** for more storage.
- The **Party** button in the box heading shows or hides the six-slot party. Add a selected Pokémon to the party, or drag it to the sidebar. Returning a party member to storage preserves its record.
- Select **Move**, then a destination slot, or drag between slots. Occupied destinations swap their contents.
- **Passport** opens the Stamp Album. **Edit visits** records games visited; **Assign / move a ribbon** records where an original award was earned. Missing visit history is not guessed. Unchanged demo records receive the authored demo history automatically; imported and edited records do not. Origin and Current stay visible above the album. A generation stamp shows its game count, and selecting it lists every recorded game in that generation, including both endpoints. Adding another visit never replaces either endpoint.
- Memory Ribbons remain a display of the underlying legacy awards. Their original awards can be assigned to earlier generations independently.

## Teams

The Showdown section includes the team library, team overview, individual build details, import, display-order editor and widget preview. Build edits preserve the Pokémon's identity and collection data. Teams can be shared as Showdown text. The ribbon-team tab remains available.

## Widgets

The **Widgets** tab previews all seven supported Home Screen layouts:

- Pokémon Passport: small, medium, large.
- Ribbon Team: medium, large.
- Showdown Team: medium, large.

Five built-in theme packs work with every widget layout: **Pocket Green**, **Ocean Link**, **Contest Album**, **Midnight Circuit** and **Forest Trail**. They are available in Widget Studio and in the Home Screen widget’s Saved design picker, even before a custom design is saved. Widgets without a chosen/default saved design use Pocket Green for Pokémon, Contest Album for ribbon teams and Midnight Circuit for Showdown. Widget gallery previews use the same defaults.

Choose a pack in Studio to customise it, use **Set default** for that widget type, or **Set [pack] as default pack** for all three types. Existing explicitly selected saved designs stay independent. A default change applies to widgets whose Saved design is unset. Background design, tint and strength can be changed or turned off separately.

Save named designs with separate Pokémon/team selections, light/dark/automatic appearance, five palettes, pixel/system fonts, text scaling, ribbon ordering and visibility controls. Each Home Screen widget can select its own **Saved design**. Editing a saved design updates the widgets using it; **Set default** configures widgets without an explicit design.

**Add to Home Screen** saves the design and shows the remaining system steps. Apple does not expose an API that places a Home Screen widget directly from an app. Hold an empty Home Screen area → **Edit → Add Widget → Ribbon Passport**, select the widget and size, then choose the saved design in **Edit Widget**.

The pixel font and demo artwork are bundled for offline use. Existing collection files are decoded without requiring a migration or a reset. Backup reimports preserve matched Pokémon's visit/ribbon metadata, PC positions and Showdown teams.

## Validation

Xcode simulator builds and the native test suite cover old-format decoding, storage capacity and swaps, party membership, per-generation ribbon assignment, independent widget presets, Showdown export/import and font/resource loading. Tests also render all seven widgets in light and dark. Real-device signing, Home Screen placement and iOS timeline refresh still depend on the user's iPhone and provisioning.
