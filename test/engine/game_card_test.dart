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
