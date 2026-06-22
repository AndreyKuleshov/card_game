import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/ability.dart';
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

  test('opponent winning a round damages the player castle', () {
    final s = makeSession(
      player: [c('p1', Element.fire, 1), c('p2', Element.fire, 1), c('p3', Element.fire, 1), c('p4', Element.fire, 1)],
      opp: [c('o1', Element.fire, 9), c('o2', Element.fire, 9), c('o3', Element.fire, 9), c('o4', Element.fire, 9)],
    );
    final result = s.playPlayerCard(s.playerHand.first);
    expect(result.winner, RoundWinner.opponent);
    expect(s.playerCastleHp, lessThan(10));
  });
}
