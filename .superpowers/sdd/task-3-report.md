# Task 3: Ability and GameCard models — Report

## Summary
Implemented `Ability` and `Rarity` enums in `lib/engine/ability.dart`, plus the `GameCard` class in `lib/engine/game_card.dart`, following exact TDD specifications. All tests pass; full test suite runs cleanly.

## TDD Process

### Step 1: Write Failing Test ✓
Created `test/engine/game_card_test.dart` with three test cases:
- Construct a common card with no ability
- Construct a trump card with an ability
- Cards are equal by id (including hashCode)

### Step 2: Confirm Test Fails ✓
Ran `flutter test test/engine/game_card_test.dart`
```
Compilation failed for testPath=/Users/greenolls/cursor/card_game/test/engine/game_card_test.dart
Error: Error when reading 'lib/engine/ability.dart': No such file or directory
Error: Error when reading 'lib/engine/game_card.dart': No such file or directory
```
**Expected failure confirmed** — files do not exist yet.

### Step 3: Write `lib/engine/ability.dart` ✓
Implemented per brief:
- `enum Ability { elementalShift, doubleStrike, shield }` with documentation
- `enum Rarity { common, rare, trump }`

### Step 4: Write `lib/engine/game_card.dart` ✓
Implemented per brief:
- `class GameCard` with fields: `id`, `name`, `element`, `power`, `rarity`, `ability?`
- Constructor: const, all required except `ability`
- Value equality: `operator ==` compares by `id` only
- `hashCode` returns `id.hashCode`
- `toString()` returns formatted string

### Step 5: Confirm Test Passes ✓
Ran `flutter test test/engine/game_card_test.dart`
```
00:00 +0: loading /Users/greenolls/cursor/card_game/test/engine/game_card_test.dart
00:00 +0: constructs a common card with no ability
00:00 +1: constructs a trump card with an ability
00:00 +2: cards are equal by id
00:00 +3: All tests passed!
```
**All 3 tests GREEN**.

### Step 6: Full Test Suite ✓
Ran `flutter test` (all tests):
```
00:00 +10: All tests passed!
```
Tests breakdown:
- `setup_smoke_test.dart` (1 test) — GREEN
- `engine/element_test.dart` (6 tests) — GREEN
- `engine/game_card_test.dart` (3 tests) — GREEN

**Pristine output — no regressions.**

### Step 7: Commit ✓
```
[feature/vertical-slice 878c98a] feat: add ability, rarity, and GameCard models
 3 files changed, 81 insertions(+)
 create mode 100644 lib/engine/ability.dart
 create mode 100644 lib/engine/game_card.dart
 create mode 0644 test/engine/game_card_test.dart
```

## Files Created
1. `/Users/greenolls/cursor/card_game/lib/engine/ability.dart` (13 lines)
2. `/Users/greenolls/cursor/card_game/lib/engine/game_card.dart` (27 lines)
3. `/Users/greenolls/cursor/card_game/test/engine/game_card_test.dart` (34 lines)

## Implementation Notes
- Used pure Dart (no Flutter imports in engine code)
- GameCard uses value equality on `id` only, as specified
- All constants marked `const` for compile-time construction
- Imports use relative paths within engine package (e.g., `import 'ability.dart'`)
- Test imports use full package path (e.g., `import 'package:card_game/engine/ability.dart'`)
- Ability enum includes doc comments matching the brief exactly

## Verification
- All 10 tests pass (1 smoke + 6 element + 3 game_card)
- No compilation warnings
- No test regressions
- Commit ready for merge
