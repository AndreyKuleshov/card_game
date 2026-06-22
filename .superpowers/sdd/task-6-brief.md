### Task 6: Player controllers (interface + human + AI)

**Files:**
- Create: `lib/engine/player_controller.dart`, `lib/engine/ai_controller.dart`
- Test: `test/engine/ai_controller_test.dart`

**Interfaces:**
- Consumes: `GameCard`, `DuelConfig`, `DuelEngine` (Tasks 3, 5).
- Produces:
  - `abstract class PlayerController { GameCard chooseCard({required List<GameCard> hand, required DuelConfig config, GameCard? opponentLastCard}); }`
  - `class HumanController extends PlayerController` — throws `UnimplementedError` (human moves come from the UI, not this method; the class exists for type symmetry/PvP later).
  - `class AiController extends PlayerController` — picks the hand card with the highest base power (deterministic tie-break by card `id`).

- [ ] **Step 1: Write the failing test**

`test/engine/ai_controller_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/ai_controller.dart';
import 'package:card_game/engine/duel_engine.dart';
import 'package:card_game/engine/element.dart';
import 'package:card_game/engine/game_card.dart';

GameCard c(String id, int p) =>
    GameCard(id: id, name: id, element: Element.fire, power: p, rarity: Rarity.common);

void main() {
  test('AI picks the highest-power card', () {
    final ai = AiController();
    final pick = ai.chooseCard(hand: [c('a', 3), c('b', 7), c('d', 5)], config: const DuelConfig());
    expect(pick.id, 'b');
  });

  test('AI tie-breaks deterministically by id', () {
    final ai = AiController();
    final pick = ai.chooseCard(hand: [c('z', 5), c('a', 5)], config: const DuelConfig());
    expect(pick.id, 'a');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/engine/ai_controller_test.dart`
Expected: FAIL (files not found).

- [ ] **Step 3: Write `lib/engine/player_controller.dart`**

```dart
import 'duel_engine.dart';
import 'game_card.dart';

abstract class PlayerController {
  /// Choose a card to play this round from [hand].
  GameCard chooseCard({
    required List<GameCard> hand,
    required DuelConfig config,
    GameCard? opponentLastCard,
  });
}

/// Human moves arrive from the UI, not from this method. The class exists so
/// the duel flow is symmetric and a RemoteController can slot in later.
class HumanController extends PlayerController {
  @override
  GameCard chooseCard({
    required List<GameCard> hand,
    required DuelConfig config,
    GameCard? opponentLastCard,
  }) {
    throw UnimplementedError('Human moves are supplied by the UI layer.');
  }
}
```

- [ ] **Step 4: Write `lib/engine/ai_controller.dart`**

```dart
import 'duel_engine.dart';
import 'game_card.dart';
import 'player_controller.dart';

class AiController extends PlayerController {
  @override
  GameCard chooseCard({
    required List<GameCard> hand,
    required DuelConfig config,
    GameCard? opponentLastCard,
  }) {
    final sorted = List<GameCard>.of(hand)
      ..sort((a, b) {
        final byPower = b.power.compareTo(a.power);
        return byPower != 0 ? byPower : a.id.compareTo(b.id);
      });
    return sorted.first;
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/engine/ai_controller_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/engine/player_controller.dart lib/engine/ai_controller.dart test/engine/ai_controller_test.dart
git commit -m "feat: add player controller interface and heuristic AI"
```

---

