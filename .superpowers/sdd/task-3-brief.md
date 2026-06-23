### Task 3: Ability and GameCard models

**Files:**
- Create: `lib/engine/ability.dart`, `lib/engine/game_card.dart`
- Test: `test/engine/game_card_test.dart`

**Interfaces:**
- Consumes: `Element` (Task 2).
- Produces:
  - `enum Ability { elementalShift, doubleStrike, shield }`
  - `enum Rarity { common, rare, trump }`
  - `class GameCard { final String id, name; final Element element; final int power; final Rarity rarity; final Ability? ability; const GameCard({...}); }` with value equality on `id`.

- [ ] **Step 1: Write the failing test**

`test/engine/game_card_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/ability.dart';
import 'package:card_game/engine/element.dart';
import 'package:card_game/engine/game_card.dart';

void main() {
  test('constructs a common card with no ability', () {
    const card = GameCard(
      id: 'fire_deer',
      name: 'Горячий Олень',
      element: Element.fire,
      power: 5,
      rarity: Rarity.common,
    );
    expect(card.ability, isNull);
    expect(card.rarity, Rarity.common);
    expect(card.power, 5);
  });

  test('constructs a trump card with an ability', () {
    const trump = GameCard(
      id: 'pumpkin_king',
      name: 'Король-Тыква',
      element: Element.nature,
      power: 9,
      rarity: Rarity.trump,
      ability: Ability.doubleStrike,
    );
    expect(trump.ability, Ability.doubleStrike);
  });

  test('cards are equal by id', () {
    const a = GameCard(id: 'x', name: 'A', element: Element.fire, power: 1, rarity: Rarity.common);
    const b = GameCard(id: 'x', name: 'A clone', element: Element.water, power: 9, rarity: Rarity.rare);
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/engine/game_card_test.dart`
Expected: FAIL (files not found).

- [ ] **Step 3: Write `lib/engine/ability.dart`**

```dart
/// Trump-card abilities used in the vertical slice.
enum Ability {
  /// Ignore the opponent's element bonus this round.
  elementalShift,

  /// Deal x1.5 damage (floored) on a won round.
  doubleStrike,

  /// Take no castle damage on a lost round.
  shield,
}

/// Card rarity tiers.
enum Rarity { common, rare, trump }
```

- [ ] **Step 4: Write `lib/engine/game_card.dart`**

```dart
import 'ability.dart';
import 'element.dart';

class GameCard {
  final String id;
  final String name;
  final Element element;
  final int power;
  final Rarity rarity;
  final Ability? ability;

  const GameCard({
    required this.id,
    required this.name,
    required this.element,
    required this.power,
    required this.rarity,
    this.ability,
  });

  @override
  bool operator ==(Object other) => other is GameCard && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'GameCard($id, $name, $element, p$power)';
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/engine/game_card_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/engine/ability.dart lib/engine/game_card.dart test/engine/game_card_test.dart
git commit -m "feat: add ability, rarity, and GameCard models"
```

---

