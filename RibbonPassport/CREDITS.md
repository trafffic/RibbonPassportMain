# Sources and credits

Ribbon Passport is an unofficial Pokémon fan app. It is not affiliated with Pokémon, Niantic, Pokémon Showdown or ribbons.guide.

## Field guides, teams and honorary achievements

The offline field guides are original short summaries with links to the source material, reviewed 16 October 2026. They are separate from official in-game ribbon descriptions. Full attribution and individual links are available in **Settings → Sources & credits**, and on each guide/team's Sources page. Published battle records describe their original rosters; they are not independent playtests by Ribbon Passport or a guarantee for replacement Pokémon. No rental code is presented as live-verified.

- [.athis — Athis Ribbon Handbook](https://sites.google.com/view/athis-ribbon-handbook/home): game-specific ribbon routes, contest preparation and the Latios/Metagross/Suicune starting recommendation.
- [Smogon](https://www.smogon.com/): facility guides and original team reports. Maison guide authors NoCheese and Lumari; team creators **Peterko**, **QuentinQuonce**, **GG Unit**, **SilverstarStream**, **bobdat**, **CeroRift** and **Eisenherz** are named on their corresponding team cards. Exact original reports and build links are included in `RibbonAssets/community-content.json`.
- The Alolan Muk Battle Royal lead comes from the [original Reddit write-up](https://www.reddit.com/r/pokemon/comments/5lu7et/alolan_muk_is_a_real_mvp_in_battle_royal/). Its original author's account is deleted; no replacement author is inferred.
- **Giovanni Cischke**: [World Champion team report, published by Victory Road](https://victoryroad.pro/2026/08/27/giovanni-cischke-worlds/). [VR Pastes](https://www.vrpastes.com/VP48GdZh) hosts the corresponding detailed build. [PokéPaste](https://pokepast.es/) hosts several other authors' linked builds. Hosting websites are not credited as the team creators.
- [Serebii](https://www.serebii.net/): game-specific ribbon/mark mechanics and honorary-achievement references, including Shiny Leaves, Pokéathlon, Pokéstar Studios, Trainer Hill, PWT, Subway and Black Tower/White Treehollow.
- [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/List_of_Ribbons_in_the_games): ribbon mechanics cross-checks; [Footprint](https://bulbapedia.bulbagarden.net/wiki/Footprint) documents the BDSP voiceless-species exception.
- [Pokémon Support](https://support.pokemon.com/hc/en-us/articles/6372731346452-Why-did-my-Pok%C3%A9mon-s-moves-change), [Pokémon HOME](https://home.pokemon.com/en-us/move/), [official ranked news](https://sv-news.pokemon.co.jp/en/page/389.html) and [World Championship results](https://www.pokemon.com/uk/play-pokemon/worlds/2025/event-results): official references linked from the relevant source cards.

Manual honors, journals and Move Dex notes are user records. They are not official ribbons, automatically verified achievements or endorsements by these authors/sites. Source review notes remain local; the app does not send correction messages.

- Native application code in this project: GPL-3.0, matching the source catalogue's licence. Full text: Licences/GPL-3.0.txt.
- ribbons.guide species/game/ribbon catalogue and title data: [SlyAceZeta/Ribbons.Guide](https://github.com/SlyAceZeta/Ribbons.Guide), GPL-3.0. Catalogue snapshot: 14 October 2026. Ribbon introduction-generation metadata in `RibbonAssets/catalog-order.json` was checked against the same upstream [ribbon data](https://github.com/SlyAceZeta/Ribbons.Guide/blob/main/data/ribbons.json) on 15 October 2026.
- Pokémon pixel sprites and cover-mascot images: [msikma/PokeSprite](https://github.com/msikma/pokesprite), MIT repository licence in Licences/PokeSprite-MIT.txt. This includes the decorative Shadow Lugia fan sprite used for XD-origin Lugia.
- Gen 9 pixel sprites and fallback source: [PokeAPI/sprites](https://github.com/PokeAPI/sprites), repository CC0 notice in Licences/PokeAPI-CC0.txt. Pokémon imagery remains copyrighted by its respective owners.
- Showdown species/form names: [smogon/pokemon-showdown/data/pokedex.ts](https://github.com/smogon/pokemon-showdown/blob/master/data/pokedex.ts). Showdown static pixel sprites are an additional fallback source. The Showdown repository uses MIT; see Licences/Pokemon-Showdown-MIT.txt.
- Pokémon GO's three-sparkle shiny symbol: [PokeMiners/pogo_assets](https://github.com/PokeMiners/pogo_assets), Images/Filters/ic_shiny_white.png. Artwork copyright remains with the respective game owners; PokeMiners extracted the asset.
- Console silhouettes: SVG Repo CC0 icons for [3DS](https://www.svgrepo.com/svg/342067/nintendo-3ds), [GameCube](https://www.svgrepo.com/svg/87051/gamecube-console-box) and [Switch](https://www.svgrepo.com/svg/404424/console-controller-gamepad-games-gaming-switch). Phone icon: Pictogrammers Material Design Icons; notice in Licences/Pictogrammers.txt.
- GBA silhouette supplied by the user. The dark/light versions use the same alpha shape with different foreground colours.
- HOME uses its official transparent logo; Bank uses the PokeSprite storage icon. Game emblems use pixel-art mascots, including Primal Kyogre for Alpha Sapphire and Primal Groudon for Omega Ruby.
- Application icon: a new, code-drawn rosette for this project.

Rarity scores are editorial estimates reused from the Scriptable widget. They describe restricted availability and acquisition challenge; they are not measured ownership rates or official Pokémon rarity grades.

- Updated DS icon: [ICOOON MONO / TopeconHeroes, icon 12003](https://icooon-mono.com/12003-nintendo-ds%E3%81%A3%E3%81%BD%E3%81%84%E3%82%A2%E3%82%A4%E3%82%B3%E3%83%B3/), recoloured and with slightly thicker shapes for small widget rendering. App incorporation and adaptation are allowed by the [creator’s licence](https://icooon-mono.com/license/); this asset is not covered by the code’s GPL licence. See Licences/ICOOON-MONO.txt.

- Held-item pixel art: [Smogon sprites, src/minisprites/items](https://github.com/smogon/sprites/tree/master/src/minisprites/items), matched to the canonical item IDs in [Pokémon Showdown data/items.ts](https://github.com/smogon/pokemon-showdown/blob/master/data/items.ts). The legacy Stick icon comes from PokeSprite. Item and award label colours are calculated from their artwork and adjusted for light/dark contrast. Pokémon imagery remains copyrighted by its respective owners.

# Pixel font

Ribbon manager eligibility metadata and directed transfer routes are derived from the upstream [ribbon definitions](https://github.com/SlyAceZeta/Ribbons.Guide/blob/main/data/ribbons.json), [species definitions](https://github.com/SlyAceZeta/Ribbons.Guide/blob/main/data/pokemon.json), [games](https://github.com/SlyAceZeta/Ribbons.Guide/blob/main/data/games.json), [transfer groups](https://github.com/SlyAceZeta/Ribbons.Guide/blob/main/data/gamegroups.json) and [eligibility logic](https://github.com/SlyAceZeta/Ribbons.Guide/blob/main/js/main.js). The compact offline snapshot is `RibbonAssets/ribbon-rules.json` (15 October 2026), under the same GPL-3.0 licence.

Pixelify Sans by Stefie Justprince is bundled for offline use in the app and widgets. Source: [Google Fonts](https://github.com/google/fonts/tree/main/ofl/pixelifysans). Licensed under the SIL Open Font License 1.1; see `Licences/PixelifySans-OFL.txt`.

- Widget theme pack scenery: original code-drawn pixel backgrounds included under the project’s GPL-3.0 licence.
- The 16 standard Sun/Moon PC wallpapers: original game artwork extracted by Tiddlywinks and hosted by [Bulbagarden Archives](https://archives.bulbagarden.net/wiki/Category:Sun_and_Moon_Box_wallpapers). The original 208 × 192 PNGs are bundled unchanged in `RibbonAssets/Wallpapers`; the app displays their interior grid area below its own box heading. Individual source URLs are recorded in `RibbonAssets/Wallpapers/sources.json`. Pokémon artwork remains © Nintendo/Creatures Inc./Game Freak and is not covered by the application code’s GPL licence.

- Export format references: [ribbons.guide backup creation/restoration](https://github.com/SlyAceZeta/Ribbons.Guide/blob/main/js/main.js) and [Pokémon Showdown team import/export](https://github.com/smogon/pokemon-showdown/blob/master/sim/teams.ts). `RibbonAssets/export-compatibility.json` contains supported destination IDs and capture-field labels derived from the upstream ribbons.guide catalogue; its GPL licence is credited above.

- Owned-ribbon description bubbles display the English in-game descriptions bundled in `RibbonAssets/ribbon-rules.json`, derived from [ribbons.guide’s multilingual description catalogue](https://github.com/SlyAceZeta/Ribbons.Guide/blob/main/data/ribbons.json). Checked on 15 October 2026 against [Bulbapedia’s game-by-game transcriptions](https://bulbapedia.bulbagarden.net/wiki/List_of_Ribbons_in_the_games); the four normal/gold Memory Ribbon entries include the complete “all of the Ribbons” wording. Legacy ribbons retain their Generation IV/V descriptions; ribbons with later wording retain the catalogue’s modern version. Descriptions are available offline. Original Pokémon game text remains © Nintendo/Creatures Inc./Game Freak.
