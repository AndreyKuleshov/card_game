import 'dart:math';
import 'game_card.dart';

class Deck {
  final List<GameCard> _cards;

  Deck(List<GameCard> cards) : _cards = List.of(cards);

  int get remaining => _cards.length;
  bool get isEmpty => _cards.isEmpty;

  GameCard? draw() => _cards.isEmpty ? null : _cards.removeAt(0);

  List<GameCard> drawUpTo(int n) {
    final out = <GameCard>[];
    for (var i = 0; i < n; i++) {
      final card = draw();
      if (card == null) break;
      out.add(card);
    }
    return out;
  }

  void shuffle(Random random) => _cards.shuffle(random);
}
