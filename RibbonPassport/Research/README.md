# Ribbon guides and community teams — research draft

Reviewed 16 October 2026. This folder contains the working research for storyboard screens 2–8. The implemented app uses an edited offline catalogue in `RibbonAssets/community-content.json`; exact figures still marked pending here are not presented as verified instructions. App screens and attribution were implemented on 17 October 2026.

The user confirmed all ribbon games including Switch, a small curated team library, offline summaries with source links, and manual Pokémon milestones for trainer/save-wide accomplishments. Those milestones remain separate from actual ribbons, marks and Ribbon Master completion.

## What is saved

`content-research.json` contains 46 source records, 25 guide modules, 10 team/lead candidates with published builds and attribution, screen content contracts, unresolved checks, and a coverage map against the existing rules snapshot dated 15 October 2026.

The map accounts for all **159 award entries** in that snapshot. **97** have game locations, producing **423 award/game pairs across 30 game IDs**. Four of those entries are Memory Ribbon variants, which need a consolidation explanation rather than a new earning task. The other 62 entries have no post-capture earning task in the current rules; that includes catch-only marks and distribution awards. This is coverage of the existing catalog, not independent proof that every catalog rule is correct or every game-specific guide is finished.

Each earning pair maps exactly once to a draft module. Switch FireRed/LeafGreen and XD NSO are explicitly flagged for release-specific checks. Game IDs without ribbon earning tasks, such as the Gen V games, should still support journey entries and optional honors without inventing new ribbons.

## Field guide contents

| Area | Draft coverage | Main sources |
| --- | --- | --- |
| Orre | Purification, Mt. Battle, unchanged-party requirement | [Athis — Orre](https://sites.google.com/view/athis-ribbon-handbook/orre) |
| GBA Hoenn | 20 contests, Artist, Level 50/Open Level Tower, preparation | [Athis — Hoenn](https://sites.google.com/view/athis-ribbon-handbook/hoenn), [Serebii — RSE ribbons](https://www.serebii.net/rubysapphire/ribbons.shtml) |
| DS Sinnoh/Johto | 20 Super Contests, all six Tower ribbons, NPC/human Multi distinction, Red | [Athis — Sinnoh](https://sites.google.com/view/athis-ribbon-handbook/sinnoh), [Johto](https://sites.google.com/view/athis-ribbon-handbook/johto-remake) |
| XY/ORAS | Maison, Super Training, affection, Contest Spectaculars and Contest Star | [Maison guide](https://www.smogon.com/ingame/bc/maison_part1), [Athis — Kalos](https://sites.google.com/view/athis-ribbon-handbook/kalos), [Hoenn remakes](https://sites.google.com/view/athis-ribbon-handbook/hoenn-remake) |
| Alola | Normal/Super Tree, SM/USUM restrictions, Battle Royal | [Athis — Alola](https://sites.google.com/view/athis-ribbon-handbook/alola) |
| Sword/Shield | Leon at Master Ball tier, champion and ranked routes | [Athis — Galar](https://sites.google.com/view/athis-ribbon-handbook/galar), [Serebii — ribbons](https://www.serebii.net/swordshield/ribbons.shtml) |
| BDSP | Master Class Tower, Super Contest Shows, Twinkling Star, Footprint exception | [Athis — Sinnoh remakes](https://sites.google.com/view/athis-ribbon-handbook/sinnoh-remake), [Serebii — ribbons](https://www.serebii.net/brilliantdiamondshiningpearl/ribbons.shtml) |
| Legends: Arceus | Hisui photo preparation and later ribbon display | [Athis — Hisui](https://sites.google.com/view/athis-ribbon-handbook/hisui) |
| Scarlet/Violet | Champion, post-capture marks, optional size marks and current ranked reference | [Athis — Paldea](https://sites.google.com/view/athis-ribbon-handbook/paldea), [Serebii — marks](https://www.serebii.net/scarletviolet/marks.shtml), [official Season 41 announcement](https://sv-news.pokemon.co.jp/en/page/389.html) |
| Shared | Weekday/purchase/effort/friendship/Footprint locations, league requirements, Memory explanation | Version-specific source IDs in the JSON |

The implementation should resolve a guide using **award + exact game**, then the Pokémon's eligibility. A generation alone is insufficient. Source prose and official in-game descriptions are separate fields. A guide has short Requirements, Prepare, Steps and Before you transfer sections; team and source links are contextual.

## Team shortlist

These are source-read candidates, not teams tested by this project. A leaderboard result applies to its published roster and format. It does not establish that any Pokémon can replace a member and retain the result.

| Game/facility | Candidate | Attribution and evidence | Ribbon Master slot |
| --- | --- | --- | --- |
| RSE Tower Singles | Latios / Metagross / Suicune | [.athis starting guide](https://sites.google.com/view/athis-ribbon-handbook/home/starting-tips); recommendation, no streak claimed | Role-based replacement suggested by guide; species-specific result unknown |
| Pt/HGSS Tower Singles | Latias / Registeel / Garchomp | Peterko; 2,363 listed wins; [build](https://pokepast.es/8a8009bc65c7dda5), [record index](https://www.smogon.com/forums/threads/4th-generation-battle-facilities-discussion-and-records.3663294/) | No free replacement slot established |
| HGSS Tower NPC Multi | Staraptor / Tauros | QuentinQuonce; 83 in SoulSilver; [original detailed report](https://www.smogon.com/forums/threads/4th-generation-battle-facilities-discussion-and-records.3663294/page-10#post-9781591) | Both owned slots have roles; replacement unproven |
| Maison Super Singles | Durant / Cloyster / Drapion | GG Unit; 971 historical listed wins; [record article and builds](https://www.smogon.com/articles/maison-leaderboard) | A specific three-member setup strategy |
| Tree Super Singles | Garchomp / Mega Scizor / Tapu Fini | SilverstarStream; 1,064; [report](https://www.smogon.com/forums/posts/9292567), [build](https://pokepast.es/2b517015d0cc1f27) | Needs a separate final-battle adaptation |
| Battle Royal | Alolan Muk lead | Deleted original Reddit author; [complete lead build and method](https://www.reddit.com/r/pokemon/comments/5lu7et/alolan_muk_is_a_real_mvp_in_battle_royal/) | One complete lead only; two support slots unspecified |
| Sword/Shield Tower Singles | Zamazenta / Eternatus / G-Max Charizard | bobdat; 100 unbeaten at publication; [original post](https://www.smogon.com/forums/threads/swsh-battle-facilities-discussion-records.3656190/page-5#post-8362857) | Replacing Charizard is an adaptation, not the published result |
| BDSP Master Singles | Rotom-Wash / Scizor / Garchomp | CeroRift; 1,050 listed wins; [build](https://pokepast.es/e9454c49f6e5edf4), [index](https://www.smogon.com/forums/threads/bdsp-battle-tower-discussion-records.3693739/) | Replacement not established |
| BDSP Master Doubles | Pelipper / Kingdra / Raikou / Scizor | Eisenherz; 1,045 listed wins; [build](https://pokepast.es/bf0032eb959ac699), [report](https://www.smogon.com/forums/posts/9051821) | Community Scizor-replacement reports need separate attribution/review |
| SV ranked Doubles | Koraidon / Lunala team | Giovanni Cischke; [World Champion report](https://victoryroad.pro/2026/08/27/giovanni-cischke-worlds/), [exact builds](https://www.vrpastes.com/VP48GdZh) | Competitive reference, not an arbitrary-RM carry team |

All sets retain source EVs and move order, including valid 510-EV spreads that do not divide neatly by four. Unknown levels/IVs are not filled with assumptions. No rental code is advertised as live. High records and easy ribbon-carry advice should have distinct evidence labels in the library.

The original Gen IV Multi post was opened in the browser to read its collapsed builds; the Staraptor uses **Choice Scarf**, not the Choice Band used by a different later contributor. The Sword/Shield post was similarly expanded to read bobdat's actual team. The SV paste's extended view was used for natures, IVs and EVs.

## Findings that affect behavior

- Gen III Winning must be earned before leveling past 50; the Pokémon needs to enter the awarding seven-battle set. Maison team changes work differently.
- Tree normal rules differ between SM and USUM. A restricted Pokémon allowed in USUM normal is not thereby eligible for Super Tree.
- Footprint has friendship, 30-level and BDSP species-exception branches. The draft includes the 42-species voiceless exception list and the NPC location per game. Later game access alone is not enough to call it obtainable. [Footprint reference](https://bulbapedia.bulbagarden.net/wiki/Footprint)
- BDSP Twinkling Star requires **Master Rank** Brilliant/Shining. A short guide that omits the rank can mislead the player.
- World Ability needs a historical/unofficial-service explanation because the official Wi-Fi service ended.
- Preparing a Pokémon at Hisui's photography studio is sufficient; taking a photo is not required.
- Post-capture marks belong in available awards; size marks remain optional. Conflicting Gourmand odds are left out of draft numerical instructions.
- Once-in-a-Lifetime has a described intended method but no verified granting logic according to the reference review; do not create a required earning task. [Reference](https://bulbapedia.bulbagarden.net/wiki/List_of_Ribbons_in_the_games)
- SV's official Season 41 announcement specifies Regulation I from 1 April 2026 until service ends. Offline ranked advice needs a checked date. A tournament result does not prove an arbitrary RM replacement is suitable. [Official announcement](https://sv-news.pokemon.co.jp/en/page/389.html)
- HOME keeps movesets for linked games and can replace a set with legal moves on entry. The initial Move Dex screen therefore records manual observations and checked status, not inferred registration. [Pokémon Support](https://support.pokemon.com/hc/en-us/articles/6372731346452-Why-did-my-Pok%C3%A9mon-s-moves-change)

## Content still requiring review

Before publishing the full catalogue, finish the pending fields recorded in each module: Artist score definition, numerical friendship/affection requirements and final NPC checks, transferred Footprint baselines, Memory appearance bugs by software version, precise post-capture mark counters, and release-specific Switch ports. Check full BDSP Master Class progression. Seek separately documented RM-carry adaptations, particularly the two Gen IV Multi formats, rather than rebranding benchmark teams as carry teams.

The honor catalog needs exact definitions and source links for Trainer Hill, Leaf/Shiny Crown, Unova Champion, Pokéstar star, Subway and Academy Ace. Pokéathlon, PWT and Black Tower/White Treehollow have initial source records. No honor is auto-completed from a save or a game visit.

## Implementation order and validation

1. Add backward-compatible local models for guide/source references, honors, journal entries and named personal builds. Include them in app backups and recovery.
2. Connect Description → Guide and the sourced team detail/personal-copy flow. Bundle reviewed summaries for offline reading; display a source card and checked date.
3. Add the optional honors album, record editor and local screenshot storage. Label trainer/save-wide feats attached manually to a Pokémon.
4. Add Journey notes and manual Move Dex notes within the current passport organization.
5. Expand reviewed content while checking compact-phone layouts, VoiceOver, reduced motion, old-backup decoding and external export compatibility.

Research validation checks source/game/award/team references, every existing earning pair exactly once, four moves per captured build and EV totals at most 510. These checks verify data consistency, not battle legality, source accuracy or in-game success.
