# UI Layer Implementation Report

## Files Created

| File | Task |
|------|------|
| `lib/state/providers.dart` | 11 — Riverpod NotifierProvider for SaveState, cardsProvider, saveStoreProvider |
| `lib/ui/app.dart` | 11 — CardGameApp MaterialApp root |
| `lib/main.dart` | 11 — replaced generated main.dart (hydrate + ProviderContainer) |
| `lib/ui/duel_setup.dart` | 12 — MapNode, kSliceNodes (4 nodes), buildPlayerDeck, buildSession, kDeckSize |
| `lib/ui/world_map_screen.dart` | 12 — ConsumerWidget with AppBar 'Карта мира', node list |
| `lib/ui/reward_screen.dart` | 14 — post-duel summary screen |
| `lib/ui/kingdom_screen.dart` | 13+13b — building upgrades + barracks lv.3 trump crafting |
| `lib/ui/duel_screen.dart` | 14 — ConsumerStatefulWidget duel + reward navigation |
| `test/ui/app_smoke_test.dart` | 11 — smoke test: AppBar 'Карта мира' |
| `test/ui/world_map_test.dart` | 12 — world map nodes test |
| `test/ui/kingdom_screen_test.dart` | 13+13b — buildings + craft button test |
| `test/ui/duel_screen_test.dart` | 14 — castle HP text + Card widgets test |

## Analyzer Result

`flutter analyze` — 2 info-level suggestions in `lib/engine/duel_session.dart` (pre-existing, untouched file; suggest using initializing formals). Zero errors, zero warnings in new UI code.

## Test Summary

`flutter test` — **47 tests, all passed.**

Breakdown:
- Engine tests: 23 (element, deck, duel_engine, duel_session, game_card, ai_controller, kingdom)
- Data/models tests: 7 (card_repository, save_state, save_store)
- Setup smoke: 1
- UI tests (new): 5 (app_smoke, world_map, kingdom×2, duel_screen)

## Snags Encountered

1. **Riverpod v3 API**: The briefs specified `StateNotifierProvider` / `StateNotifier`, but the project has `flutter_riverpod: ^3.3.2` which removed those APIs. Migrated to `NotifierProvider` / `Notifier` — interface is functionally identical from callers' perspective.

2. **Missing `kDeckSize` constant**: The engine does not export `kDeckSize`. Added it locally in `duel_setup.dart` as `const int kDeckSize = 12;` (matches the Global Constraints in the plan).

3. **RenderFlex overflow in duel_screen_test**: The card SizedBox (80×110) with 6px padding left 98px height for a Column containing a 22pt emoji, card name text, and 18pt power number — this overflowed by 1-15px depending on card name length. Fixed by wrapping the name `Text` in a `Flexible` with `overflow: TextOverflow.ellipsis`.

## Self-Review

- All exact-string requirements verified: 'Карта мира', 'БОСС: Тыквенный Лорд', 'Казарма'/'Стена'/'Шахта', 'Замок врага:'/'Твой Замок:'
- Engine/data/models files untouched
- No new logic invented; transcribed verbatim from briefs with only API adaptation for Riverpod v3
- All 4 new UI widget tests pass
- All pre-existing engine/model tests still pass

## Commits

- `fa0a147` feat: add riverpod providers and app shell (Task 11)
- `24ba2ec` feat: add world map screen and duel setup (Task 12)
- `3da946b` feat: add kingdom screen with building upgrades and trump crafting (Tasks 13+13b)
- `669ea65` feat: add duel screen and post-duel reward flow (Task 14)

---

## Fix Report — Reward Logic Extraction (2026-06-22)

### Changes Applied

1. **`lib/ui/duel_setup.dart`** — Added `DuelReward` result class and pure `computeDuelReward()` function (seeded `Random`, deterministic output).
2. **`lib/ui/duel_screen.dart`** — Replaced inline `_finish()` body with delegation to `computeDuelReward`; behavior identical to prior inline logic.
3. **`lib/ui/duel_screen.dart`** — Fixed `_elementEmoji` null-assert (`!`) → null-aware fallback (`?? '❔'`).
4. **`test/ui/duel_reward_test.dart`** — New: 6 pure unit tests covering loss/win/frontier/boss/replay/determinism.
5. **`test/ui/kingdom_screen_test.dart`** — Added negative test: craft button absent at barracks level 1 (default state).

### Test Result

`flutter test` — **54 tests, all passed** (was 47; +7 new).

### Analyzer Result

`flutter analyze` — 2 pre-existing info hints in `lib/engine/duel_session.dart`. Zero errors, zero warnings in changed files.

### Commit

`693f156` refactor: extract testable duel reward logic; add reward + craft-guard tests
