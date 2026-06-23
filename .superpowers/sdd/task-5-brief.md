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

