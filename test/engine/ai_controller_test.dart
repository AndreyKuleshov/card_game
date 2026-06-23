import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/ai_controller.dart';
import 'package:card_game/engine/duel_engine.dart';
import 'package:card_game/engine/element.dart';
import 'package:card_game/engine/game_card.dart';
import 'package:card_game/engine/ability.dart';

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
