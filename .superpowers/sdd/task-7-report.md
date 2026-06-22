# Task 7: Kingdom — Buildings, Upgrades, Economy

## TDD Process

### Step 1: Write Failing Test
Created `/test/engine/kingdom_test.dart` with 5 test cases verifying:
- Default kingdom initialization (all levels = 1, barracksElement = fire)
- Building effect formulas (barracksBonus = level, wallHpBonus = level * 5, mineCrystalsPerWin = level * 2)
- Upgrade mechanics with level cap at 3
- Upgrade cost table (level 1 → 10 crystals, level 2 → 25 crystals, level 3+ → 0)
- DuelConfig integration (startingCastleHp = 30 + wallHpBonus, barracksElement/barracksBonus mapping)

**RED Status:** Test compilation failed with 12 errors as expected (kingdom.dart doesn't exist).

```
test/engine/kingdom_test.dart:3:8: Error: Error when reading 'lib/engine/kingdom.dart': No such file or directory
```

### Step 2: Implement Minimal Solution
Created `/lib/engine/kingdom.dart` (80 lines) with:

**enum BuildingType**
- Three values: `barracks`, `wall`, `mine`

**class Kingdom**
- Final fields: `barracksLevel`, `wallLevel`, `mineLevel`, `barracksElement`
- Const constructor with defaults (all levels = 1, barracksElement = Element.fire)
- Getters: `barracksBonus`, `wallHpBonus`, `mineCrystalsPerWin`
- Method: `levelOf(BuildingType)` — returns current level
- Method: `upgraded(BuildingType)` — increments level, caps at 3
- Method: `copyWith()` — immutable update pattern

**class KingdomEconomy**
- Static method: `upgradeCost(type, currentLevel)` — returns 10/25/0 based on current level
- Static method: `toDuelConfig(k)` — maps Kingdom to DuelConfig with wall/barracks bonuses

**GREEN Status:** All 5 kingdom tests passed.

```
00:00 +0: default kingdom is all level 1 with fire barracks
00:00 +1: building effects scale with level
00:00 +2: upgrading increments level and caps at 3
00:00 +3: upgrade cost table
00:00 +4: toDuelConfig maps wall hp and barracks bonus
00:00 +5: All tests passed!
```

### Step 3: Verify Full Test Suite
Ran `flutter test` (all 31 tests across the project):

```
00:00 +0-26: [existing tests across element, deck, duel_engine, ai_controller, game_card]
00:00 +26-31: [5 new kingdom tests]
All 31 tests passed!
```

No regressions. Implementation is pure Dart (only `duel_engine.dart`, `element.dart` imports).

## Code Quality
- Follows immutability pattern (const constructor, copyWith)
- No Flutter imports (engine layer)
- Clear getters for effect scaling
- Switch exhaustiveness enforced by Dart analyzer
- Cost table maps to brief spec exactly

## Commit
```
commit 4ebffd7
feat: add kingdom buildings, upgrades, and economy
```

## Test Evidence

### Red Phase
- kingdom_test.dart: 12 compilation errors (file not found)
- Test would not run

### Green Phase
- 5 kingdom_test cases: PASS
- 26 existing tests: PASS (no regressions)
- Total: 31/31 PASS

### Verification
All formulas verified:
- barracksBonus(level 1/2/3) = 1/2/3 ✓
- wallHpBonus(level 1/2/3) = 5/10/15 ✓
- mineCrystalsPerWin(level 1/2/3) = 2/4/6 ✓
- upgradeCost(1) = 10, upgradeCost(2) = 25, upgradeCost(3+) = 0 ✓
- toDuelConfig: startingCastleHp = 30 + wallHpBonus, barracksElement/barracksBonus preserved ✓
