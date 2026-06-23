### Task 4: Deck (draw, hand, deterministic shuffle)

**Files:**
- Create: `lib/engine/deck.dart`
- Test: `test/engine/deck_test.dart`

**Interfaces:**
- Consumes: `GameCard` (Task 3).
- Produces:
  - `class Deck { Deck(List<GameCard> cards); int get remaining; bool get isEmpty; GameCard? draw(); List<GameCard> drawUpTo(int n); void shuffle(Random random); }`
  - `draw()` removes and returns the top card, or `null` if empty.
  - `drawUpTo(n)` returns up to `n` cards (fewer if deck runs out).

- [ ] **Step 1: Write the failing test**

`test/engine/deck_test.dart`:
```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/deck.dart';
import 'package:card_game/engine/element.dart';
import 'package:card_game/engine/game_card.dart';

GameCard c(String id) =>
    GameCard(id: id, name: id, element: Element.fire, power: 1, rarity: Rarity.common);

void main() {
  test('draw removes from the top and reports remaining', () {
    final deck = Deck([c('a'), c('b'), c('c')]);
    expect(deck.remaining, 3);
    expect(deck.draw()?.id, 'a');
    expect(deck.remaining, 2);
  });

  test('draw returns null when empty', () {
    final deck = Deck([]);
    expect(deck.isEmpty, isTrue);
    expect(deck.draw(), isNull);
  });

  test('drawUpTo returns fewer cards when deck runs out', () {
    final deck = Deck([c('a'), c('b')]);
    final hand = deck.drawUpTo(4);
    expect(hand.map((e) => e.id), ['a', 'b']);
    expect(deck.remaining, 0);
  });

  test('shuffle with a seeded Random is deterministic', () {
    final d1 = Deck([c('a'), c('b'), c('c'), c('d')])..shuffle(Random(42));
    final d2 = Deck([c('a'), c('b'), c('c'), c('d')])..shuffle(Random(42));
    expect(d1.drawUpTo(4).map((e) => e.id), d2.drawUpTo(4).map((e) => e.id));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/engine/deck_test.dart`
Expected: FAIL (deck.dart not found).

- [ ] **Step 3: Write minimal implementation**

`lib/engine/deck.dart`:
```dart
import 'dart:math';
import 'game_card.dart';

class Deck {
  final List<GameCard> _cards;

  Deck(List<GameCard> cards) : _cards = List.of(cards);

  int get remaining => _cards.length;
  bool get isEmpty => _cards.isEmpty;

  GameCard? draw() => _cards.isEmpty ? null : _cards.removeAt(0);

  List<GameCard> drawUpTo(int n) {
    final out = <GameCard>[];
    for (var i = 0; i < n; i++) {
      final card = draw();
      if (card == null) break;
      out.add(card);
    }
    return out;
  }

  void shuffle(Random random) => _cards.shuffle(random);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/engine/deck_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/deck.dart test/engine/deck_test.dart
git commit -m "feat: add deck with deterministic shuffle and draw"
```

---

