# Task 5: Duel Engine — Report

## TDD Process

### RED (Test Fails)
Wrote test file `/Users/greenolls/cursor/card_game/test/engine/duel_engine_test.dart` with 7 test cases covering:
- Basic power comparison (higher power wins, deals difference)
- Element advantage (+3 bonus when card beats opponent element)
- Tie condition (equal power = tie, 0 damage)
- Shield ability (prevents all damage on losing card)
- DoubleStrike ability (multiplies damage by 1.5, floored)
- ElementalShift ability (cancels opponent's element bonus)
- Barracks bonus (player-side boost for matching element)

Initial run failed as expected with "No such file or directory" for `duel_engine.dart`.

### GREEN (Test Passes)
Implemented `/Users/greenolls/cursor/card_game/lib/engine/duel_engine.dart` with:
- `DuelConfig` class with `startingCastleHp`, `handSize`, `barracksElement`, `barracksBonus`
- `enum RoundWinner { player, opponent, tie }`
- `RoundResult` class tracking winner, damage, and both powers
- `DuelEngine.effectivePower()` calculating:
  - Base card power
  - Element bonus: +3 if card element beats opponent (ElementRules.beats), UNLESS opponent has elementalShift
  - Barracks bonus: +config.barracksBonus if isPlayer AND card.element == config.barracksElement
- `DuelEngine.resolveRound()` determining:
  - Effective powers for both cards
  - Winner by power comparison
  - Damage calculation: (winnerPower - loserPower)
    - Multiplied by 1.5 then floored if winner has doubleStrike
    - Set to 0 if loser has shield
    - 0 damage on tie

Test output:
```
00:00 +0: resolveRound higher power wins and deals the difference
00:00 +1: resolveRound element advantage adds the bonus
00:00 +2: resolveRound tie deals no damage
00:00 +3: resolveRound shield on the losing card prevents damage
00:00 +4: resolveRound doubleStrike on the winning card multiplies damage by 1.5 floored
00:00 +5: resolveRound elementalShift on opponent cancels player element bonus
00:00 +6: resolveRound barracks bonus boosts the matching player element
00:00 +7: All tests passed!
```

### Full Suite (21 tests)
Ran `flutter test` to verify no regressions:
```
00:00 +0: /Users/greenolls/cursor/card_game/test/setup_smoke_test.dart: toolchain is wired up
00:00 +1-7: ElementRules tests (6 tests)
00:00 +8-11: Deck tests (4 tests)
00:00 +12-18: DuelEngine tests (7 tests)
00:00 +19-21: GameCard tests (3 tests)
All 21 tests passed!
```

## Verification of Brief Requirements

| Requirement | Implementation | Status |
|-------------|-----------------|--------|
| `DuelConfig` with 4 fields | ✓ All fields, defaults match brief | PASS |
| `enum RoundWinner` | ✓ player, opponent, tie | PASS |
| `RoundResult` with 4 fields | ✓ winner, damage, playerEffectivePower, opponentEffectivePower | PASS |
| `effectivePower()` static method | ✓ Takes card, opponentCard, isPlayer, config | PASS |
| Element bonus +3 | ✓ Tested: nature(5) beats water(6) → 8 vs 6 | PASS |
| ElementalShift cancels bonus | ✓ Tested: nature(5) + elementalShift opponent → 5 vs 5 tie | PASS |
| Barracks bonus player only | ✓ Tested: fire(5)+3 barracks → 8 vs fire(6) | PASS |
| Damage = power difference | ✓ Basic test: 7 vs 4 → 3 damage | PASS |
| DoubleStrike ×1.5 floor | ✓ Tested: (9-4)=5 → 7.5 → 7 | PASS |
| Shield = 0 damage | ✓ Tested: shield card loses, 0 damage | PASS |
| Tie = 0 damage | ✓ Tested: equal power → tie, 0 damage | PASS |

## Commit

```
dcd5101 feat: add duel round resolution with elements and abilities
```

Files:
- `/Users/greenolls/cursor/card_game/lib/engine/duel_engine.dart` (92 lines)
- `/Users/greenolls/cursor/card_game/test/engine/duel_engine_test.dart` (81 lines)

Imports follow brief constraint: only sibling engine files (`ability.dart`, `element.dart`, `game_card.dart`), no Flutter packages.

## Test Coverage Additions

Added four new test cases to cover symmetric and edge-case behaviors:

1. **elementalShift on player card cancels opponent element bonus**
   - Fire beats nature: opponent fire(5) would get +3 vs player nature(5) → 8 vs 5
   - Player's elementalShift cancels opponent's bonus → 5 vs 5 tie (0 damage)
   - Verifies symmetric behavior of elementalShift (works on player card too)

2. **doubleStrike applies when the opponent card wins**
   - Same element (no element bonus)
   - Opponent fire(9, doubleStrike) vs player fire(4)
   - Opponent wins: (9-4)=5 → floor(7.5)=7 damage
   - Verifies doubleStrike works for opponent cards

3. **shield on the winning card does not reduce damage**
   - Same element, player fire(8, shield) beats opponent fire(3)
   - Damage = 5 (shield only protects losing card)
   - Verifies shield has no effect when winning

4. **Added expect(r.damage, 0) to existing elementalShift test**
   - Existing test "elementalShift on opponent cancels player element bonus" now also asserts 0 damage
   - Ensures consistency in tie verification

### Test Results

**Targeted duel_engine_test.dart:**
```
flutter test test/engine/duel_engine_test.dart
00:00 +10: All tests passed!
```
10 tests: 7 original + 3 new + 1 enhanced = pristine pass.

**Full suite (flutter test):**
```
00:00 +24: All tests passed!
```
24 tests across all modules, no regressions.

### Commit

```
2a27d54 test: cover symmetric elementalShift, opponent doubleStrike, winner shield
```

File modified:
- `/Users/greenolls/cursor/card_game/test/engine/duel_engine_test.dart` (+36 lines)
