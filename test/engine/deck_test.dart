import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/ability.dart';
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
