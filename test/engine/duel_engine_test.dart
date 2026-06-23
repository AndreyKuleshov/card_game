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
      expect(r.damage, 0);
    });

    test('forge bonus boosts the matching player element', () {
      const boosted = DuelConfig(elementBonuses: {Element.fire: 3});
      // Player fire(5)+3 = 8 vs opponent fire(6).
      final r = DuelEngine.resolveRound(
        playerCard: card('p', Element.fire, 5),
        opponentCard: card('o', Element.fire, 6),
        config: boosted,
      );
      expect(r.winner, RoundWinner.player);
      expect(r.damage, 2);
    });

    test('elementalShift on player card cancels opponent element bonus', () {
      // Fire beats Nature: opponent fire(5) would get +3 vs player nature(5) -> 8 vs 5.
      // Player's elementalShift cancels the opponent's bonus -> 5 vs 5 tie.
      final r = DuelEngine.resolveRound(
        playerCard: card('p', Element.nature, 5, ability: Ability.elementalShift),
        opponentCard: card('o', Element.fire, 5),
        config: cfg,
      );
      expect(r.winner, RoundWinner.tie);
      expect(r.damage, 0);
    });

    test('doubleStrike applies when the opponent card wins', () {
      // Same element (no element bonus). Opponent fire(9, doubleStrike) vs player fire(4):
      // opponent wins, (9-4)=5 -> floor(7.5)=7 damage to the player castle.
      final r = DuelEngine.resolveRound(
        playerCard: card('p', Element.fire, 4),
        opponentCard: card('o', Element.fire, 9, ability: Ability.doubleStrike),
        config: cfg,
      );
      expect(r.winner, RoundWinner.opponent);
      expect(r.damage, 7);
    });

    test('shield on the winning card does not reduce damage', () {
      // Same element. Player fire(8, shield) beats opponent fire(3): shield only protects the loser.
      final r = DuelEngine.resolveRound(
        playerCard: card('p', Element.fire, 8, ability: Ability.shield),
        opponentCard: card('o', Element.fire, 3),
        config: cfg,
      );
      expect(r.winner, RoundWinner.player);
      expect(r.damage, 5);
    });
  });
}
