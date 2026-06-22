# Task 6: Player Controllers Report

## TDD Workflow

### Step 1: Write Failing Test
Created `test/engine/ai_controller_test.dart` with:
- Test "AI picks the highest-power card" — expects `AiController` to pick card 'b' with power 7 from hand `[c('a', 3), c('b', 7), c('d', 5)]`
- Test "AI tie-breaks deterministically by id" — expects `AiController` to pick card 'a' (lower id) when both 'z' and 'a' have power 5

**RED evidence:**
```
test/engine/ai_controller_test.dart:2:8: Error: Error when reading 'lib/engine/ai_controller.dart': No such file or directory
```

### Step 2: Verify Fail
Ran: `flutter test test/engine/ai_controller_test.dart`

Confirmed compilation error: files not found.

### Step 3: Implement PlayerController Abstract Class
Created `lib/engine/player_controller.dart`:
- Defined `abstract class PlayerController` with `chooseCard({required List<GameCard> hand, required DuelConfig config, GameCard? opponentLastCard})`
- Implemented `HumanController extends PlayerController` throwing `UnimplementedError('Human moves are supplied by the UI layer.')`
- Imports only sibling engine files: `duel_engine.dart`, `game_card.dart`
- No Flutter imports

### Step 4: Implement AiController
Created `lib/engine/ai_controller.dart`:
- Implemented `AiController extends PlayerController`
- Algorithm:
  1. Copy hand into mutable list
  2. Sort by power descending (higher power first via `b.power.compareTo(a.power)`)
  3. Tie-break by id ascending (lower id first via `a.id.compareTo(b.id)`)
  4. Return first card (highest power, lowest id on tie)
- Imports only sibling engine files: `duel_engine.dart`, `game_card.dart`, `player_controller.dart`
- No Flutter imports

### Step 5: Verify Tests Pass
Ran: `flutter test test/engine/ai_controller_test.dart`

**GREEN evidence:**
```
00:00 +0: AI picks the highest-power card
00:00 +1: AI tie-breaks deterministically by id
00:00 +2: All tests passed!
```

### Step 6: Full Test Suite
Ran: `flutter test` (all tests)

**Pristine output:**
```
00:00 +26: All tests passed!
```

All 26 tests pass including the 2 new AI controller tests.

### Step 7: Commit
Executed:
```bash
git add lib/engine/player_controller.dart lib/engine/ai_controller.dart test/engine/ai_controller_test.dart
git commit -m "feat: add player controller interface and heuristic AI"
```

**Commit:** `f69628e feat: add player controller interface and heuristic AI`

## Deliverables

✅ `lib/engine/player_controller.dart` — Abstract `PlayerController` interface + `HumanController`
✅ `lib/engine/ai_controller.dart` — `AiController` with greedy highest-power strategy
✅ `test/engine/ai_controller_test.dart` — 2 test cases (highest power, deterministic tie-break by id)
✅ Full test suite passes (26/26 tests)
✅ Verbatim implementation from brief
✅ Pure Dart, no Flutter imports
✅ Commit created

## Summary

Task 6 completed following TDD exactly per the brief:
1. Failing test written (RED)
2. Implementation added (GREEN)
3. Full suite passes with pristine output
4. Commit created

All code matches the brief verbatim.
