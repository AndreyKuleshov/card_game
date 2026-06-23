import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/ability.dart';
import 'package:card_game/engine/ai_controller.dart';
import 'package:card_game/engine/deck.dart';
import 'package:card_game/engine/duel_engine.dart';
import 'package:card_game/engine/duel_session.dart';
import 'package:card_game/engine/element.dart';
import 'package:card_game/engine/game_card.dart';

GameCard c(String id, Element e, int p, [Rarity r = Rarity.common]) =>
    GameCard(id: id, name: id, element: e, power: p, rarity: r);

DuelSession makeSession({
  required List<GameCard> player,
  required List<GameCard> opp,
  List<GameCard> trumps = const [],
}) {
  return DuelSession(
    playerDeck: Deck(player),
    opponentDeck: Deck(opp),
    playerTrumps: trumps,
    playerConfig: const DuelConfig(startingCastleHp: 10),
    opponentConfig: const DuelConfig(startingCastleHp: 10),
    ai: AiController(),
    random: Random(1),
  )..start();
}

List<GameCard> fours(int power) => [
      for (var i = 0; i < 4; i++) c('x$power$i', Element.fire, power),
    ];

void main() {
  test('start deals hands, sets hp, and the opponent reveals first', () {
    final s = makeSession(player: fours(5), opp: fours(1));
    expect(s.playerHand.length, 4);
    expect(s.playerCastleHp, 10);
    expect(s.opponentCastleHp, 10);
    // Opponent leads: a card is already on the table for the player to answer.
    expect(s.pendingOpponentCard, isNotNull);
  });

  test('answering with a stronger card damages the opponent castle', () {
    final s = makeSession(player: fours(9), opp: fours(1));
    final result = s.respond(s.playerHand.first);
    expect(result.winner, RoundWinner.player);
    expect(s.opponentCastleHp, lessThan(10));
  });

  test('answering with a weaker card damages the player castle', () {
    final s = makeSession(player: fours(1), opp: fours(9));
    final result = s.respond(s.playerHand.first);
    expect(result.winner, RoundWinner.opponent);
    expect(s.playerCastleHp, lessThan(10));
  });

  test('answering with a hand card refills the hand back to 4', () {
    final s = makeSession(player: fours(9), opp: fours(1));
    s.respond(s.playerHand.first);
    expect(s.playerHand.length, 4);
  });

  test('a trump answers the round, is spent once, and does not touch the hand', () {
    final trump = c('t1', Element.fire, 9, Rarity.trump);
    final s = makeSession(player: fours(5), opp: fours(1), trumps: [trump]);
    expect(s.availableTrumps.length, 1);
    final handBefore = s.playerHand.length;

    final result = s.respond(trump);
    expect(result.playerCard.id, 't1');
    expect(s.availableTrumps, isEmpty); // spent for the battle
    expect(s.playerHand.length, handBefore); // trump did not consume a hand slot
  });

  test('opponent never runs out: always one on the table + 3 in reserve', () {
    // Player can never finish the opponent (all ties), so the duel runs long.
    final s = makeSession(player: fours(1), opp: fours(1));
    for (var i = 0; i < 30; i++) {
      expect(s.pendingOpponentCard, isNotNull);
      expect(s.opponentHand.length, 3); // handSize(4) - 1 revealed
      // Tie deals no damage, so castles survive and the loop keeps going.
      s.respond(s.playerHand.first);
    }
  });

  test('reducing the opponent castle to zero yields playerWon', () {
    final s = makeSession(player: fours(9), opp: fours(1));
    var guard = 0;
    while (s.outcome == DuelOutcome.ongoing && guard++ < 50) {
      s.respond(s.playerHand.first);
    }
    expect(s.outcome, DuelOutcome.playerWon);
  });

  test('decks recycle; the duel ends only when a castle is destroyed', () {
    final s = DuelSession(
      playerDeck: Deck([c('p1', Element.fire, 9), c('p2', Element.fire, 9)]),
      opponentDeck: Deck([c('o1', Element.fire, 1), c('o2', Element.fire, 1)]),
      playerTrumps: const [],
      playerConfig: const DuelConfig(startingCastleHp: 50),
      opponentConfig: const DuelConfig(startingCastleHp: 30),
      ai: AiController(),
      random: Random(1),
    )..start();

    var rounds = 0;
    while (s.outcome == DuelOutcome.ongoing && rounds++ < 500) {
      s.respond(s.playerHand.first);
    }
    expect(s.outcome, DuelOutcome.playerWon);
    expect(s.opponentCastleHp, lessThanOrEqualTo(0));
    expect(rounds, greaterThan(2)); // played more rounds than the 2-card deck
  });
}
