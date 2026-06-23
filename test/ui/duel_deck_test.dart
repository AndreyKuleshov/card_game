import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_game/engine/ability.dart';
import 'package:card_game/engine/element.dart';
import 'package:card_game/engine/game_card.dart';
import 'package:card_game/models/save_state.dart';
import 'package:card_game/ui/duel_setup.dart';

GameCard card(String id, int power, [Rarity r = Rarity.common]) =>
    GameCard(id: id, name: id, element: Element.fire, power: power, rarity: r);

final pool = [
  for (var p = 1; p <= 9; p++) card('c$p', p),
  card('trump_lava_cat', 8, Rarity.trump),
];

double avgPower(List<GameCard> deck) =>
    deck.map((c) => c.power).reduce((a, b) => a + b) / deck.length;

void main() {
  test('opponent deck gets stronger as the node level grows', () {
    final r = Random(7);
    final weak = buildOpponentDeck(
        allCards: pool, level: 0, isBoss: false, random: r);
    final strong = buildOpponentDeck(
        allCards: pool, level: 3, isBoss: false, random: r);
    expect(avgPower(strong), greaterThan(avgPower(weak)));
  });

  test('boss deck includes a trump', () {
    final deck = buildOpponentDeck(
        allCards: pool, level: 3, isBoss: true, random: Random(1));
    expect(deck.any((c) => c.rarity == Rarity.trump), isTrue);
  });

  test('non-boss opponent deck has no trumps', () {
    final deck = buildOpponentDeck(
        allCards: pool, level: 2, isBoss: false, random: Random(1));
    expect(deck.every((c) => c.rarity != Rarity.trump), isTrue);
  });

  test('different seeds produce different deals', () {
    final a = buildOpponentDeck(allCards: pool, level: 2, isBoss: false, random: Random(1));
    final b = buildOpponentDeck(allCards: pool, level: 2, isBoss: false, random: Random(2));
    expect(a.map((c) => c.id).toList(), isNot(equals(b.map((c) => c.id).toList())));
  });

  test('player deck excludes trumps; trumps come out separately', () {
    final all = [card('common1', 4), card('starter', 8, Rarity.trump)];
    final save = SaveState.initial().copyWith(
      ownedCardIds: {'common1', 'starter'},
    );
    final deck = buildPlayerDeck(save, all);
    final trumps = buildPlayerTrumps(save, all);
    expect(deck.every((c) => c.rarity != Rarity.trump), isTrue);
    expect(trumps.map((c) => c.id), contains('starter'));
  });
}
