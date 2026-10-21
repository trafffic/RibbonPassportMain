# Guided game check-in — 21 October 2026

Option 3 is implemented in the native app. From a safe **current-game** transfer check, **Record a new game** opens the generation step, followed by compatible games in the chosen generation. Recording a game updates the current game, preserves the known departure in Journey, and retains ribbon ownership and earning locations. Undo restores the previous record. Cancel makes no changes. Standalone Add/Edit sheets retain their existing outer Save action; passport changes use the existing immediate save path.

All new text uses `PixelFont` / bundled Pixelify Sans. The screens share `PassportTheme`, `RetroAction`, `TerminalBackControl`, `GameMascot`, and `PokemonSprite` with the app. Long labels wrap, content scrolls on compact screens, and the action area remains visible. Native captures were visually inspected in light/dark at 320/390 points with larger text, plus the simulator interaction screens below.

## Validation

- [Successful native run](https://github.com/trafffic/RibbonPassportMain/actions/runs/39513977154), tested source `8c82f97bfc3ba68ea69967265082573bdca3a969`.
- Xcode 26.3, macOS 15.7.9 Intel, iPhone SE (3rd generation), iOS Simulator 26.2.
- **104 unit/render tests passed**, zero failures or skips. Includes five new checks for preserved history, safe/compatible destinations, skipped-generation history, JSON round trips, failed saves/recovery, bundled font availability and native compact renders.
- **3 UI tests passed**, zero failures or skips: overview check-in, changing generation, disabled save before game selection, successful recording, Undo/cancel; ribbon-tab check-in reflected in the passport and Journey; existing transfer checklist and Undo regression.
- App and widget targets compiled in the Debug simulator build. Signing and collection formats were unchanged. The previously validated `self.kind(of:)` recovery compiler fix is included so the app builds on this Xcode version.
- The local app/shared/test sources match the tested source. The temporary validation workflow stays on `codex/guided-game-check-in`.

Tests use injected save closures and the isolated Debug interaction fixture. These results cover the simulator, not physical-device or VoiceOver interaction testing.

## Retained evidence

Machine-readable summaries: [unit/render](unit-summary.json), [UI interactions](guided-move-summary.json).

- [Generation step](guided-move-generation.png)
- [Selected destination](guided-move-game-selected.png)
- [Recorded move](guided-move-recorded.png)
- [Updated passport](guided-move-passport-updated.png)
- [Updated Journey](guided-move-journey-updated.png)
- Larger-text render: [320 light](guided-move-320-light.png), [320 dark](guided-move-320-dark.png), [390 light](guided-move-390-light.png), [390 dark](guided-move-390-dark.png).
