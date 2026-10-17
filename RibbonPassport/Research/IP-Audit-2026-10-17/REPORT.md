# Ribbon Passport: IP and licence audit

Date: 17 October 2026. Scope: current local source tree, app and widget resources, credits and runtime artwork loading. Intended release: free, ad-free iOS companion app. This is a technical provenance and release-risk assessment, not a legal clearance or an Apple decision. No application behaviour, licence declarations or artwork was changed by this audit.

## Finding

The current project has unresolved third-party image permissions and an existing GPL declaration. It is not ready to describe as an MIT-only project. Removing the Poké Ball from the icon alone would not resolve the other assets, downloaded images or upstream-derived data. This does not establish that every use infringes: licences, factual information, copyright exceptions and referential trademark use need separate consideration.

The most economical next step is to settle permission for the Ribbons.Guide-derived material before replacing the eligibility engine. In parallel, replace decorative official artwork with original, independently designed artwork and correct inaccurate credits. Keep the existing project intact while preparing a public release variant.

## Evidence and inventory

The Xcode project includes the whole RibbonAssets folder in both app and widget resource phases. Assets that are unused on a particular screen can therefore still be distributed. Counts below describe files, not distinct copyrighted works; light/dark copies and variants are included.

| Material | Local quantity | Provenance / evidence | Assessment and action |
| --- | ---: | --- | --- |
| App icon | 1 PNG | App/Assets.xcassets/AppIcon.appiconset/AppIcon.png; supplied mockup cropped in this conversation | Contains a recognisable Poké Ball. Permission from original artwork creator and relevant underlying rights is not recorded. Replace with an independently designed ribbon emblem or document permission. |
| Award images | 159 PNGs | RibbonAssets/Art/award-*.png | Ribbon/mark game artwork. Credits identify upstream repositories broadly, but there is no per-file rights manifest for this category. Obtain provenance/permission or use independently designed generic achievement graphics. |
| Item images | 572 PNGs | RibbonAssets/Art/item-*.png; CREDITS.md identifies smogon/sprites and PokeSprite for Stick | Game item art; code repository licences are not blanket Pokémon image licences. Inventory includes fallback/variant names. Replace decorative icons with text or original generic art unless rights established. |
| Game/service images | 132 PNGs | RibbonAssets/Art/game-*.png; catalog.json gameImageSources and gameImageKinds | Includes mascots and service imagery. Manifest lists 38 source entries, not a complete per-file mapping of 132 variants. HOME points to official logo; Bank points to PokeSprite storage artwork. Replace decorative mascots with original neutral emblems; assess necessary text references separately. |
| Bundled Pokémon sprites | 12 PNGs | RibbonAssets/Art/sprite-*.png; includes demo sprites and Shadow Lugia | PokeSprite and other fan repositories do not establish permission from underlying Pokémon owners. Fan-created derivatives can also have contributor rights. |
| Shiny symbol | 2 PNGs | shiny-dark.png and shiny-light.png; catalog.json uiImageSources points to extracted Pokémon GO asset | Replace with original stars/sparkles or an appropriate system symbol. |
| Sun/Moon wallpapers | 16 PNGs | RibbonAssets/Wallpapers/sm-*.png and sources.json; credits explicitly call them unchanged original game artwork | Strong provenance evidence of copied game art, but no redistribution permission established. Existing code-drawn PixelWallpaper alternatives provide a practical replacement. |
| Console/device icons | 12 PNGs | console-*.png; ICOOON MONO, SVG Repo, Pictogrammers and user-supplied GBA | Mixed licences; assess individually rather than removing all. GBA authorship/permission not recorded. Original neutral shapes or system symbols simplify this category. |
| Pixelify Sans | 1 TTF | RibbonAssets/Fonts/PixelifySans.ttf and PixelifySans-OFL.txt | OFL notice is present. Retain notice and comply with font conditions. No specific problem identified from this review; font bytes were not compared to upstream. |

Total: 889 PNGs in Art, 16 wallpaper PNGs and one app icon, plus the font. See inventory.csv for paths, sizes, SHA-256 hashes, categories and evidence-based status. The inventory is a starting manifest, not proof of permission.

## Runtime downloads are part of the review

Shared/SharedStore.swift:141–178 implements SpriteLoader. Shared/PassportViews.swift:66 invokes it. The loader requests PokeSprite images from raw.githubusercontent.com, then PokeAPI for Gen 9, then play.pokemonshowdown.com. Images are trimmed and cached in shared app-group storage for app/widget rendering.

Removing only bundled sprites would still leave these requests. Downloading rather than bundling is not a rights workaround. A public release without established image rights should disable those sources and use neutral placeholders; consider previously cached files and widgets during migration. Requests also disclose ordinary network metadata to the hosting services, relevant to privacy disclosures.

## GPL and a possible MIT migration

Both CREDITS.md and the in-app RibbonAssets/credits.md state that the native application code is GPL-3.0. Licences/GPL-3.0.txt and RibbonAssets/Notices/GPL-3.0.txt exist and match. No root LICENSE/COPYING file was found. The 20 Swift files inspected have no GPL header; that does not override the project-wide declaration or prove independent authorship. The precise GPL-3.0-only versus GPL-3.0-or-later grant is not made explicit in the project declaration.

Four data files record upstream derivation:

| File | Content | Consumers |
| --- | --- | --- |
| catalog.json | 1,549 species/form entries; 159 awards; 66 game entries; 111 titles; rarity, merge and alias metadata | Shared/RibbonCore.swift; species selection, labels, title and merge logic |
| ribbon-rules.json | 1,549 species rules; 159 award rules; 49 game rules; 12 transfer graph entries | Shared/RibbonRules.swift; manager, eligibility and transfer assessments |
| catalog-order.json | 66 ordered games; 159 ordered awards and generation values | Shared/CustomizationPacks.swift CatalogOrder |
| export-compatibility.json | 1,545 guide species; 66 guide games; 159 guide awards; ball/language mappings | Shared/UserCustomization.swift ExportCompatibility; backup/export compatibility |

CREDITS.md expressly says eligibility metadata and routes derive from upstream definitions and eligibility logic. Shared/RibbonRules.swift describes itself as an offline snapshot of ribbons.guide. These are concrete provenance warnings; this audit did not run a line-by-line similarity analysis against pinned upstream commits. Names, facts, game rules, software expression and database selection/arrangement should not be treated as legally identical categories. Bundled data does not automatically make every unrelated Swift file a GPL derivative. Conversely, a Swift rewrite or JSON conversion does not automatically remove upstream rights.

Do not relabel this entire tree MIT. Options:

1. Obtain an explicit licence/exception from all relevant upstream rights holders, specifying exactly which code/data, versions and App Store distribution it covers. A single maintainer may not own all contributions; their grant cannot clear Pokémon artwork.
2. Independently implement affected logic and curate replacement data from suitable sources, documenting research, authorship and permitted reuse. Reformatting the existing snapshot is not independent replacement.
3. Retain GPL and satisfy its distribution requirements, while separately resolving App Store terms. Public source alone should not be assumed to settle all contractual restrictions. Historical FSF App Store enforcement is a warning, not a fresh legal determination about this specific build and today's agreements.

For GPL distribution, establish a corresponding-source delivery method for the exact released version, including build inputs/scripts and required notices. No project source download URL, written source offer or release-source procedure was found in the inspected app/docs. This is a preparation gap, not a finding of past noncompliance: distribution history was not checked. For an MIT release, original code authorship and any third-party copied portions still need verification.

## Text, guides and community builds

All 159 award entries in ribbon-rules.json have nonempty descriptions. CREDITS.md identifies these as in-game wording, and App/RibbonManager.swift:360 and :459 display them. Replacing these with concise original explanations is more practical than carrying copied descriptive prose. Short names and factual mechanics require a different analysis; this audit does not conclude that all labels must be removed.

community-content.json contains 57 source entries, 25 guide modules, 10 team candidates and 9 honor definitions. The app has source pages and author attributions. Credits describe guide prose as original summaries, which is positive. The source records have no licence/permission fields, and no permissions ledger was found. Attribution is not a licence. This review sampled structures and read the credits; it did not compare every summary sentence with all 57 originals. Review copied narrative separately from factual build values, report titles, names and hyperlinks. Preserve author credit and links; where permission is unclear, link to full guides rather than reproduce prose.

## Confirmed notice and provenance problems

1. Both credit files still call the icon a new code-drawn rosette. It is now extracted from the user-supplied mockup and includes a Poké Ball. Correct provenance; do not label it original project artwork.
2. The PokeSprite entry can imply MIT covers sprites. Upstream explicitly reserves sprite copyright to Nintendo/Creatures/GAME FREAK and applies MIT to other material. Clarify this distinction in both credits and the bundled notice context.
3. Pictogrammers.txt is a short overview linking Apache 2.0, not the complete Apache licence. Verify the exact cellphone asset grant, include the full applicable licence and preserve required notices/change statements.
4. ICOOON MONO allows incorporation into apps but restricts redistribution as asset material and use in generators. Standalone image files in a public source archive need separate consideration. Keep it outside blanket MIT/GPL grants or replace it with independently authored art.
5. catalog.json uiImageSources still identifies an SVG Repo DS icon, while credits and ICOOON-MONO.txt identify a replacement. Resolve the stale source mapping and pin source versions for reproducibility.
6. User-supplied GBA and logo provenance lacks a recorded authorship/redistribution grant. User supply by itself is not evidence of underlying ownership.

All seven files under Licences have identical copies under RibbonAssets/Notices. Both credits copies match. App/CommunityScreens.swift:312–337 exposes these bundled notices in the app, and Xcode includes the resources. This is useful infrastructure to retain.

## Other release preparation observations

No advertising/analytics/payment SDK integration or Swift package references were found in the inspected source/project. This supports the stated ad-free intent but is not a dynamic network audit. No PrivacyInfo.xcprivacy or dedicated privacy-policy file was found. UserDefaults use and third-party artwork requests warrant a privacy manifest/disclosure review; absence alone is not a complete finding of noncompliance. App Store Connect privacy answers, support/privacy URLs, account settings, screenshots and a signed archive were not available for inspection. No technical release-readiness claim is made here.

## Prioritised release plan

1. Decide the upstream permission route first: identify exact Ribbons.Guide versions/contributors and request a clear alternative licence or distribution permission. Do not switch existing notices meanwhile.
2. Replace the app icon, official wallpapers, shiny symbol and decorative service/mascot images. Existing code-drawn wallpapers reduce work. Keep old user wallpaper preferences loadable with a neutral fallback.
3. Resolve award/item/sprite rights or use original generic images/text. Disable runtime sprite downloads in that variant and account for cached app/widget images.
4. Replace copied award prose; validate community prose and provenance. Preserve factual functionality where independently supportable.
5. Correct and consolidate notices, establish exact release source delivery/licence scope, and record per-asset source/author/licence/version.
6. Finish privacy and App Store submission preparation, then assess the actual release archive. No claim that a neutral icon or MIT file alone guarantees acceptance.

The collection model, journals, manual records, recovery UI, widget layouts and original visual primitives are candidates to retain. Their authorship has not been certified here. Removing the four data files blindly would break startup or major features; replace them through compatible schemas and verify imports, ordering, eligibility and widgets.

## Primary sources checked

- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/): 2.3.9, 5.2.1, 5.2.2; TestFlight 2.2. Apple requires rights for protected third-party content; a free price does not provide an IP exemption.
- [Pokémon's published IP guidance](https://support.pokemon.com/hc/en-us/articles/360000634094-Can-I-use-Pok%C3%A9mon-images-or-materials): no general permission for fan projects. This policy is not an exhaustive statement of statutory exceptions.
- [Ribbons.Guide](https://github.com/SlyAceZeta/Ribbons.Guide): GPL for original content/code; Pokémon images separately attributed to owners.
- [PokeSprite README](https://github.com/msikma/pokesprite/blob/master/readme.md): image copyright separate from MIT code/other material.
- [PokeAPI sprite licence](https://github.com/PokeAPI/sprites/blob/master/LICENCE.txt): explicitly identifies Pokémon image copyright alongside CC0; no assumption that CC0 clears third-party rights.
- [Smogon sprites](https://github.com/smogon/sprites): upstream source for item art; does not establish clearance from Pokémon owners.
- [Pictogrammers licensing](https://pictogrammers.com/docs/general/license/).
- [ICOOON MONO licensing](https://icooon-mono.com/license/).
- [GNU GPLv3 source-distribution guide](https://www.gnu.org/licenses/quick-guide-gplv3.pdf); complete GPL text reviewed locally in Licences/GPL-3.0.txt.
- [FSF historical App Store enforcement explanation](https://www.fsf.org/blogs/licensing/more-about-the-app-store-gpl-enforcement).

Limitations: no trademark-register clearance, no independent rights-holder correspondence, no exhaustive asset pixel comparison, no pinned-upstream code comparison, no complete community-text similarity analysis, no signed-archive inspection and no App Store review. No external messages were sent.
