# Sources and credits

Ribbon Passport is an unofficial Pokémon fan app. It is not affiliated with Pokémon, Niantic, Pokémon Showdown or ribbons.guide.

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

Pixelify Sans by Stefie Justprince is bundled for offline use in the app and widgets. Source: [Google Fonts](https://github.com/google/fonts/tree/main/ofl/pixelifysans). Licensed under the SIL Open Font License 1.1; see `Licences/PixelifySans-OFL.txt`.

- Widget theme pack scenery: original code-drawn pixel backgrounds included under the project’s GPL-3.0 licence.
- The 16 standard Sun/Moon PC wallpapers: original game artwork extracted by Tiddlywinks and hosted by [Bulbagarden Archives](https://archives.bulbagarden.net/wiki/Category:Sun_and_Moon_Box_wallpapers). The original 208 × 192 PNGs are bundled unchanged in `RibbonAssets/Wallpapers`; the app displays their interior grid area below its own box heading. Individual source URLs are recorded in `RibbonAssets/Wallpapers/sources.json`. Pokémon artwork remains © Nintendo/Creatures Inc./Game Freak and is not covered by the application code’s GPL licence.

- Export format references: [ribbons.guide backup creation/restoration](https://github.com/SlyAceZeta/Ribbons.Guide/blob/main/js/main.js) and [Pokémon Showdown team import/export](https://github.com/smogon/pokemon-showdown/blob/master/sim/teams.ts). `RibbonAssets/export-compatibility.json` contains supported destination IDs and capture-field labels derived from the upstream ribbons.guide catalogue; its GPL licence is credited above.
