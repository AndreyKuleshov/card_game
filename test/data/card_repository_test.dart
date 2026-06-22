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
