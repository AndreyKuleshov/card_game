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

