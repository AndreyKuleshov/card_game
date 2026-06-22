
---

## Fix Report — 2026-06-22 (commit 9c33425)

### Changes made

**Finding 1 — Genuine random chest drops (`lib/ui/duel_setup.dart`, `lib/ui/duel_screen.dart`, `test/ui/duel_reward_test.dart`)**
- Removed `Random(node.index + 7)` constant seed from `computeDuelReward`.
- Added `required Random random` parameter; caller now owns the RNG.
- `_finish` in `duel_screen.dart` passes `random: Random()` (unseeded = truly random).
- Tests: replaced the "determinism" test with two seed-locked behavior tests:
  - seed=2 → `nextDouble()=0.0007836` (< 0.30) → `trumpGranted == 'trump_frost_granny'` ✓
  - seed=0 → `nextDouble()=0.8255141` (>= 0.30) → `trumpGranted == null` ✓

**Finding 2 — Craft path gets its own trump (`lib/ui/kingdom_screen.dart`, `test/ui/kingdom_screen_test.dart`)**
- Replaced `trump_pumpkin_king`/`trump_frost_granny` toggle logic with a single `craftId = 'trump_lava_cat'`.
- When already owned, shows 'Козырь кузницы создан'; otherwise shows the craft button.
- Added widget test: barracks level 3 + 200 crystals → tap 'Создать козырь (40💎)' → `ownedCardIds` contains `trump_lava_cat`.

**Finding 3 — GAME_DESIGN.md §5 honest trump list**
- Updated the three acquisition paths to name concrete trump ids:
  boss → `trump_pumpkin_king`, крафт → `trump_lava_cat`, сундук → `trump_frost_granny`
- Added starter path: `trump_starter_drake`.
- Updated total count from "3–4" to "4 козыря".

### Seeds chosen
| Seed | nextDouble() | Outcome |
|------|-------------|---------|
| 2    | 0.0007836   | < 0.30 → chest grants trump_frost_granny |
| 0    | 0.8255141   | >= 0.30 → no chest drop |

### Test result
`flutter test` — **56 tests passed**, 0 failures.

### Analyze result
`flutter analyze` — **No issues found!** (ran in 4.5s)

### Commit
`9c33425` — fix: inject Random into computeDuelReward, assign craft trump_lava_cat, update design doc trumps
