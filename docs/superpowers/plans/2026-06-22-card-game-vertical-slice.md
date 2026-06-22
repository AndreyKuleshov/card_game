# Fantasy Card Game — Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable offline vertical slice of a humorous fantasy card-duel game in Flutter: duel an AI by comparing cards (power + element), earn crystals, upgrade a 3-building kingdom, and acquire trump cards three ways, across a linear 3-node + boss map.

**Architecture:** A pure-Dart rules engine (`lib/engine/`) with zero Flutter imports holds all game logic and is fully unit-tested. A `PlayerController` interface abstracts move selection so `HumanController` and `AiController` are swappable (and `RemoteController` can be added later for PvP without touching the engine). Riverpod providers hold app state; game state is persisted locally as a single JSON blob via `shared_preferences`. The Flutter UI layer renders engine state and feeds player moves back in.

**Tech Stack:** Flutter (stable), Dart, `flutter_riverpod` (state), `shared_preferences` (persistence), `flutter test` (unit + widget tests). No code-generation dependencies.

## Global Constraints

- **Card class is named `GameCard`** — never `Card` (collides with the Flutter `Card` widget).
- **Three elements**, cycle: Fire → Nature → Water → Fire (each beats the next).
- **Element advantage bonus: +3** to effective power (constant `kElementBonus = 3`).
- **Starting castle HP: 30** (`kBaseCastleHp = 30`); **hand size: 4** (`kHandSize = 4`); **deck size: 12** (`kDeckSize = 12`).
- **Card power range: 1–10.** Trump cards: power 8–10 plus exactly one ability.
- **Abilities (slice):** `elementalShift` (ignore opponent's element bonus this round), `doubleStrike` (×1.5 damage on a won round, floored), `shield` (no castle damage on a lost round).
- **Russian, playful card names** (e.g. «Горелый Пирожок»), never grim dark-fantasy naming.
- **`lib/engine/` files import only `dart:*`** — no `package:flutter/*`. This is enforced by review.
- **Commit messages:** Conventional Commits, English (e.g. `feat: add element resolution`).
- **All randomness goes through an injected `Random`** so tests are deterministic (seeded).

---

## File Structure

```
lib/
  engine/
    element.dart          # Element enum + ElementRules (cycle, bonus)
    ability.dart          # Ability enum
    game_card.dart        # GameCard model
    deck.dart             # Deck (draw, hand, shuffle via injected Random)
    duel_engine.dart      # DuelConfig, DuelState, RoundResult, DuelEngine
    player_controller.dart# PlayerController interface + HumanController
    ai_controller.dart    # AiController (heuristic)
    kingdom.dart          # BuildingType, Building, Kingdom, economy rules
  data/
    card_repository.dart  # loads/parses cards from JSON
  models/
    save_state.dart       # SaveState model + JSON (de)serialization
    save_store.dart       # SaveStore: persist/load via shared_preferences
  state/
    providers.dart        # Riverpod providers (save, kingdom, duel)
  ui/
    app.dart              # MaterialApp + routing
    world_map_screen.dart # linear node chain + boss
    kingdom_screen.dart   # buildings + upgrade buttons
    deck_screen.dart      # view collection / deck
    duel_screen.dart      # the duel UI
    reward_screen.dart    # post-duel reward / chest
assets/
  cards.json              # card definitions
test/
  engine/                 # one test file per engine unit
  data/
  models/
  ui/
```

---

### Task 1: Project setup and dependencies

**Files:**
- Create: `pubspec.yaml` (via `flutter create`, then edit)
- Create: folder skeleton under `lib/` and `test/`
- Test: `test/setup_smoke_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: a runnable Flutter project with `flutter_riverpod` and `shared_preferences` available; `flutter test` green.

- [ ] **Step 1: Create the Flutter project in the current directory**

Run:
```bash
cd /Users/greenolls/cursor/card_game
flutter create --org com.cardgame --project-name card_game .
```
Expected: project scaffold created; `flutter --version` shows a stable channel.

- [ ] **Step 2: Add dependencies**

Run:
```bash
flutter pub add flutter_riverpod shared_preferences
flutter pub get
```
Expected: `pubspec.yaml` lists `flutter_riverpod` and `shared_preferences` under `dependencies`; pub get succeeds.

- [ ] **Step 3: Register the assets directory in `pubspec.yaml`**

Under the `flutter:` section add:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/cards.json
```

- [ ] **Step 4: Create folder skeleton**

Run:
```bash
mkdir -p lib/engine lib/data lib/models lib/state lib/ui assets test/engine test/data test/models test/ui
```

- [ ] **Step 5: Replace the default widget test with a smoke test**

Delete `test/widget_test.dart` and create `test/setup_smoke_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toolchain is wired up', () {
    expect(1 + 1, 2);
  });
}
```

- [ ] **Step 6: Run tests**

Run: `flutter test`
Expected: PASS (1 test).

- [ ] **Step 7: Commit**

```bash
git init
git add -A
git commit -m "chore: scaffold flutter project with riverpod and shared_preferences"
```

---

### Task 2: Element model and resolution rules

**Files:**
- Create: `lib/engine/element.dart`
- Test: `test/engine/element_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `enum Element { fire, nature, water }`
  - `const int kElementBonus = 3;`
  - `class ElementRules { static bool beats(Element a, Element b); }` — `true` iff `a` has advantage over `b`.

- [ ] **Step 1: Write the failing test**

`test/engine/element_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/element.dart';

void main() {
  group('ElementRules.beats', () {
    test('fire beats nature', () {
      expect(ElementRules.beats(Element.fire, Element.nature), isTrue);
    });
    test('nature beats water', () {
      expect(ElementRules.beats(Element.nature, Element.water), isTrue);
    });
    test('water beats fire', () {
      expect(ElementRules.beats(Element.water, Element.fire), isTrue);
    });
    test('relationship is not symmetric', () {
      expect(ElementRules.beats(Element.nature, Element.fire), isFalse);
      expect(ElementRules.beats(Element.water, Element.nature), isFalse);
      expect(ElementRules.beats(Element.fire, Element.water), isFalse);
    });
    test('same element has no advantage', () {
      expect(ElementRules.beats(Element.fire, Element.fire), isFalse);
    });
  });

  test('element bonus is 3', () {
    expect(kElementBonus, 3);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/engine/element_test.dart`
Expected: FAIL (target of URI doesn't exist / `element.dart` not found).

- [ ] **Step 3: Write minimal implementation**

`lib/engine/element.dart`:
```dart
/// The three fantasy elements. Cycle: fire -> nature -> water -> fire.
enum Element { fire, nature, water }

/// Bonus added to effective power when a card has elemental advantage.
const int kElementBonus = 3;

class ElementRules {
  const ElementRules._();

  /// Returns true if [a] has elemental advantage over [b].
  static bool beats(Element a, Element b) {
    switch (a) {
      case Element.fire:
        return b == Element.nature;
      case Element.nature:
        return b == Element.water;
      case Element.water:
        return b == Element.fire;
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/engine/element_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/element.dart test/engine/element_test.dart
git commit -m "feat: add element model and advantage rules"
```

---

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

### Task 5: Duel engine — power, damage, abilities, win condition

**Files:**
- Create: `lib/engine/duel_engine.dart`
- Test: `test/engine/duel_engine_test.dart`

**Interfaces:**
- Consumes: `GameCard`, `Element`, `ElementRules`, `kElementBonus`, `Ability` (Tasks 2–3).
- Produces:
  - `class DuelConfig { final int startingCastleHp; final int handSize; final Element? barracksElement; final int barracksBonus; const DuelConfig({this.startingCastleHp = 30, this.handSize = 4, this.barracksElement, this.barracksBonus = 0}); }`
  - `enum RoundWinner { player, opponent, tie }`
  - `class RoundResult { final RoundWinner winner; final int damage; final int playerEffectivePower; final int opponentEffectivePower; }`
  - `class DuelEngine { static int effectivePower({required GameCard card, required GameCard opponentCard, required bool isPlayer, required DuelConfig config}); static RoundResult resolveRound({required GameCard playerCard, required GameCard opponentCard, required DuelConfig config}); }`
  - `effectivePower` = base power + element bonus (if `card.element` beats `opponentCard.element`, unless the opponent card has `elementalShift`) + barracks bonus (player side only, when `card.element == config.barracksElement`).
  - Damage = `(winnerPower - loserPower)`, ×1.5 floored if the winning card has `doubleStrike`; `0` if the losing card has `shield`; `0` on tie.

- [ ] **Step 1: Write the failing test**

`test/engine/duel_engine_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/ability.dart';
import 'package:card_game/engine/duel_engine.dart';
import 'package:card_game/engine/element.dart';
import 'package:card_game/engine/game_card.dart';

GameCard card(String id, Element e, int p, {Ability? ability, Rarity rarity = Rarity.common}) =>
    GameCard(id: id, name: id, element: e, power: p, rarity: ability == null ? rarity : Rarity.trump, ability: ability);

const cfg = DuelConfig();

void main() {
  group('resolveRound', () {
    test('higher power wins and deals the difference', () {
      final r = DuelEngine.resolveRound(
        playerCard: card('p', Element.fire, 7),
        opponentCard: card('o', Element.fire, 4),
        config: cfg,
      );
      expect(r.winner, RoundWinner.player);
      expect(r.damage, 3);
    });

    test('element advantage adds the bonus', () {
      // Player nature(5) vs opponent water(6): nature beats water -> 5+3=8 vs 6.
      final r = DuelEngine.resolveRound(
        playerCard: card('p', Element.nature, 5),
        opponentCard: card('o', Element.water, 6),
        config: cfg,
      );
      expect(r.winner, RoundWinner.player);
      expect(r.damage, 2); // 8 - 6
    });

    test('tie deals no damage', () {
      final r = DuelEngine.resolveRound(
        playerCard: card('p', Element.fire, 5),
        opponentCard: card('o', Element.fire, 5),
        config: cfg,
      );
      expect(r.winner, RoundWinner.tie);
      expect(r.damage, 0);
    });

    test('shield on the losing card prevents damage', () {
      final r = DuelEngine.resolveRound(
        playerCard: card('p', Element.fire, 3, ability: Ability.shield),
        opponentCard: card('o', Element.fire, 8),
        config: cfg,
      );
      expect(r.winner, RoundWinner.opponent);
      expect(r.damage, 0);
    });

    test('doubleStrike on the winning card multiplies damage by 1.5 floored', () {
      final r = DuelEngine.resolveRound(
        playerCard: card('p', Element.fire, 9, ability: Ability.doubleStrike),
        opponentCard: card('o', Element.fire, 4),
        config: cfg,
      );
      expect(r.winner, RoundWinner.player);
      expect(r.damage, 7); // (9-4)=5 -> 7.5 -> floor 7
    });

    test('elementalShift on opponent cancels player element bonus', () {
      // Player nature(5) vs opponent water(5) with elementalShift: no +3, so 5 vs 5 tie.
      final r = DuelEngine.resolveRound(
        playerCard: card('p', Element.nature, 5),
        opponentCard: card('o', Element.water, 5, ability: Ability.elementalShift),
        config: cfg,
      );
      expect(r.winner, RoundWinner.tie);
    });

    test('barracks bonus boosts the matching player element', () {
      const boosted = DuelConfig(barracksElement: Element.fire, barracksBonus: 3);
      // Player fire(5)+3 = 8 vs opponent fire(6).
      final r = DuelEngine.resolveRound(
        playerCard: card('p', Element.fire, 5),
        opponentCard: card('o', Element.fire, 6),
        config: boosted,
      );
      expect(r.winner, RoundWinner.player);
      expect(r.damage, 2);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/engine/duel_engine_test.dart`
Expected: FAIL (duel_engine.dart not found).

- [ ] **Step 3: Write minimal implementation**

`lib/engine/duel_engine.dart`:
```dart
import 'ability.dart';
import 'element.dart';
import 'game_card.dart';

class DuelConfig {
  final int startingCastleHp;
  final int handSize;
  final Element? barracksElement;
  final int barracksBonus;

  const DuelConfig({
    this.startingCastleHp = 30,
    this.handSize = 4,
    this.barracksElement,
    this.barracksBonus = 0,
  });
}

enum RoundWinner { player, opponent, tie }

class RoundResult {
  final RoundWinner winner;
  final int damage;
  final int playerEffectivePower;
  final int opponentEffectivePower;

  const RoundResult({
    required this.winner,
    required this.damage,
    required this.playerEffectivePower,
    required this.opponentEffectivePower,
  });
}

class DuelEngine {
  const DuelEngine._();

  static int effectivePower({
    required GameCard card,
    required GameCard opponentCard,
    required bool isPlayer,
    required DuelConfig config,
  }) {
    var power = card.power;
    final opponentShifts = opponentCard.ability == Ability.elementalShift;
    if (!opponentShifts && ElementRules.beats(card.element, opponentCard.element)) {
      power += kElementBonus;
    }
    if (isPlayer &&
        config.barracksElement != null &&
        card.element == config.barracksElement) {
      power += config.barracksBonus;
    }
    return power;
  }

  static RoundResult resolveRound({
    required GameCard playerCard,
    required GameCard opponentCard,
    required DuelConfig config,
  }) {
    final pPow = effectivePower(
        card: playerCard, opponentCard: opponentCard, isPlayer: true, config: config);
    final oPow = effectivePower(
        card: opponentCard, opponentCard: playerCard, isPlayer: false, config: config);

    if (pPow == oPow) {
      return RoundResult(
          winner: RoundWinner.tie,
          damage: 0,
          playerEffectivePower: pPow,
          opponentEffectivePower: oPow);
    }

    final playerWins = pPow > oPow;
    final winningCard = playerWins ? playerCard : opponentCard;
    final losingCard = playerWins ? opponentCard : playerCard;

    var damage = (pPow - oPow).abs();
    if (winningCard.ability == Ability.doubleStrike) {
      damage = (damage * 1.5).floor();
    }
    if (losingCard.ability == Ability.shield) {
      damage = 0;
    }

    return RoundResult(
      winner: playerWins ? RoundWinner.player : RoundWinner.opponent,
      damage: damage,
      playerEffectivePower: pPow,
      opponentEffectivePower: oPow,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/engine/duel_engine_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/duel_engine.dart test/engine/duel_engine_test.dart
git commit -m "feat: add duel round resolution with elements and abilities"
```

---

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

### Task 7: Kingdom — buildings, upgrades, economy

**Files:**
- Create: `lib/engine/kingdom.dart`
- Test: `test/engine/kingdom_test.dart`

**Interfaces:**
- Consumes: `Element`, `DuelConfig` (Tasks 2, 5).
- Produces:
  - `enum BuildingType { barracks, wall, mine }`
  - `class Kingdom { final int barracksLevel, wallLevel, mineLevel; final Element barracksElement; const Kingdom({...defaults all level 1, barracksElement = Element.fire}); Kingdom copyWith({...}); }`
  - Effect getters: `int get barracksBonus` (level→ +1/+2/+3), `int get wallHpBonus` (+5/+10/+15), `int get mineCrystalsPerWin` (+2/+4/+6).
  - `int levelOf(BuildingType)`, `Kingdom upgraded(BuildingType)` (caps at level 3).
  - `class KingdomEconomy { static int upgradeCost(BuildingType type, int currentLevel); static DuelConfig toDuelConfig(Kingdom k); }` — cost table `{1->10, 2->25}` (cost to go *from* that level), `toDuelConfig` maps wall/barracks bonuses into a `DuelConfig`.

- [ ] **Step 1: Write the failing test**

`test/engine/kingdom_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/element.dart';
import 'package:card_game/engine/kingdom.dart';

void main() {
  test('default kingdom is all level 1 with fire barracks', () {
    const k = Kingdom();
    expect(k.barracksLevel, 1);
    expect(k.wallLevel, 1);
    expect(k.mineLevel, 1);
    expect(k.barracksElement, Element.fire);
  });

  test('building effects scale with level', () {
    const k = Kingdom(barracksLevel: 1, wallLevel: 2, mineLevel: 3);
    expect(k.barracksBonus, 1);
    expect(k.wallHpBonus, 10);
    expect(k.mineCrystalsPerWin, 6);
  });

  test('upgrading increments level and caps at 3', () {
    var k = const Kingdom(barracksLevel: 2);
    k = k.upgraded(BuildingType.barracks);
    expect(k.barracksLevel, 3);
    k = k.upgraded(BuildingType.barracks);
    expect(k.barracksLevel, 3); // capped
  });

  test('upgrade cost table', () {
    expect(KingdomEconomy.upgradeCost(BuildingType.wall, 1), 10);
    expect(KingdomEconomy.upgradeCost(BuildingType.wall, 2), 25);
  });

  test('toDuelConfig maps wall hp and barracks bonus', () {
    const k = Kingdom(barracksLevel: 3, wallLevel: 2, barracksElement: Element.water);
    final cfg = KingdomEconomy.toDuelConfig(k);
    expect(cfg.startingCastleHp, 40); // 30 base + 10 wall
    expect(cfg.barracksElement, Element.water);
    expect(cfg.barracksBonus, 3);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/engine/kingdom_test.dart`
Expected: FAIL (kingdom.dart not found).

- [ ] **Step 3: Write minimal implementation**

`lib/engine/kingdom.dart`:
```dart
import 'duel_engine.dart';
import 'element.dart';

enum BuildingType { barracks, wall, mine }

class Kingdom {
  final int barracksLevel;
  final int wallLevel;
  final int mineLevel;
  final Element barracksElement;

  const Kingdom({
    this.barracksLevel = 1,
    this.wallLevel = 1,
    this.mineLevel = 1,
    this.barracksElement = Element.fire,
  });

  int get barracksBonus => barracksLevel; // 1/2/3
  int get wallHpBonus => wallLevel * 5; // 5/10/15
  int get mineCrystalsPerWin => mineLevel * 2; // 2/4/6

  int levelOf(BuildingType type) {
    switch (type) {
      case BuildingType.barracks:
        return barracksLevel;
      case BuildingType.wall:
        return wallLevel;
      case BuildingType.mine:
        return mineLevel;
    }
  }

  Kingdom upgraded(BuildingType type) {
    int cap(int level) => level >= 3 ? 3 : level + 1;
    switch (type) {
      case BuildingType.barracks:
        return copyWith(barracksLevel: cap(barracksLevel));
      case BuildingType.wall:
        return copyWith(wallLevel: cap(wallLevel));
      case BuildingType.mine:
        return copyWith(mineLevel: cap(mineLevel));
    }
  }

  Kingdom copyWith({
    int? barracksLevel,
    int? wallLevel,
    int? mineLevel,
    Element? barracksElement,
  }) {
    return Kingdom(
      barracksLevel: barracksLevel ?? this.barracksLevel,
      wallLevel: wallLevel ?? this.wallLevel,
      mineLevel: mineLevel ?? this.mineLevel,
      barracksElement: barracksElement ?? this.barracksElement,
    );
  }
}

class KingdomEconomy {
  const KingdomEconomy._();

  /// Crystal cost to upgrade *from* [currentLevel]. Level 3 is the cap.
  static int upgradeCost(BuildingType type, int currentLevel) {
    switch (currentLevel) {
      case 1:
        return 10;
      case 2:
        return 25;
      default:
        return 0; // already max
    }
  }

  static DuelConfig toDuelConfig(Kingdom k) {
    return DuelConfig(
      startingCastleHp: 30 + k.wallHpBonus,
      barracksElement: k.barracksElement,
      barracksBonus: k.barracksBonus,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/engine/kingdom_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/kingdom.dart test/engine/kingdom_test.dart
git commit -m "feat: add kingdom buildings, upgrades, and economy"
```

---

### Task 8: Card data — JSON asset and repository

**Files:**
- Create: `assets/cards.json`, `lib/data/card_repository.dart`
- Test: `test/data/card_repository_test.dart`

**Interfaces:**
- Consumes: `GameCard`, `Element`, `Ability`, `Rarity` (Tasks 2–3).
- Produces:
  - `class CardRepository { static GameCard fromJson(Map<String, dynamic> json); static List<GameCard> parseAll(String jsonString); Future<List<GameCard>> loadFromAsset(AssetBundle bundle); }`
  - JSON shape per card: `{"id","name","element":"fire|nature|water","power":int,"rarity":"common|rare|trump","ability":"elementalShift|doubleStrike|shield"|null}`.

- [ ] **Step 1: Create `assets/cards.json` with the slice content**

```json
[
  {"id":"fire_deer","name":"Горячий Олень","element":"fire","power":4,"rarity":"common","ability":null},
  {"id":"fire_rooster","name":"Желанный Петушок","element":"fire","power":6,"rarity":"common","ability":null},
  {"id":"fire_pie","name":"Горелый Пирожок","element":"fire","power":3,"rarity":"common","ability":null},
  {"id":"fire_phoenix_pearl","name":"Перл Феникса","element":"fire","power":7,"rarity":"common","ability":null},
  {"id":"nature_zucchini","name":"Боевой Кабачок","element":"nature","power":5,"rarity":"common","ability":null},
  {"id":"nature_forester","name":"Пьяный Лесник","element":"nature","power":4,"rarity":"common","ability":null},
  {"id":"nature_mushroom","name":"Гриб-Качок","element":"nature","power":6,"rarity":"common","ability":null},
  {"id":"nature_hedgehog","name":"Боевой Ёж","element":"nature","power":3,"rarity":"common","ability":null},
  {"id":"water_jellyfish","name":"Сердитая Медуза","element":"water","power":5,"rarity":"common","ability":null},
  {"id":"water_puddle","name":"Капитан Лужа","element":"water","power":4,"rarity":"common","ability":null},
  {"id":"water_beaver","name":"Бобёр-Сантехник","element":"water","power":6,"rarity":"common","ability":null},
  {"id":"water_dumpling","name":"Ледяной Пельмень","element":"water","power":7,"rarity":"common","ability":null},
  {"id":"trump_pumpkin_king","name":"Король-Тыква","element":"nature","power":9,"rarity":"trump","ability":"doubleStrike"},
  {"id":"trump_lava_cat","name":"Лавовый Котик","element":"fire","power":8,"rarity":"trump","ability":"elementalShift"},
  {"id":"trump_frost_granny","name":"Морозная Бабуля","element":"water","power":9,"rarity":"trump","ability":"shield"},
  {"id":"trump_starter_drake","name":"Дракоша-Стартер","element":"fire","power":8,"rarity":"trump","ability":"doubleStrike"}
]
```

- [ ] **Step 2: Write the failing test**

`test/data/card_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/data/card_repository.dart';
import 'package:card_game/engine/ability.dart';
import 'package:card_game/engine/element.dart';

void main() {
  test('fromJson parses a common card', () {
    final card = CardRepository.fromJson({
      'id': 'fire_deer',
      'name': 'Горячий Олень',
      'element': 'fire',
      'power': 4,
      'rarity': 'common',
      'ability': null,
    });
    expect(card.id, 'fire_deer');
    expect(card.element, Element.fire);
    expect(card.power, 4);
    expect(card.rarity, Rarity.common);
    expect(card.ability, isNull);
  });

  test('fromJson parses a trump card with an ability', () {
    final card = CardRepository.fromJson({
      'id': 'trump_pumpkin_king',
      'name': 'Король-Тыква',
      'element': 'nature',
      'power': 9,
      'rarity': 'trump',
      'ability': 'doubleStrike',
    });
    expect(card.rarity, Rarity.trump);
    expect(card.ability, Ability.doubleStrike);
  });

  test('parseAll reads a list', () {
    const json = '[{"id":"a","name":"A","element":"water","power":5,"rarity":"common","ability":null}]';
    final cards = CardRepository.parseAll(json);
    expect(cards, hasLength(1));
    expect(cards.first.element, Element.water);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/data/card_repository_test.dart`
Expected: FAIL (card_repository.dart not found).

- [ ] **Step 4: Write minimal implementation**

`lib/data/card_repository.dart`:
```dart
import 'dart:convert';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import '../engine/ability.dart';
import '../engine/element.dart';
import '../engine/game_card.dart';

class CardRepository {
  const CardRepository._();

  static Element _element(String s) => Element.values.firstWhere((e) => e.name == s);
  static Rarity _rarity(String s) => Rarity.values.firstWhere((e) => e.name == s);
  static Ability? _ability(String? s) =>
      s == null ? null : Ability.values.firstWhere((e) => e.name == s);

  static GameCard fromJson(Map<String, dynamic> json) {
    return GameCard(
      id: json['id'] as String,
      name: json['name'] as String,
      element: _element(json['element'] as String),
      power: json['power'] as int,
      rarity: _rarity(json['rarity'] as String),
      ability: _ability(json['ability'] as String?),
    );
  }

  static List<GameCard> parseAll(String jsonString) {
    final list = jsonDecode(jsonString) as List<dynamic>;
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<GameCard>> loadFromAsset(
      {AssetBundle? bundle, String path = 'assets/cards.json'}) async {
    final b = bundle ?? rootBundle;
    return parseAll(await b.loadString(path));
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/data/card_repository_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add assets/cards.json lib/data/card_repository.dart test/data/card_repository_test.dart
git commit -m "feat: add card json asset and repository parser"
```

---

### Task 9: Save state model and local persistence

**Files:**
- Create: `lib/models/save_state.dart`, `lib/models/save_store.dart`
- Test: `test/models/save_state_test.dart`

**Interfaces:**
- Consumes: `Kingdom`, `Element`, `BuildingType` (Task 7).
- Produces:
  - `class SaveState { final int crystals; final Kingdom kingdom; final Set<String> ownedCardIds; final int unlockedNodeIndex; const SaveState({...}); SaveState copyWith({...}); Map<String,dynamic> toJson(); factory SaveState.fromJson(Map<String,dynamic>); static SaveState initial(); }`
  - `initial()`: crystals 0, default `Kingdom`, owns the 12 common card ids + `trump_starter_drake`, `unlockedNodeIndex = 0`.
  - `class SaveStore { Future<SaveState> load(); Future<void> save(SaveState state); }` backed by `shared_preferences` under key `save_v1` (stores `jsonEncode(state.toJson())`); `load()` returns `SaveState.initial()` when absent.

- [ ] **Step 1: Write the failing test**

`test/models/save_state_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/element.dart';
import 'package:card_game/engine/kingdom.dart';
import 'package:card_game/models/save_state.dart';

void main() {
  test('initial state has starter content', () {
    final s = SaveState.initial();
    expect(s.crystals, 0);
    expect(s.unlockedNodeIndex, 0);
    expect(s.ownedCardIds, contains('trump_starter_drake'));
    expect(s.ownedCardIds.length, greaterThanOrEqualTo(13));
  });

  test('json round-trip preserves all fields', () {
    final s = SaveState(
      crystals: 42,
      kingdom: const Kingdom(barracksLevel: 2, wallLevel: 3, mineLevel: 1, barracksElement: Element.water),
      ownedCardIds: {'a', 'b'},
      unlockedNodeIndex: 2,
    );
    final restored = SaveState.fromJson(s.toJson());
    expect(restored.crystals, 42);
    expect(restored.kingdom.wallLevel, 3);
    expect(restored.kingdom.barracksElement, Element.water);
    expect(restored.ownedCardIds, {'a', 'b'});
    expect(restored.unlockedNodeIndex, 2);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/save_state_test.dart`
Expected: FAIL (save_state.dart not found).

- [ ] **Step 3: Write `lib/models/save_state.dart`**

```dart
import '../engine/element.dart';
import '../engine/kingdom.dart';

const _starterCommonIds = [
  'fire_deer', 'fire_rooster', 'fire_pie', 'fire_phoenix_pearl',
  'nature_zucchini', 'nature_forester', 'nature_mushroom', 'nature_hedgehog',
  'water_jellyfish', 'water_puddle', 'water_beaver', 'water_dumpling',
];

class SaveState {
  final int crystals;
  final Kingdom kingdom;
  final Set<String> ownedCardIds;
  final int unlockedNodeIndex;

  const SaveState({
    required this.crystals,
    required this.kingdom,
    required this.ownedCardIds,
    required this.unlockedNodeIndex,
  });

  static SaveState initial() => SaveState(
        crystals: 0,
        kingdom: const Kingdom(),
        ownedCardIds: {..._starterCommonIds, 'trump_starter_drake'},
        unlockedNodeIndex: 0,
      );

  SaveState copyWith({
    int? crystals,
    Kingdom? kingdom,
    Set<String>? ownedCardIds,
    int? unlockedNodeIndex,
  }) {
    return SaveState(
      crystals: crystals ?? this.crystals,
      kingdom: kingdom ?? this.kingdom,
      ownedCardIds: ownedCardIds ?? this.ownedCardIds,
      unlockedNodeIndex: unlockedNodeIndex ?? this.unlockedNodeIndex,
    );
  }

  Map<String, dynamic> toJson() => {
        'crystals': crystals,
        'kingdom': {
          'barracksLevel': kingdom.barracksLevel,
          'wallLevel': kingdom.wallLevel,
          'mineLevel': kingdom.mineLevel,
          'barracksElement': kingdom.barracksElement.name,
        },
        'ownedCardIds': ownedCardIds.toList(),
        'unlockedNodeIndex': unlockedNodeIndex,
      };

  factory SaveState.fromJson(Map<String, dynamic> json) {
    final k = json['kingdom'] as Map<String, dynamic>;
    return SaveState(
      crystals: json['crystals'] as int,
      kingdom: Kingdom(
        barracksLevel: k['barracksLevel'] as int,
        wallLevel: k['wallLevel'] as int,
        mineLevel: k['mineLevel'] as int,
        barracksElement:
            Element.values.firstWhere((e) => e.name == k['barracksElement']),
      ),
      ownedCardIds: (json['ownedCardIds'] as List<dynamic>).cast<String>().toSet(),
      unlockedNodeIndex: json['unlockedNodeIndex'] as int,
    );
  }
}
```

- [ ] **Step 4: Run the round-trip test (no persistence yet)**

Run: `flutter test test/models/save_state_test.dart`
Expected: PASS.

- [ ] **Step 5: Write `lib/models/save_store.dart`**

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'save_state.dart';

class SaveStore {
  static const _key = 'save_v1';

  Future<SaveState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return SaveState.initial();
    return SaveState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(SaveState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
}
```

- [ ] **Step 6: Add a persistence test using the in-memory prefs backend**

Append to `test/models/save_state_test.dart`:
```dart
// Add these imports at the top of the file:
// import 'package:card_game/models/save_store.dart';
// import 'package:shared_preferences/shared_preferences.dart';

void persistenceTests() {
  test('SaveStore returns initial when nothing stored', () async {
    SharedPreferences.setMockInitialValues({});
    final state = await SaveStore().load();
    expect(state.crystals, 0);
  });

  test('SaveStore persists and reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SaveStore();
    await store.save(SaveState.initial().copyWith(crystals: 99));
    final reloaded = await store.load();
    expect(reloaded.crystals, 99);
  });
}
```
Then call `persistenceTests();` at the end of `main()` in that file (and add the two imports shown).

- [ ] **Step 7: Run all model tests**

Run: `flutter test test/models/save_state_test.dart`
Expected: PASS (round-trip + 2 persistence tests).

- [ ] **Step 8: Commit**

```bash
git add lib/models/save_state.dart lib/models/save_store.dart test/models/save_state_test.dart
git commit -m "feat: add save state model and shared_preferences persistence"
```

---

### Task 10: Duel session — full-match orchestration

**Files:**
- Create: `lib/engine/duel_session.dart`
- Test: `test/engine/duel_session_test.dart`

**Interfaces:**
- Consumes: `Deck`, `GameCard`, `DuelConfig`, `DuelEngine`, `RoundResult`, `RoundWinner`, `AiController` (Tasks 4–6).
- Produces:
  - `enum DuelOutcome { playerWon, opponentWon, ongoing }`
  - `class DuelSession { DuelSession({required Deck playerDeck, required Deck opponentDeck, required DuelConfig playerConfig, required DuelConfig opponentConfig, required AiController ai, required Random random}); int playerCastleHp; int opponentCastleHp; List<GameCard> get playerHand; List<GameCard> get opponentHand; void start(); RoundResult playPlayerCard(GameCard card); DuelOutcome get outcome; }`
  - `start()` shuffles both decks and draws opening hands. `playPlayerCard` makes the AI choose, resolves the round via `DuelEngine` (using each side's own config), applies damage to the correct castle, refills both hands, and returns the `RoundResult`. When both decks and hands are exhausted with both castles alive, higher HP wins (tie → playerWon, player-favored to keep the slice decisive).

- [ ] **Step 1: Write the failing test**

`test/engine/duel_session_test.dart`:
```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/ai_controller.dart';
import 'package:card_game/engine/deck.dart';
import 'package:card_game/engine/duel_engine.dart';
import 'package:card_game/engine/duel_session.dart';
import 'package:card_game/engine/element.dart';
import 'package:card_game/engine/game_card.dart';

GameCard c(String id, Element e, int p) =>
    GameCard(id: id, name: id, element: e, power: p, rarity: Rarity.common);

DuelSession makeSession({required List<GameCard> player, required List<GameCard> opp}) {
  return DuelSession(
    playerDeck: Deck(player),
    opponentDeck: Deck(opp),
    playerConfig: const DuelConfig(startingCastleHp: 10),
    opponentConfig: const DuelConfig(startingCastleHp: 10),
    ai: AiController(),
    random: Random(1),
  )..start();
}

void main() {
  test('start deals opening hands and sets castle hp', () {
    final s = makeSession(
      player: [c('p1', Element.fire, 5), c('p2', Element.fire, 5), c('p3', Element.fire, 5), c('p4', Element.fire, 5)],
      opp: [c('o1', Element.fire, 1), c('o2', Element.fire, 1), c('o3', Element.fire, 1), c('o4', Element.fire, 1)],
    );
    expect(s.playerHand.length, 4);
    expect(s.opponentHand.length, 4);
    expect(s.playerCastleHp, 10);
    expect(s.opponentCastleHp, 10);
  });

  test('winning a round damages the opponent castle', () {
    final s = makeSession(
      player: [c('p1', Element.fire, 9), c('p2', Element.fire, 9), c('p3', Element.fire, 9), c('p4', Element.fire, 9)],
      opp: [c('o1', Element.fire, 1), c('o2', Element.fire, 1), c('o3', Element.fire, 1), c('o4', Element.fire, 1)],
    );
    final card = s.playerHand.first;
    final result = s.playPlayerCard(card);
    expect(result.winner, RoundWinner.player);
    expect(s.opponentCastleHp, lessThan(10));
  });

  test('reducing opponent castle to zero yields playerWon', () {
    final s = makeSession(
      player: [c('p1', Element.fire, 9), c('p2', Element.fire, 9), c('p3', Element.fire, 9), c('p4', Element.fire, 9)],
      opp: [c('o1', Element.fire, 1), c('o2', Element.fire, 1), c('o3', Element.fire, 1), c('o4', Element.fire, 1)],
    );
    var guard = 0;
    while (s.outcome == DuelOutcome.ongoing && guard++ < 20) {
      s.playPlayerCard(s.playerHand.first);
    }
    expect(s.outcome, DuelOutcome.playerWon);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/engine/duel_session_test.dart`
Expected: FAIL (duel_session.dart not found).

- [ ] **Step 3: Write minimal implementation**

`lib/engine/duel_session.dart`:
```dart
import 'dart:math';
import 'ai_controller.dart';
import 'deck.dart';
import 'duel_engine.dart';
import 'game_card.dart';

enum DuelOutcome { playerWon, opponentWon, ongoing }

class DuelSession {
  final Deck _playerDeck;
  final Deck _opponentDeck;
  final DuelConfig playerConfig;
  final DuelConfig opponentConfig;
  final AiController ai;
  final Random random;

  final List<GameCard> _playerHand = [];
  final List<GameCard> _opponentHand = [];

  late int playerCastleHp;
  late int opponentCastleHp;

  DuelSession({
    required Deck playerDeck,
    required Deck opponentDeck,
    required this.playerConfig,
    required this.opponentConfig,
    required this.ai,
    required this.random,
  })  : _playerDeck = playerDeck,
        _opponentDeck = opponentDeck;

  List<GameCard> get playerHand => List.unmodifiable(_playerHand);
  List<GameCard> get opponentHand => List.unmodifiable(_opponentHand);

  void start() {
    _playerDeck.shuffle(random);
    _opponentDeck.shuffle(random);
    playerCastleHp = playerConfig.startingCastleHp;
    opponentCastleHp = opponentConfig.startingCastleHp;
    _refill();
  }

  void _refill() {
    _playerHand.addAll(_playerDeck.drawUpTo(playerConfig.handSize - _playerHand.length));
    _opponentHand
        .addAll(_opponentDeck.drawUpTo(opponentConfig.handSize - _opponentHand.length));
  }

  RoundResult playPlayerCard(GameCard card) {
    _playerHand.remove(card);
    final oppCard = ai.chooseCard(hand: _opponentHand, config: opponentConfig);
    _opponentHand.remove(oppCard);

    // Resolve from each side's perspective so both configs apply their own
    // barracks bonus. Damage attribution uses the player-perspective winner.
    final playerView = DuelEngine.resolveRound(
        playerCard: card, opponentCard: oppCard, config: playerConfig);
    final oppView = DuelEngine.resolveRound(
        playerCard: oppCard, opponentCard: card, config: opponentConfig);

    if (playerView.winner == RoundWinner.player) {
      opponentCastleHp -= playerView.damage;
    } else if (oppView.winner == RoundWinner.player) {
      // opponent's own perspective: their card won
      playerCastleHp -= oppView.damage;
    }
    _refill();
    return playerView;
  }

  DuelOutcome get outcome {
    if (opponentCastleHp <= 0) return DuelOutcome.playerWon;
    if (playerCastleHp <= 0) return DuelOutcome.opponentWon;
    final exhausted = _playerHand.isEmpty &&
        _opponentHand.isEmpty &&
        _playerDeck.isEmpty &&
        _opponentDeck.isEmpty;
    if (exhausted) {
      return playerCastleHp >= opponentCastleHp
          ? DuelOutcome.playerWon
          : DuelOutcome.opponentWon;
    }
    return DuelOutcome.ongoing;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/engine/duel_session_test.dart`
Expected: PASS.

- [ ] **Step 5: Run the full engine suite**

Run: `flutter test test/engine`
Expected: PASS (all engine tests).

- [ ] **Step 6: Commit**

```bash
git add lib/engine/duel_session.dart test/engine/duel_session_test.dart
git commit -m "feat: add full-match duel session orchestration"
```

---

### Task 11: Riverpod providers and app shell

**Files:**
- Create: `lib/state/providers.dart`, `lib/ui/app.dart`, `lib/main.dart` (replace generated)
- Test: `test/ui/app_smoke_test.dart`

**Interfaces:**
- Consumes: `SaveState`, `SaveStore`, `CardRepository`, `GameCard` (Tasks 8–9).
- Produces:
  - `final saveStoreProvider = Provider<SaveStore>(...)`
  - `final cardsProvider = FutureProvider<List<GameCard>>(...)` (loads asset)
  - `final saveStateProvider = StateNotifierProvider<SaveController, SaveState>(...)`
  - `class SaveController extends StateNotifier<SaveState> { SaveController(this._store, SaveState initial); Future<void> hydrate(); void addCrystals(int n); bool tryUpgrade(BuildingType type); void grantCard(String id); void unlockNextNode(); }` — every mutator persists via `_store.save(state)`.
  - `class CardGameApp extends StatelessWidget` (the `MaterialApp` root, `home: WorldMapScreen`).

- [ ] **Step 1: Write `lib/state/providers.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/card_repository.dart';
import '../engine/game_card.dart';
import '../engine/kingdom.dart';
import '../models/save_state.dart';
import '../models/save_store.dart';

final saveStoreProvider = Provider<SaveStore>((ref) => SaveStore());

final cardsProvider = FutureProvider<List<GameCard>>((ref) async {
  return CardRepository.loadFromAsset();
});

final saveStateProvider =
    StateNotifierProvider<SaveController, SaveState>((ref) {
  return SaveController(ref.read(saveStoreProvider), SaveState.initial());
});

class SaveController extends StateNotifier<SaveState> {
  final SaveStore _store;
  SaveController(this._store, SaveState initial) : super(initial);

  Future<void> hydrate() async {
    state = await _store.load();
  }

  void _commit(SaveState next) {
    state = next;
    _store.save(next);
  }

  void addCrystals(int n) => _commit(state.copyWith(crystals: state.crystals + n));

  bool tryUpgrade(BuildingType type) {
    final level = state.kingdom.levelOf(type);
    if (level >= 3) return false;
    final cost = KingdomEconomy.upgradeCost(type, level);
    if (state.crystals < cost) return false;
    _commit(state.copyWith(
      crystals: state.crystals - cost,
      kingdom: state.kingdom.upgraded(type),
    ));
    return true;
  }

  void grantCard(String id) {
    if (state.ownedCardIds.contains(id)) return;
    _commit(state.copyWith(ownedCardIds: {...state.ownedCardIds, id}));
  }

  void unlockNextNode() =>
      _commit(state.copyWith(unlockedNodeIndex: state.unlockedNodeIndex + 1));
}
```

- [ ] **Step 2: Write `lib/ui/app.dart`** (imports `WorldMapScreen` from Task 12 — create that file before running)

```dart
import 'package:flutter/material.dart';
import 'world_map_screen.dart';

class CardGameApp extends StatelessWidget {
  const CardGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Карточное Королевство',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const WorldMapScreen(),
    );
  }
}
```

- [ ] **Step 3: Replace `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/providers.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(saveStateProvider.notifier).hydrate();
  runApp(UncontrolledProviderScope(container: container, child: const CardGameApp()));
}
```

- [ ] **Step 4: Write a smoke test** (after Task 12's screen exists)

`test/ui/app_smoke_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_game/ui/app.dart';

void main() {
  testWidgets('app boots to the world map', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: CardGameApp()));
    await tester.pumpAndSettle();
    expect(find.text('Карта мира'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Run the smoke test** (after Task 12)

Run: `flutter test test/ui/app_smoke_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/state/providers.dart lib/ui/app.dart lib/main.dart test/ui/app_smoke_test.dart
git commit -m "feat: add riverpod providers and app shell"
```

> Note: Steps 4–5 depend on `WorldMapScreen` (Task 12). If executing strictly in order, write Task 12's screen first, then run these. Commit this task after Task 12 compiles.

---

### Task 12: World map screen (linear node chain + boss)

**Files:**
- Create: `lib/ui/world_map_screen.dart`, `lib/ui/duel_setup.dart`
- Test: `test/ui/world_map_test.dart`

**Interfaces:**
- Consumes: `saveStateProvider`, `cardsProvider`, `BuildingType` (Task 11), engine types.
- Produces:
  - `class MapNode { final int index; final String title; final List<String> opponentCardIds; final DuelConfig opponentConfig; final bool isBoss; final String? rewardTrumpId; const MapNode(...); }`
  - `const List<MapNode> kSliceNodes` — 4 nodes: `Тренировка`, `Противник 1`, `Противник 2`, `БОСС` (boss has `rewardTrumpId: 'trump_pumpkin_king'`).
  - `class WorldMapScreen extends ConsumerWidget` — `AppBar('Карта мира')`, a column of node buttons; node `i` is enabled iff `i <= unlockedNodeIndex`; tapping a node pushes the duel screen with that node's setup.

- [ ] **Step 1: Write `lib/ui/duel_setup.dart`** (shared node data + duel construction)

```dart
import 'dart:math';
import '../engine/ai_controller.dart';
import '../engine/deck.dart';
import '../engine/duel_engine.dart';
import '../engine/duel_session.dart';
import '../engine/game_card.dart';
import '../engine/kingdom.dart';
import '../models/save_state.dart';

class MapNode {
  final int index;
  final String title;
  final List<String> opponentCardIds;
  final DuelConfig opponentConfig;
  final bool isBoss;
  final String? rewardTrumpId;

  const MapNode({
    required this.index,
    required this.title,
    required this.opponentCardIds,
    required this.opponentConfig,
    this.isBoss = false,
    this.rewardTrumpId,
  });
}

const kSliceNodes = <MapNode>[
  MapNode(
    index: 0,
    title: 'Тренировка',
    opponentCardIds: ['fire_pie', 'nature_hedgehog', 'water_puddle', 'fire_deer'],
    opponentConfig: DuelConfig(startingCastleHp: 20),
  ),
  MapNode(
    index: 1,
    title: 'Противник 1',
    opponentCardIds: ['fire_rooster', 'nature_zucchini', 'water_jellyfish', 'nature_mushroom'],
    opponentConfig: DuelConfig(startingCastleHp: 28),
  ),
  MapNode(
    index: 2,
    title: 'Противник 2',
    opponentCardIds: ['water_beaver', 'fire_phoenix_pearl', 'nature_mushroom', 'water_dumpling'],
    opponentConfig: DuelConfig(startingCastleHp: 34),
  ),
  MapNode(
    index: 3,
    title: 'БОСС: Тыквенный Лорд',
    opponentCardIds: ['water_dumpling', 'fire_phoenix_pearl', 'water_beaver', 'trump_lava_cat'],
    opponentConfig: DuelConfig(startingCastleHp: 40),
    isBoss: true,
    rewardTrumpId: 'trump_pumpkin_king',
  ),
];

/// Builds a 12-card deck from owned cards, padding by repeating owned ids so a
/// thin starter collection still fills a deck.
List<GameCard> buildPlayerDeck(SaveState save, List<GameCard> allCards) {
  final owned = allCards.where((c) => save.ownedCardIds.contains(c.id)).toList();
  final deck = <GameCard>[];
  var i = 0;
  while (deck.length < kDeckSize && owned.isNotEmpty) {
    deck.add(owned[i % owned.length]);
    i++;
  }
  return deck;
}

DuelSession buildSession({
  required SaveState save,
  required List<GameCard> allCards,
  required MapNode node,
  required Random random,
}) {
  final byId = {for (final c in allCards) c.id: c};
  final playerCards = buildPlayerDeck(save, allCards);
  final oppCards = node.opponentCardIds.map((id) => byId[id]!).toList();
  return DuelSession(
    playerDeck: Deck(playerCards),
    opponentDeck: Deck(oppCards),
    playerConfig: KingdomEconomy.toDuelConfig(save.kingdom),
    opponentConfig: node.opponentConfig,
    ai: AiController(),
    random: random,
  )..start();
}
```

- [ ] **Step 2: Write the failing widget test**

`test/ui/world_map_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_game/ui/world_map_screen.dart';

void main() {
  testWidgets('world map shows nodes and locks future ones', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: WorldMapScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Карта мира'), findsOneWidget);
    expect(find.text('Тренировка'), findsOneWidget);
    expect(find.textContaining('БОСС'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/ui/world_map_test.dart`
Expected: FAIL (world_map_screen.dart not found).

- [ ] **Step 4: Write `lib/ui/world_map_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import 'duel_setup.dart';
import 'duel_screen.dart';
import 'kingdom_screen.dart';

class WorldMapScreen extends ConsumerWidget {
  const WorldMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(saveStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карта мира'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: Text('💎 ${save.crystals}')),
          ),
          IconButton(
            icon: const Icon(Icons.castle),
            tooltip: 'Королевство',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const KingdomScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final node in kSliceNodes)
            Card(
              child: ListTile(
                leading: Icon(node.isBoss ? Icons.whatshot : Icons.flag),
                title: Text(node.title),
                trailing: node.index <= save.unlockedNodeIndex
                    ? const Icon(Icons.play_arrow)
                    : const Icon(Icons.lock),
                enabled: node.index <= save.unlockedNodeIndex,
                onTap: node.index <= save.unlockedNodeIndex
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => DuelScreen(node: node)),
                        )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run test** (requires `DuelScreen` and `KingdomScreen` to exist — create stub files first if executing strictly in order, or implement Tasks 13–14 then return)

Run: `flutter test test/ui/world_map_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/world_map_screen.dart lib/ui/duel_setup.dart test/ui/world_map_test.dart
git commit -m "feat: add world map screen and duel setup"
```

---

### Task 13: Kingdom screen (buildings + upgrades)

**Files:**
- Create: `lib/ui/kingdom_screen.dart`
- Test: `test/ui/kingdom_screen_test.dart`

**Interfaces:**
- Consumes: `saveStateProvider`, `SaveController.tryUpgrade`, `BuildingType`, `KingdomEconomy` (Tasks 7, 11).
- Produces: `class KingdomScreen extends ConsumerWidget` — lists the three buildings with level, effect text, cost, and an «Улучшить» button calling `tryUpgrade`; disabled at level 3 or when crystals are insufficient.

- [ ] **Step 1: Write the failing widget test**

`test/ui/kingdom_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_game/ui/kingdom_screen.dart';

void main() {
  testWidgets('kingdom screen lists three buildings', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: KingdomScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Казарма'), findsOneWidget);
    expect(find.text('Стена'), findsOneWidget);
    expect(find.text('Шахта'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/kingdom_screen_test.dart`
Expected: FAIL (kingdom_screen.dart not found).

- [ ] **Step 3: Write `lib/ui/kingdom_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/kingdom.dart';
import '../state/providers.dart';

class KingdomScreen extends ConsumerWidget {
  const KingdomScreen({super.key});

  static const _titles = {
    BuildingType.barracks: 'Казарма',
    BuildingType.wall: 'Стена',
    BuildingType.mine: 'Шахта',
  };

  String _effect(BuildingType type, Kingdom k) {
    switch (type) {
      case BuildingType.barracks:
        return '+${k.barracksBonus} к силе карт стихии';
      case BuildingType.wall:
        return '+${k.wallHpBonus} ХП замка';
      case BuildingType.mine:
        return '+${k.mineCrystalsPerWin} 💎 за победу';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(saveStateProvider);
    final controller = ref.read(saveStateProvider.notifier);
    final k = save.kingdom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Королевство'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: Text('💎 ${save.crystals}')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final type in BuildingType.values)
            Card(
              child: ListTile(
                title: Text(_titles[type]!),
                subtitle: Text('Ур. ${k.levelOf(type)} — ${_effect(type, k)}'),
                trailing: k.levelOf(type) >= 3
                    ? const Text('МАКС')
                    : FilledButton(
                        onPressed: save.crystals >=
                                KingdomEconomy.upgradeCost(type, k.levelOf(type))
                            ? () => controller.tryUpgrade(type)
                            : null,
                        child: Text(
                            'Улучшить (${KingdomEconomy.upgradeCost(type, k.levelOf(type))}💎)'),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/kingdom_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/kingdom_screen.dart test/ui/kingdom_screen_test.dart
git commit -m "feat: add kingdom screen with building upgrades"
```

---

### Task 14: Duel screen and reward flow

**Files:**
- Create: `lib/ui/duel_screen.dart`, `lib/ui/reward_screen.dart`
- Test: `test/ui/duel_screen_test.dart`

**Interfaces:**
- Consumes: `DuelSession`, `MapNode`, `buildSession`, `saveStateProvider`, `SaveController` (Tasks 10–12), `RoundResult`.
- Produces:
  - `class DuelScreen extends ConsumerStatefulWidget { final MapNode node; }` — builds a `DuelSession` in `initState` (seeded `Random` from `node.index` for determinism in tests), shows both castle HP bars, the player hand as tappable cards, the last round result; on `DuelOutcome` resolved, navigates to `RewardScreen`.
  - On player win: grant crystals (`5 + kingdom.mineCrystalsPerWin`), if node not yet cleared `unlockNextNode()`, on boss grant `rewardTrumpId`, ~30% chest roll (seeded) grants `trump_frost_granny`.
  - `class RewardScreen extends StatelessWidget { final bool won; final int crystalsEarned; final String? trumpGranted; }` — summary + «В королевство» button popping to the map.

- [ ] **Step 1: Write the failing widget test**

`test/ui/duel_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_game/ui/duel_screen.dart';
import 'package:card_game/ui/duel_setup.dart';

void main() {
  testWidgets('duel screen renders castle hp and a playable hand', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: DuelScreen(node: kSliceNodes.first)),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Замок'), findsWidgets);
    // Hand cards are rendered as InkWell-wrapped tiles; at least one exists.
    expect(find.byType(Card), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/duel_screen_test.dart`
Expected: FAIL (duel_screen.dart not found).

- [ ] **Step 3: Write `lib/ui/reward_screen.dart`**

```dart
import 'package:flutter/material.dart';

class RewardScreen extends StatelessWidget {
  final bool won;
  final int crystalsEarned;
  final String? trumpGranted;

  const RewardScreen({
    super.key,
    required this.won,
    required this.crystalsEarned,
    this.trumpGranted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(won ? 'Победа!' : 'Поражение')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(won ? '🎉 Замок врага пал!' : '💥 Твой замок разрушен',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            if (won) Text('Получено: 💎 $crystalsEarned'),
            if (trumpGranted != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('🏆 Новый козырь: $trumpGranted'),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context)
                  .popUntil((route) => route.isFirst),
              child: const Text('В королевство'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Write `lib/ui/duel_screen.dart`**

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/duel_session.dart';
import '../engine/game_card.dart';
import '../state/providers.dart';
import 'duel_setup.dart';
import 'reward_screen.dart';

class DuelScreen extends ConsumerStatefulWidget {
  final MapNode node;
  const DuelScreen({super.key, required this.node});

  @override
  ConsumerState<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends ConsumerState<DuelScreen> {
  DuelSession? _session;
  String _log = 'Выбери карту';
  bool _resolved = false;

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(cardsProvider);
    final save = ref.watch(saveStateProvider);

    return cardsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Ошибка: $e'))),
      data: (allCards) {
        final session = _session ??= buildSession(
          save: save,
          allCards: allCards,
          node: widget.node,
          random: Random(widget.node.index + 1),
        );
        return Scaffold(
          appBar: AppBar(title: Text(widget.node.title)),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Замок врага: ${session.opponentCastleHp}'),
                Text('Твой Замок: ${session.playerCastleHp}'),
                const SizedBox(height: 12),
                Text(_log),
                const Spacer(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final card in session.playerHand)
                      Card(
                        child: InkWell(
                          onTap: _resolved ? null : () => _play(card, session),
                          child: SizedBox(
                            width: 80,
                            height: 110,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_elementEmoji(card),
                                      style: const TextStyle(fontSize: 22)),
                                  Text(card.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 10)),
                                  Text('${card.power}',
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _elementEmoji(GameCard c) =>
      {'fire': '🔥', 'nature': '🌿', 'water': '💧'}[c.element.name]!;

  void _play(GameCard card, DuelSession session) {
    final result = session.playPlayerCard(card);
    setState(() {
      _log = 'Раунд: ${result.playerEffectivePower} против '
          '${result.opponentEffectivePower}, урон ${result.damage}';
    });
    final outcome = session.outcome;
    if (outcome != DuelOutcome.ongoing && !_resolved) {
      _resolved = true;
      _finish(outcome == DuelOutcome.playerWon);
    } else {
      setState(() {}); // refresh hand
    }
  }

  void _finish(bool won) {
    final controller = ref.read(saveStateProvider.notifier);
    final save = ref.read(saveStateProvider);
    var earned = 0;
    String? trump;
    if (won) {
      earned = 5 + save.kingdom.mineCrystalsPerWin;
      controller.addCrystals(earned);
      if (widget.node.index >= save.unlockedNodeIndex &&
          widget.node.index < kSliceNodes.length - 1) {
        controller.unlockNextNode();
      }
      if (widget.node.rewardTrumpId != null) {
        trump = widget.node.rewardTrumpId;
        controller.grantCard(trump!);
      } else if (Random(widget.node.index + 7).nextDouble() < 0.30) {
        trump = 'trump_frost_granny';
        controller.grantCard(trump);
      }
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) =>
          RewardScreen(won: won, crystalsEarned: earned, trumpGranted: trump),
    ));
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/ui/duel_screen_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/duel_screen.dart lib/ui/reward_screen.dart test/ui/duel_screen_test.dart
git commit -m "feat: add duel screen and post-duel reward flow"
```

---

### Task 15: Full suite, analyzer, and manual run

**Files:**
- Modify: none (verification task); fix any issues surfaced.

**Interfaces:**
- Consumes: everything.
- Produces: a green analyzer, a green test suite, and a manually verified runnable build.

- [ ] **Step 1: Run the analyzer**

Run: `flutter analyze`
Expected: "No issues found!" Fix any warnings/errors before continuing.

- [ ] **Step 2: Run the entire test suite**

Run: `flutter test`
Expected: PASS (all engine, data, model, and UI tests).

- [ ] **Step 3: Manual smoke run** (requires a device/emulator)

Run: `flutter run`
Verify by hand: world map shows 4 nodes (only «Тренировка» unlocked); play and win the training duel; crystals increase; the next node unlocks; open Королевство and upgrade a building; beat the boss and confirm «Король-Тыква» is granted on the reward screen.

- [ ] **Step 4: Commit any fixes**

```bash
git add -A
git commit -m "chore: pass analyzer and full test suite for vertical slice"
```

---

## Self-Review

**1. Spec coverage:**
- §2 Cards/elements → Tasks 2, 3, 8 ✓
- §3 Duel flow (30 HP, hand 4, element bonus, damage = diff, win by castle 0 / HP tiebreak) → Tasks 5, 10 ✓
- §4 Kingdom (3 buildings × 3 levels, crystals, hybrid combat+production) → Tasks 7, 13 ✓
- §5 Trumps (3 abilities; boss/craft/chest acquisition) → boss + chest in Task 14, abilities in Tasks 3/5; **craft path:** the spec puts crafting at Barracks lv.3. *Gap noted:* Tasks 13/14 implement boss-trophy and chest but not the craft-a-trump action. **Fix:** added below as Task 13b.
- §6 Architecture (engine/controllers/state/persistence/ui split) → Tasks 2–14 ✓
- §7 Linear map 3 nodes + boss, local save → Tasks 9, 12 ✓

**2. Placeholder scan:** No "TBD/TODO" in steps; all code blocks are complete.

**3. Type consistency:** `GameCard`, `DuelConfig`, `RoundResult`, `RoundWinner`, `DuelSession`, `Kingdom`, `KingdomEconomy.toDuelConfig`, `SaveController` method names are consistent across tasks. `kDeckSize`/`kHandSize` used consistently.

Adding the missing craft task:

---

### Task 13b: Craft a trump at Barracks level 3

**Files:**
- Modify: `lib/ui/kingdom_screen.dart`
- Test: `test/ui/kingdom_screen_test.dart` (extend)

**Interfaces:**
- Consumes: `saveStateProvider`, `SaveController.tryUpgrade`/`addCrystals`/`grantCard`, `Kingdom.barracksLevel`.
- Produces: a «Создать козырь (40💎)» button in the Barracks card, visible only when `barracksLevel == 3` and the craft trump (`trump_pumpkin_king` if not owned, else `trump_frost_granny`) is not yet owned; on tap, if `crystals >= 40`, deduct 40 and `grantCard`.

- [ ] **Step 1: Extend the kingdom test**

Append to `test/ui/kingdom_screen_test.dart`:
```dart
// add at top: import 'package:card_game/state/providers.dart';
// add at top: import 'package:card_game/engine/kingdom.dart';

testWidgets('craft button appears only at barracks level 3', (tester) async {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer();
  // Force barracks to level 3 with plenty of crystals.
  final ctrl = container.read(saveStateProvider.notifier);
  ctrl.addCrystals(100);
  ctrl.tryUpgrade(BuildingType.barracks); // 1->2
  ctrl.tryUpgrade(BuildingType.barracks); // 2->3
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: KingdomScreen()),
  ));
  await tester.pumpAndSettle();
  expect(find.textContaining('Создать козырь'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/kingdom_screen_test.dart`
Expected: FAIL (no craft button).

- [ ] **Step 3: Add the craft UI to the Barracks card in `kingdom_screen.dart`**

Inside the `ListTile` for buildings, after the upgrade button logic, add a craft row under the Barracks tile. Replace the `Card(...)` body in the `for` loop with a column that appends the craft button when applicable:
```dart
// Replace the `child: ListTile(...)` of the Card with:
child: Column(
  children: [
    ListTile(
      title: Text(_titles[type]!),
      subtitle: Text('Ур. ${k.levelOf(type)} — ${_effect(type, k)}'),
      trailing: k.levelOf(type) >= 3
          ? const Text('МАКС')
          : FilledButton(
              onPressed: save.crystals >=
                      KingdomEconomy.upgradeCost(type, k.levelOf(type))
                  ? () => controller.tryUpgrade(type)
                  : null,
              child: Text(
                  'Улучшить (${KingdomEconomy.upgradeCost(type, k.levelOf(type))}💎)'),
            ),
    ),
    if (type == BuildingType.barracks && k.barracksLevel >= 3)
      Builder(builder: (context) {
        const craftId = 'trump_pumpkin_king';
        const altId = 'trump_frost_granny';
        final target = save.ownedCardIds.contains(craftId) ? altId : craftId;
        if (save.ownedCardIds.contains(target)) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Все козыри кузницы созданы'),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(8),
          child: FilledButton.tonal(
            onPressed: save.crystals >= 40
                ? () {
                    controller.addCrystals(-40);
                    controller.grantCard(target);
                  }
                : null,
            child: const Text('Создать козырь (40💎)'),
          ),
        );
      }),
  ],
),
```
Note: `addCrystals(-40)` reuses the existing mutator; it already persists. Ensure `SaveController.addCrystals` accepts negative values (it does — plain addition).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/kingdom_screen_test.dart`
Expected: PASS (both kingdom tests).

- [ ] **Step 5: Commit**

```bash
git add lib/ui/kingdom_screen.dart test/ui/kingdom_screen_test.dart
git commit -m "feat: add trump crafting at barracks level 3"
```

---

## Done criteria

- `flutter analyze` clean, `flutter test` green.
- A player can: clear the training node, earn crystals, upgrade all three buildings, craft a trump at Barracks lv.3, win a chest-drop trump, and beat the boss to claim «Король-Тыква».
- All three trump-acquisition paths (boss, craft, chest) are reachable in one playthrough.
